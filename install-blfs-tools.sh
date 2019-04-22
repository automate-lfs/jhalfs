#!/bin/bash
# $Id$
set -e

: << inline_doc
Installs a set-up to build BLFS packages.
You can set these variables:
TRACKING_DIR  : where the installed package file is kept.
                 (default /var/lib/jhalfs/BLFS)
BLFS_ROOT     : where the installed tools will be installed, relative to $HOME.
                Must start with a '/' (default /blfs_root)
BLFS_BRANCH_ID: development, branch-xxx, xxx (where xxx is a valid tag)
                (default development)
INITSYS   : which book do you want? 'sysv' or 'systemd' (default sysv)
Examples:
1 - If you plan to use the tools to build BLFS on top of LFS, but you did not
use jhalfs, or forgot to include the jhalfs-blfs tools:
(as root) mkdir -p /var/lib/jhalfs/BLFS && chown -R <user> /var/lib/jhalfs
(as user) INITSYS=<your system> ./install-blfs-tools.sh
2 - To install with only user privileges (default to sysv):
TRACKING_DIR=$HOME/blfs_root/trackdir ./install-blfs-tools.sh

This script can also be called automatically after running make in this
directory. The parameters will then be taken from the configuration file.
inline_doc


# VT100 colors
declare -r  BLACK=$'\e[1;30m'
declare -r  DK_GRAY=$'\e[0;30m'

declare -r  RED=$'\e[31m'
declare -r  GREEN=$'\e[32m'
declare -r  YELLOW=$'\e[33m'
declare -r  BLUE=$'\e[34m'
declare -r  MAGENTA=$'\e[35m'
declare -r  CYAN=$'\e[36m'
declare -r  WHITE=$'\e[37m'

declare -r  OFF=$'\e[0m'
declare -r  BOLD=$'\e[1m'
declare -r  REVERSE=$'\e[7m'
declare -r  HIDDEN=$'\e[8m'

declare -r  tab_=$'\t'
declare -r  nl_=$'\n'

declare -r   DD_BORDER="${BOLD}==============================================================================${OFF}"
declare -r   SD_BORDER="${BOLD}------------------------------------------------------------------------------${OFF}"
declare -r STAR_BORDER="${BOLD}******************************************************************************${OFF}"
declare -r dotSTR=".................." # Format display of parameters and versions

# bold yellow > <  pair
declare -r R_arrow=$'\e[1;33m>\e[0m'
declare -r L_arrow=$'\e[1;33m<\e[0m'
VERBOSITY=1

# Take parameters from "configuration" if $1="auto"
if [ "$1" = auto ]; then
  [[ $VERBOSITY > 0 ]] && echo -n "Loading configuration ... "
  source configuration
  [[ $? > 0 ]] && echo -e "\nconfiguration could not be loaded" && exit 2
  [[ $VERBOSITY > 0 ]] && echo "OK"
fi

if [ "$BOOK_BLFS" = y ]; then
## Read variables and sanity checks
  [[ "$relSVN" = y ]] && BLFS_BRANCH_ID=development
  [[ "$BRANCH" = y ]] && BLFS_BRANCH_ID=$BRANCH_ID
  [[ "$WORKING_COPY" = y ]] && BLFS_BOOK=$BOOK
  [[ "$BRANCH_ID" = "**EDIT ME**" ]] &&
    echo You have not set the book version or branch && exit 1
  [[ "$BOOK" = "**EDIT ME**" ]] &&
    echo You have not set the working copy location && exit 1
fi

COMMON_DIR="common"
# blfs-tool envars
BLFS_TOOL='y'
BUILDDIR=$(cd ~;pwd)
BLFS_ROOT="${BLFS_ROOT:=/blfs_root}"
TRACKING_DIR="${TRACKING_DIR:=/var/lib/jhalfs/BLFS}"
INITSYS="${INITSYS:=sysv}"
BLFS_BRANCH_ID=${BLFS_BRANCH_ID:=development}
BLFS_XML=${BLFS_XML:=blfs-xml}

# Validate the configuration:
PARAMS="BLFS_ROOT TRACKING_DIR INITSYS BLFS_XML"
if [ "$WORKING_COPY" = y ]; then
  PARAMS="$PARAMS WORKING_COPY BOOK"
else
  PARAMS="$PARAMS BLFS_BRANCH_ID"
fi
# Format for displaying parameters:
declare -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'

for config_param in $PARAMS; do
  echo -e "`eval echo $PARAM_VALS`"
done

echo "${SD_BORDER}${nl_}"
echo -n "Are you happy with these settings? yes/no (no): "
read ANSWER
if [ x$ANSWER != "xyes" ] ; then
  echo "${nl_}Rerun make and fix your settings.${nl_}"
  exit
fi
[[ $VERBOSITY > 0 ]] && echo "${SD_BORDER}${nl_}"

#*******************************************************************#
[[ $VERBOSITY > 0 ]] && echo -n "Loading function <func_check_version.sh>..."
source $COMMON_DIR/libs/func_check_version.sh
[[ $? > 0 ]] && echo " function module did not load.." && exit 2
[[ $VERBOSITY > 0 ]] && echo "OK"

[[ $VERBOSITY > 0 ]] && echo "${SD_BORDER}${nl_}"

case $BLFS_BRANCH_ID in
  development )  BLFS_TREE=trunk/BOOK ;;
     branch-* )  BLFS_TREE=branches/${BLFS_BRANCH_ID#branch-} ;;
            * )  BLFS_TREE=tags/${BLFS_BRANCH_ID} ;;
esac

# Check for build prerequisites.
echo
  check_alfs_tools
  check_blfs_tools
echo "${SD_BORDER}${nl_}"

# Install the files
[[ $VERBOSITY > 0 ]] && echo -n Populating the ${BUILDDIR}${BLFS_ROOT} directory
[[ ! -d ${BUILDDIR}${BLFS_ROOT} ]] && mkdir -pv ${BUILDDIR}${BLFS_ROOT}
rm -rf ${BUILDDIR}${BLFS_ROOT}/*
cp -r BLFS/* ${BUILDDIR}${BLFS_ROOT}
cp -r menu ${BUILDDIR}${BLFS_ROOT}
cp $COMMON_DIR/progress_bar.sh ${BUILDDIR}${BLFS_ROOT}
cp README.BLFS ${BUILDDIR}${BLFS_ROOT}
[[ $VERBOSITY > 0 ]] && echo "... OK"

# Clean-up
[[ $VERBOSITY > 0 ]] && echo Cleaning the ${BUILDDIR}${BLFS_ROOT} directory
make -C ${BUILDDIR}${BLFS_ROOT}/menu clean
rm -rf ${BUILDDIR}${BLFS_ROOT}/libs/.svn
rm -rf ${BUILDDIR}${BLFS_ROOT}/xsl/.svn
rm -rf ${BUILDDIR}${BLFS_ROOT}/menu/.svn
rm -rf ${BUILDDIR}${BLFS_ROOT}/menu/lxdialog/.svn
# We do not want to keep an old version of the book:
rm -rf ${BUILDDIR}${BLFS_ROOT}/$BLFS_XML

# Set some harcoded envars to their proper values
sed -i s@tracking-dir@$TRACKING_DIR@ \
    ${BUILDDIR}${BLFS_ROOT}/{Makefile,gen-makefile.sh}

# Ensures the tracking directory exists.
# Throws an error if it does not exist and the user does not
# have write permission to create it.
# If it exists, does nothing.
mkdir -p $TRACKING_DIR
[[ $VERBOSITY > 0 ]] && echo "... OK"

[[ $VERBOSITY > 0 ]] &&
echo "Retrieving and validating the book (may take some time)"

[[ -z "$BLFS_BOOK" ]] ||
[[ $BLFS_BOOK = $BUILDDIR$BLFS_ROOT/$BLFS_XML ]] ||
cp -a $BLFS_BOOK $BUILDDIR$BLFS_ROOT/$BLFS_XML

make -j1 -C $BUILDDIR$BLFS_ROOT \
     TRACKING_DIR=$TRACKING_DIR \
     REV=$INITSYS            \
     BLFS_XML=$BUILDDIR$BLFS_ROOT/$BLFS_XML      \
     SVN=svn://svn.linuxfromscratch.org/BLFS/$BLFS_TREE \
     $BUILDDIR$BLFS_ROOT/packages.xml
[[ $VERBOSITY > 0 ]] && echo "... OK"

