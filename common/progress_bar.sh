#!/bin/bash

# $Id$

set -e

if [ ! -f $1 ] ; then
  echo -n "."
  sleep 1
  if [ -d /proc/$2 ] ; then
    ./$0 $1 $2
  fi
fi
