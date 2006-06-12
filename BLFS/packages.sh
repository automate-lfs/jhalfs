#!/bin/bash
#
# $Id$
#
set -e

declare -r SVN="svn://svn.linuxfromscratch.org"

BLFS_XML=$1  # Book directory
DOC_MODE=$2  # Action to take, only update at the moment

#---------------------
# packages module
source libs/func_packages
[[ $? > 0 ]] && echo -e "\n\tERROR: func_packages did not load..\n" && exit

#----------------------------#
BOOK_Source() {              #
#----------------------------#
: <<inline_doc
    function:   Retrieve a fresh copy or upate an existing copy of the BLFS svn tree
    input vars: $1 BLFS_XML directory
                $2 DOC_MODE action get/update
    externals:  none
    modifies:   $BLFS_XML directory tree
    returns:    nothing
    output:     
    on error:   exit
    on success: text messages
inline_doc

    # Redundant definitions but this function may be reused
  local BLFS_XML=$1
  local DOC_MODE=$2
  
  if [[ -z "$BLFS_XML" ]] ; then
    echo -e "\n\tYou must to provide the name of the BLFS book sources directory.\n"
    exit 1
  fi

  if [[ -n "$DOC_MODE" ]] ; then
    case $DOC_MODE in
      update )
        if [[ ! -d $BLFS_XML ]] ; then
          echo -e "\n\t$BLFS_XML is not a directory\n"
          exit 1
        fi
        if [[ ! -f $BLFS_XML/use-unzip.xml ]] ; then
          echo -e "\n\tLooks like $BLFS_XML is not a BLFS book sources directory\n"
          exit 1
        fi

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
      
      get )
        [[ ! -d $BLFS_XML ]] && mkdir -pv $BLFS_XML
        svn co $SVN/BLFS/trunk/BOOK $BLFS_XML 2>&1
       ;;
      * )
         echo -e "\n\tUnknown option ${DOC_MODE} ignored.\n"
      ;;
    esac
  fi
}

BOOK_Source $BLFS_XML $DOC_MODE

echo -en "\n\tGenerating packages file ..."
generate_packages
echo "done."

echo -en "\tGenerating gnome-core dependencies list ..."
generate_gnome_core
echo "done."

echo -en "\tGenerating gnome-full dependencies list ..."
generate_gnome_full
echo "done."

echo -en "\tGenerating kde-core dependencies list ..."
generate_kde_core
echo "done."

echo -en "\tGenerating kde-full dependencies list ..."
generate_kde_full
echo -e "done.\n"

