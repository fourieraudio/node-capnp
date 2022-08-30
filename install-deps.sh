#!/bin/sh

set -euf

apt-get update
apt-get install -y --no-install-recommends \
    libcapnp-dev

