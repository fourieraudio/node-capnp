#!/bin/bash

# Fourier Rewind
# Copyright Fourier Audio Ltd. 2021. All Rights Reserved.

set -euf -o pipefail

o64-clang --version
o64-clang++ --version

# Get directory of this script in a relatively robust fashion (pun intended); see
# http://www.binaryphile.com/bash/2020/01/12/determining-the-location-of-your-script-in-bash.html
HERE=$(cd "$(dirname "$BASH_SOURCE")"; cd -P "$(dirname "$(readlink "$BASH_SOURCE" || echo -e "$BASH_SOURCE")")"; pwd)

BUILD="${HERE}/build-capnp"

rm -rf "${BUILD}"
mkdir -p "${BUILD}"
pushd $_

curl -O https://capnproto.org/capnproto-c++-0.8.0.tar.gz
tar zxf capnproto-c++-0.8.0.tar.gz
pushd capnproto-c++-0.8.0

CC=o64-clang CXX=o64-clang++ ./configure --build=x86_64-apple-darwin --host=x86_64-linux-gnu

# libtool seems to decide that we must build shared libraries with -nostdlib as the linker will
# necessarily link against the wrong stdlib. I don't believe this to be true for our toolchain, but
# I'm also not enough of a GNU greybeard to know how to dissuade libtool from emitting this linker
# flag. So, we'll do it the brute-force-and-ignorance way.
sed -i 's/ -nostdlib//g' ./libtool

# Similarly, the configure script seems to misdetect the value of the max_cmd_length variable,
# setting it to an empty string. This results in the libtool linker command going bang approximately
# half way through. Force the value to be set.
ARG_MAX=`getconf ARG_MAX`
sed -i "s/max_cmd_len=$/max_cmd_len=${ARG_MAX}/" ./libtool

# The capnp makefile tries to run the capnpc tool as a smoke test approximately half way through the
# process. Unsurprisingly, when we are cross-compiling, this approach is met with limited success.
# Expunge this from the makefile, replacing the test_capnp_outputs rule with an empty recipe.
sed -i 's/(test_capnpc_outputs): test_capnpc_middleman$/(test_capnpc_outputs):\n\t@:/' Makefile

CC=o64-clang CXX=o64-clang++ make -j

make install-data DESTDIR=capnp-root

export CAPNP_LIBDIR=`pwd`/.libs
export CAPNP_INCDIR=`pwd`/capnp-root/usr/local/include

popd
popd

cat << EOF > capnp-darwin.env
export CAPNP_LIBDIR="${CAPNP_LIBDIR}"
export CAPNP_INCDIR="${CAPNP_INCDIR}"
EOF

echo "Written env file $(pwd)/capnp-darwin.env !";
