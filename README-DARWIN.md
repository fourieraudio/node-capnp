So, you want to cross-compile for darwin? Have fun.

Jokes, I've done all the work for you. Simply:

0. Make the `osxcross` darwin clang toolchain available on your PATH
   (Fourier application repositories have tooling to do all the building for you).
1. From a Linux build environment, run `npm install --platform=darwin`.
2. ...
3. Profit!!!

NOTE that the generated capnp dylibs will not yet have been patched up to have the correct link
paths, and so are still named `*.so` - you'll want to use `install_name_tool` to fix them up before
bundling them into your application. The node module binary itself *IS* patched by this tooling (see
`build.js` for more fascinating details).

(ymmv, e&oe...)
