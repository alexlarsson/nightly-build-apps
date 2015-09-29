#!/bin/bash

set -o nounset
set -o errexit

if [ "$#" -nt 3 ]; then
    echo "Wrong args"
fi

DIR="$1"
OPT="$2"
CONFIGURE_ARGS="$3"

echo DIR: $DIR
echo OPT: $OPT
echo CONFIGURE_ARGS: $CONFIGURE_ARGS

contains() {
  for word in $1; do
    [[ "$word" = "$2" ]] && return 0
  done
  return 1
}

set -x

cd $DIR

if ! contains "$OPT" noautogen ; then
    ./autogen.sh --prefix=/app "$CONFIGURE_ARGS"
fi
if contains "$OPT" force; then
    libtoolize --force
    aclocal
    autoheader
    automake --force-missing --add-missing --foreign
    autoconf
fi
if contains "$OPT" configure ||  contains "$OPT" noautogen; then
    ./configure --prefix=/app "$CONFIGURE_ARGS"
fi
make -j`nproc`
make install
