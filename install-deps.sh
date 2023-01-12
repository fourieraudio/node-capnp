#!/bin/sh

set -euf

apt-get update

# `libcapnp-dev` is required to run `npm test`, because it provides certain stock `.capnp` files
apt-get install -y --no-install-recommends \
    libcapnp-dev

