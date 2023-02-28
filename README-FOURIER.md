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
commit a `git+ssh:` reference to source control, but you could temporarily change it to a `file:`
reference when making changes to this package.

```js
"dependencies": {
  "capnp": "git+ssh://git@github.com/fourieraudio/node-capnp.git#main"
}

// Or, temporarily...
"dependencies": {
  "capnp": "file:../node-capnp"
}
```

Running `npm install` after adding this dependency will acquire the module and compile its contents.
Note that npm very helpfully swallows all output when building as part of an install script like
this, and will appear to have simply hung for ~some time whilst it performs the compilation. What
even is developer experience. To see the output of the compilation process, you must run
`npm install` from within the package's source directory.

Caution: In order for this temporary change to be properly flushed through NPM, you may need to
delete both your `node_modules` folder and your `package-lock.json`.

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

## Development

To compile the module when developing it, you can use the same `npm install` commands referenced
under "Cross-Compilation" above from within this package's source directory. When compiling the
module this way, the output will thankfully be printed to the terminal for you to follow along.

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
