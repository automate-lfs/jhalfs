#!/bin/bash
#
# $Id$
#
set -e

declare -r SVN="svn://svn.linuxfromscratch.org"

DOC_MODE=$1  # Action to take, update, get or none
BLFS_XML=$2  # Book directory
TREE=$3      # SVN tree for the BLFS book version

[[ -z $BLFS_XML ]] && BLFS_XML=blfs-xml
[[ -z $DOC_MODE ]] && DOC_MODE=update
[[ -z $TREE ]] && TREE=trunk/BOOK

TRACKING_DIR=tracking-dir

#---------------------
# packages module
source libs/func_packages
[[ $? > 0 ]] && echo -e "\n\tERROR: func_packages did not load..\n" && exit

#----------------------------#
BOOK_Source() {              #
#----------------------------#
: <<inline_doc
    function:   Retrieve or upate a copy of the BLFS book
    input vars: $1 BLFS_XML book sources directory
                $2 DOC_MODE action get/update
                $3 TREE     SVN tree when $2=get
    externals:  none
    modifies:   $BLFS_XML directory tree
    returns:    nothing
    output:
    on error:   exit
    on success: text messages
inline_doc

  case $DOC_MODE in
    update )
      if [[ ! -d $BLFS_XML ]] ; then
        echo -e "\n\t$BLFS_XML is not a directory\n"
        exit 1
      fi
      if [[ ! -f $BLFS_XML/x/x.xml ]] ; then
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
      svn co $SVN/BLFS/$TREE $BLFS_XML 2>&1
      ;;
    * )
        echo -e "\n\tUnknown option ${DOC_MODE} ignored.\n"
    ;;
  esac
}

[ "${DOC_MODE}" != "none" ] && BOOK_Source

if [ "${DOC_MODE}" = "none" ] ; then
  echo -en "\n\tGenerating packages database file ..."
  LC_ALL=C && generate_packages
  echo "done."

  echo -en "\tGenerating alsa dependencies list ..."
  generate_alsa
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
  echo -e "done."

  echo -en "\tGenerating kde-koffice dependencies list ..."
  generate_kde_koffice
  echo -e "done."

  echo -en "\tGenerating xorg7 dependencies list ..."
  generate_xorg7
  echo "done."
fi

