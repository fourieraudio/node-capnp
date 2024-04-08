# `node-capnp`

This is Fourier's fork of the GitHub `capnproto/node-capnproto` repository, modified for use in an
Electron environment:

* Modified build scripts to build against Electron headers.
* Bumped dependencies and merged PRs to resolve V8 compatibility issues, so that the package can
  be used with Electron 20.
* Modified source code and build scripts to support Win32.
* Modified build scripts to support cross-compilation from Linux to Win32 or Darwin, and
  cross-compilation between CPU architectures. (In the case of Win32, this requires us to use a
  prebuilt `node.capnp` binary, because `node-gyp` doesn't support true cross-compilation.)

For the original documentation, see [`README.md`](README.md).

## Usage

To make use of this package, add it to the `dependencies` table in your `package.json`. You should
commit a `git+ssh:` reference to source control:

```js
"dependencies": {
  "capnp": "git+ssh://git@github.com/fourieraudio/node-capnp.git#main"
}
```

Running `npm install` after adding this dependency will acquire the module and compile its contents.
Note that npm very helpfully swallows all output when building as part of an install script like
this, and will appear to have simply hung for ~some time whilst it performs the compilation. What
even is developer experience. To see the output of the compilation process, you must run
`npm install` from within the package's source directory.

## Cross-Compilation

To cross-compile, simply pass the `--platform` and/or `--arch` flags when installing this package as
a dependency. (This is the same strategy used by Electron.) Cross-compilation is supported from
either Linux or WSL. The supported target platforms are `darwin`, `linux` and `win32`, and the
supported target architectures are `ia32`, `x64` and `arm`.

```bash
# For example:
npm clean-install --platform=win32

# Another example:
npm install --platform=darwin --arch=x64 capnp
```

See [`README-DARWIN.md`](README-DARWIN.md) for more information about our approach to Darwin
cross-compilation.

### Windows "Cross"-"Compilation"
When we say we "support" cross-compilation from `linux` to `win32`, what of course we really mean is
that we support producing a `win32` distributable node package on a `linux` host. You, dear reader,
will be particularly overjoyed to learn that at present all this does is copy a committed,
pre-compiled `capnp.node` blob out of the repository and into the distribution package. Whilst this
is technically in a sense "compiling" if you look at it sideways, in the same way that walking to
the pub is "exercise", you would be forgiven for making the argument that this is perhaps somewhat
missing the point.

If you find yourself needing to make modifications to the C++ in this package, and, heaven forbid,
want your changes to actually end up in the resultant binary distributed to our dear users, then you
must;

a) Happen to have an entirely functional build environment present, perhaps by virtue of having done
this before, or;

b) Set up a Windows build environment from scratch. Hooray! Go directly to jail. Do not pass go.

The steps for accomplishing this sisyphean task include, but may not be limited to, the following:

1. Convince yourself that you don't have time to rewrite the build system to do the
   cross-compilation properly (TF-1589).
2. Install Visual Studio C++ Build Tools 2022.
3. Install `node`. Note that in order to do this, you should first install a node version manager,
   such as `nvm-windows`, and then actually install `node`. The author is using `node v18.19.0`.
4. Acquire the repository sources in your build environment.
5. Install some sort of python. Make sure it ends up on your PATH! Make sure you install the right
   sort of python. At the moment, `gyp`, upon which the build process is precariously balanced, uses
   `distutils`, which the python world in its infinite wisdom has burninated in Python 3.12. You
   must therefore not use that. I hear Python 3.11 is nice.
6. Open the `x64 Native Tools Command Prompt`. Do not do this sooner, or things you want will not be
   on your PATH.
7. Verify that `npm` and `python` are available in your PATH.
8. Navigate to the repository root. Curse as you realise you are still using `cmd.exe`, a command
   line interpreter designed exclusively for people who hate themselves.
9. Issue `npm i`. Watch in amazement as thousands of C++ compiler warnings scroll past. Ignore them.
   Everything is fine. Go and make a cup of tea.
10. Approximately 5 minutes later, marvel at the fruit of your labour, visible at
    `bin/win32-x64/capnp.node`, unless you skipped any of the above steps, in which case curse
    loudly, go back and do it again.

Currently, the `build.js` rebuilds the entirety of `capnp` every time the module is rebuilt, which
is slow and may tire you. Modifying `build.js` to prevent this is trivial.

## Development

To compile the module when developing it, you can use the same `npm install` commands referenced
under "Cross-Compilation" above from within this package's source directory. When compiling the
module this way, the output will thankfully be printed to the terminal for you to follow along.

To use your modified version of this repository in another project during development, you can
temporarily change the dependency reference in the `package.json` to a `file:` reference:

```
"dependencies": {
  "capnp": "file:../node-capnp"
}
```

Caution: In order for this temporary change to be properly flushed through NPM, you may need to
delete both your `node_modules` folder and your `package-lock.json`.

## Testing

```bash
npm run test
```

Tests currently only run on Linux. They also require `libcapnp-dev` to be installed, because the
test script looks for a `c++.capnp` schema file which is normally installed in the same directory as
capnproto's header files. We haven't (yet?) bothered to bundle any of the stock schema files into
this package.

If you have an urgent need to run this package's tests on Win32, you could find `c++.capnp` among
capnproto's header files in `./build-capnp`, and move it to `./node_modules/capnp/c++.capnp`.
