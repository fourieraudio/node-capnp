# `node-capnp`

This is Fourier's fork of the GitHub `capnproto/node-capnproto` repository, modified for use in an
Electron environment:

* Modified build scripts to build against Electron headers.
* Bumped dependencies and merged PRs to resolve V8 compatibility issues, so that the package can
  be used with Electron 20.
* Modified source code and build scripts to support Win32.
* Modified build scripts to support cross-compilation from Linux to Win32 or Darwin. (In the case of
  Win32, this requires us to use a prebuilt `node.capnp` binary, because `node-gyp` doesn't support
  true cross-compilation.)

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

Caution: In order for this temporary change to be properly flushed through NPM, you may need to
delete both your `node_modules` folder and your `package-lock.json`.

## Cross-Compilation

To cross-compile, simply pass the `--platform` flag when installing this package as a dependency.
(This is the same strategy used by Electron.) Cross-compilation is supported from either Linux or
WSL. The supported target platforms are `darwin`, `linux` and `win32`.

```bash
npm clean-install --platform=win32

npm install --platform=darwin capnp
```

See [`README-DARWIN.md`](README-DARWIN.md) for more information about our approach to Darwin
cross-compilation.


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
