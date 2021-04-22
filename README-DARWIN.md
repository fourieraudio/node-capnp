So, you want to cross-compile for darwin? Have fun.

Jokes, I've done all the work for you. Simply:

0. Make the osxcross darwin clang toolchain available on your PATH (rewind-server has a handy script
   to do all the building for you)
1. `./build-capnp-darwin.sh` (this builds capnproto so we have darwin libs and headers available)
2. `. capnp-darwin.env` (this exports `CAPNP_LIBDIR` and `CAPNP_INCDIR` so capnp can be found by the node
   module build script)
3. `npm run build:darwin` (this builds the capnp.node native module for darwin)
4. ...
5. Profit!!!

NOTE that the generated capnp dylibs will not yet have been patched up to have the correct link
paths, and so are still named `*.so` - you'll want to use `install_name_tool` to fix them up before
bundling them into your application. The node module binary itself *IS* patched by this tooling (see
`build.js` for more fascinating details).

(ymmv, e&oe...)
