#!/bin/bash

# $Id$

set -e

[[ -z $1 ]] && exit

if [ ! -f $1 ] ; then
  while fuser -v . 2>&1 | grep make >/dev/null ; do
    echo -n "."
    sleep 1
    [[ -f $1 ]] && exit
  done
fi
