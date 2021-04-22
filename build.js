#!/usr/bin/env node

// build.js copied from node-fibers package under MIT license.
// License for node-fibers is as follows:
//
// Copyright 2011 Marcel Laverdet
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

var cp = require('child_process'),
	fs = require('fs'),
	path = require('path');

// Parse args
var force = false, debug = false;
var
	arch = process.arch,
	platform = process.platform,
	v8 = /[0-9]+\.[0-9]+/.exec(process.versions.v8)[0],
  environment = { ...process.env };

var patchLibPath = false, patchTool = null;

var args = process.argv.slice(2).filter(function(arg) {
	if (arg === '-f') {
		force = true;
		return false;
	} else if (arg.substring(0, 13) === '--target_arch') {
		arch = arg.substring(14);
    force = true; // No point trying to run a binary that isn't the host's arch
	} else if (arg.substring(0, 13) === '--target_plat') {
		platform = arg.substring(14);
    force = true; // No point trying to run a binary that isn't the host's platform
    environment = patchEnvironment(environment);
    return false;
	} else if (arg === '--debug') {
		debug = true;
	} else if (arg.substring(0, 12) === '--patch_path') {
    patchLibPath = arg.substring(13);

    if (!environment.hasOwnProperty("PATCH_TOOL")) {
      console.error("--patch_path was requested but PATCH_TOOL env was not set; aborting");
      console.error("be sure to set --target_plat first if cross-compiling as it will set PATCH_TOOL for you");
      process.exit(1);
    }

    return false;
  }

	return true;
});

// If we are cross-compiling for darwin, we must instruct gyp to generate a makefile which is
// compatible with the MacOS tooling. YOU MUST use the -f variant (NOT --format=) because it
// overrides -f set by node-gyp, and node-gyp isn't clever enough to know that they're aliases.
var configure_args = (platform != process.platform && platform == "darwin")
                   ? ["-f", "make-mac"]
                   : [];

if (!{ia32: true, x64: true, arm: true}.hasOwnProperty(arch)) {
	console.error('Unsupported (?) architecture: `'+ arch+ '`');
	process.exit(1);
}

// Test for pre-built library
var modPath = platform+ '-'+ arch+ '-v8-'+ v8;
var command = process.platform === 'win32' ? 'node-gyp.cmd' : 'node-gyp';

if (!force) {
	try {
		fs.statSync(path.join(__dirname, 'bin', modPath, 'capnp.node'));
		console.log('`'+ modPath+ '` exists; testing');
		cp.execFile(process.execPath, ['src/node-capnp/capnp-test'], function(err, stdout, stderr) {
			if (err || stdout.trim() !== 'pass' || stderr) {
				console.log('Problem with the binary; manual build incoming');
				build();
			} else {
				console.log('Binary is fine; exiting');
			}
		});
	} catch (ex) {
		// Stat failed
		build();
	}
} else {
	build();
}

function nodeGyp(task, arguments = [], gyp_args = []) {
  var final_args = [task].concat(arguments, "--", gyp_args);
  console.log(`Executing ${command} with the following args: `);
  console.log(final_args);

	var sp = cp.spawn(
    command,
    final_args,
		{
      stdio: 'inherit',
      env: environment,
    });

	sp.on('exit', function(err) {
		if (err) {
			if (err === 127) {
				console.error(
					'node-gyp not found! Please upgrade your install of npm! You need at least 1.1.5 (I think) '+
					'and preferably 1.1.30.'
				);
			} else {
				console.error(`Build step ${task} failed with exit code ${err}`);
			}
			return process.exit(err);
		}
	});

  return sp;
}

// Build it
function build() {
  console.log("Building with the following environment:");
  console.log(environment);

  nodeGyp("clean").on('close', () => {
    nodeGyp("configure", args, configure_args).on('close', () => {
      nodeGyp("build", args).on('close', () => afterBuild());
    });
  });
}

// Move it to expected location
function afterBuild() {
	var targetPath = path.join(__dirname, 'build', debug ? 'Debug' : 'Release', 'capnp.node');
	var installPath = path.join(__dirname, 'bin', modPath, 'capnp.node');

	try {
		fs.mkdirSync(path.join(__dirname, 'bin', modPath), {
      recursive: true,
    });
	} catch (ex) {}

	try {
		fs.statSync(targetPath);
	} catch (ex) {
		console.error('Build succeeded but target not found');
		process.exit(1);
	}

  if (patchLibPath !== false) {
    patchLibs(environment.PATCH_TOOL, patchLibPath, targetPath);
  }

  try {
    fs.renameSync(targetPath, installPath);
    console.log('Installed in `'+ installPath+ '`');
  } catch (ex) {
    console.error(`All went wrong when we tried to move the target: ${ex}`);
  }
}

/**
 * Rewrite the dynamic library references in the produced bundle to have appropriate paths for
 * relative layout within the final application bundle.
 *
 * @param patchTool - command name to use for editing the binary
 * @param patchPath - the path to be stripped out of the binary
 * @param target - The target binary to be modified
 */
function patchLibs(patchTool, patchPath, target) {
  var libVersion = "0.8.0";
  var libExt = "so";
  var libs = [
        "libkj",
        "libkj-async",
        "libcapnp",
        "libcapnpc",
        "libcapnp-rpc",
  ];

  var patchArgs = libs.flatMap((lib) => {
    return ["-change", `${patchPath}/${lib}-${libVersion}.${libExt}`, `@executable_path/${lib}-${libVersion}.dylib`];
  }).concat([target]);

  console.log(`Invoking binary patch tool ${patchTool} with the following arguments:`);
  console.log(patchArgs);

  /*
   * In future if this errors, we may need to set headerpad_max_install_names in LDFLAGS too...
   * (this provides more space for the dylib names in the object so that they can be rewritten
   * post-link) - looks like we don't need to do this for now though?
   */
  var patchProcess = cp.spawnSync(patchTool, patchArgs, {
    stdio: 'inherit',
  });

  if (patchProcess.error) {
    console.error(`Failed to patch binary: ${patchProcess.error}`);
    process.exit(1);
  } else if (patchProcess.status !== 0) {
    console.error(`Failed to patch binary: ${patchTool} exited with code ${patchProcess.status}`);
    process.exit(1);
  } else {
    console.log("Binary patched successfully.");
  }
}

/**
 * Modify the provided environment object to be appropriate for cross-compilation for a darwin
 * target from a linux host
 */
function patchEnvironment(env) {
  if (!env.hasOwnProperty("CAPNP_LIBDIR")) {
    console.error("CAPNP_LIBDIR must be set to a place I can find compiled libcapnp, libkj and friends for the target plat/arch");
    process.exit(1);
  }

  if (!env.hasOwnProperty("CAPNP_INCDIR")) {
    console.error("CAPNP_INCDIR must be set to a place I can find headers for libcapnp and libkj!");
    process.exit(1);
  }

  return {
    CC: "o64-clang",
    CXX: "o64-clang++",
    CXXFLAGS: "-mmacosx-version-min=10.7 -std=c++14 -stdlib=libc++ -I" + env.CAPNP_INCDIR,
    LDFLAGS: "-L" + env.CAPNP_LIBDIR,
    PATCH_TOOL: "x86_64-apple-darwin20.2-install_name_tool",
    ...env
  };
}
