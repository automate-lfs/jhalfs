#!/bin/bash
#
# $Id$
#
set -e

BLFS_XML=$1

> packages.tmp

for file in `find $BLFS_XML -name "*.xml"` ; do
  pkg_id=`grep "sect1 id" $file | sed -e 's/<sect1 id="//;s/".*//'`
  [[ ! -z "$pkg_id" ]] && echo -e "$pkg_id\t$file" >> packages.tmp
done

sort packages.tmp -o packages
rm packages.tmp
