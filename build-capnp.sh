#!/bin/bash

# Syntax: build-capnp.sh TARGET
#     TARGET = darwin or linux
# 
# This script downloads the capnproto source distribution, unpacks it to a `./build-capnp`
# subdirectory, and cross-compiles its libraries and headers from a linux host to the specified
# target. We produce capnp static libraries for the `linux` target (to keep distribution simple),
# but dynamic libraries for `darwin`, because the Mac system libraries have a tendency to break.
# 
# For the `linux` target, the host must have `clang` installed and available on their PATH. The
# `darwin` target is based on the `osxcross` toolchain, which provides `o64-clang++`.
# 
# Copyright Fourier Audio Ltd. 2022. All Rights Reserved.

# See: https://sipb.mit.edu/doc/safe-shell/
set -euf -o pipefail

# Check argument count
if [[ $# != 1 ]]; then
    echo "Expected exactly one argument, but received ${#}."
    exit 1
fi

# Get directory of this script in a relatively robust fashion (pun intended); see
# http://www.binaryphile.com/bash/2020/01/12/determining-the-location-of-your-script-in-bash.html
here=$(cd "$(dirname "$BASH_SOURCE")"; \
    cd -P "$(dirname "$(readlink "$BASH_SOURCE" || echo -e "$BASH_SOURCE")")"; \
    pwd)

# We store all of our build artefacts in a subdirectory. If that directory already exists, remove
# it so that we can cleanly restart from scratch. Preserve the capnproto source distribution if
# it's present, so that we don't need to redownload it.
capnp_filename="capnproto-c++-0.10.3.tar.gz"
build_dir="${here}/build-capnp"

if [[ -f "${build_dir}/${capnp_filename}" ]]; then
    mv "${build_dir}/${capnp_filename}" .
fi

rm -rf ${build_dir}
mkdir -p ${build_dir}

if [[ -f "./${capnp_filename}" ]]; then
    mv "./${capnp_filename}" "${build_dir}"
fi

pushd ${build_dir}

# Download the capnproto source, if we don't already have it, and then unpack it. It's pretty small
# (1.6 MiB), so the download should be fast.
if [[ ! -f "${capnp_filename}" ]]; then
    curl -O https://capnproto.org/capnproto-c++-0.10.3.tar.gz
fi

tar --strip-components=1 -zxf "${capnp_filename}"

# Behave differently depending on the cross-compilation target...
if [[ $1 == "linux" ]]; then
    # We're not cross-compiling, so this is trivial.

    CC="clang" \
        CXX="clang++" \
        CFLAGS="-fPIC" \
        CXXFLAGS="-std=c++17 -fPIC" \
        ./configure --disable-shared
    make -j
    make install-data DESTDIR=capnp-root

elif [[ $1 == "darwin" ]]; then
    # Cross-compile to darwin, with various manual fixes.

    CC=o64-clang CXX=o64-clang++ ./configure --build=x86_64-apple-darwin --host=x86_64-linux-gnu

    # libtool seems to decide that we must build shared libraries with -nostdlib as the linker will
    # necessarily link against the wrong stdlib. I don't believe this to be true for our toolchain,
    # but I'm also not enough of a GNU greybeard to know how to dissuade libtool from emitting this
    # linker flag. So, we'll do it the brute-force-and-ignorance way.
    sed -i 's/ -nostdlib//g' ./libtool

    # Similarly, the configure script seems to misdetect the value of the max_cmd_length variable,
    # setting it to an empty string. This results in the libtool linker command going bang
    # approximately half way through. Force the value to be set.
    ARG_MAX=`getconf ARG_MAX`
    sed -i "s/max_cmd_len=$/max_cmd_len=${ARG_MAX}/" ./libtool

    # The capnp makefile tries to run the capnpc tool as a smoke test approximately half way through
    # the process. Unsurprisingly, when we are cross-compiling, this approach is met with limited
    # success. Expunge this from the makefile, replacing the test_capnp_outputs rule with an empty
    # recipe.
    sed -i 's/(test_capnpc_outputs): test_capnpc_middleman$/(test_capnpc_outputs):\n\t@:/' Makefile

    CC=o64-clang CXX=o64-clang++ make -j

    make install-data DESTDIR=capnp-root

else
    echo "Invalid TARGET argument: expected darwin or linux, received ${1}."
    exit 1

fi

popd
