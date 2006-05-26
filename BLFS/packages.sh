#!/bin/bash
#
# $Id$
#
set -e

#---------------------
# packages module
source func_packages
[[ $? > 0 ]] && echo -e "\n\tERROR: func_packages did not load..\n" && exit


if [[ -z "$1" ]] ; then
  echo -e "n\tYou must to provide the name of the BLFS book sources directory.\n"
  exit 1
fi

BLFS_XML=$1

if [[ ! -d $BLFS_XML ]] ; then
  echo -e "\n\t$BLFS_XML is not a directory\n"
  exit 1
fi

if [[ ! -f $BLFS_XML/use-unzip.xml ]] ; then
  echo -e "\n\tLooks like $BLFS_XML is not a BLFS book sources directory\n"
  exit 1
fi

if [[ -n "$2" ]] ; then
  case $2 in
    update )
      if [[ -d $BLFS_XML/.svn ]] ; then
      echo -e "\n\tUpdating the $BLFS_XML book sources ...\n"
        pushd $BLFS_XML 1> /dev/null
        svn up
        popd 1> /dev/null
        echo -e "\n\tBook sources updated."
      else
        echo -e "\n\tLooks like $BLFS_XML is not a svn working copy."
        echo -e "\tSkipping BLFS sources update.\n"
      fi
      ;;
    * )
      echo -e "\n\tUnknown option $2 ignored.\n"
      ;;
  esac
fi

echo -en "\n\tGenerating packages file ..."
generate_packages
echo "done."

echo -en "\tGenerating gnome-core dependencies list ..."
generate_gnome_core
echo "done."
