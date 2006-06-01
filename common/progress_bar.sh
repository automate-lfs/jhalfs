#!/bin/bash

# $Id$

set -e

[[ -z $1 ]] && exit
[[ -z $2 ]] && exit

if [ ! -f $1 ] ; then
  while [ -d /proc/$2 ] ; do
    echo -n "$2 "
    sleep 1
  done
fi
