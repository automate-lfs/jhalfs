#!/bin/bash
# $Id$
set -e

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

# bold yellow > <  pair
declare -r R_arrow=$'\e[1;33m>\e[0m'
declare -r L_arrow=$'\e[1;33m<\e[0m'

VERBOSITY=1

COMMON_DIR="common"
BLFS_TOOL='y'
BUILDDIR=$(cd ~;pwd)
BLFS_ROOT="/blfs_root"
TRACKING_DIR="/var/lib/jhalfs/BLFS"

[[ $VERBOSITY > 0 ]] && echo "${SD_BORDER}${nl_}"

#*******************************************************************#
[[ $VERBOSITY > 0 ]] && echo -n "Loading function <func_check_version.sh>..."
source $COMMON_DIR/libs/func_check_version.sh
[[ $? > 0 ]] && echo " function module did not load.." && exit 2
[[ $VERBOSITY > 0 ]] && echo "OK"

[[ $VERBOSITY > 0 ]] && echo "${SD_BORDER}${nl_}"

# blfs-tool envars
BLFS_BRANCH_ID=${BLFS_BRANCH_ID:=development}
case $BLFS_BRANCH_ID in
  development )  BLFS_TREE=trunk/BOOK ;;
     branch-* )  BLFS_TREE=branches/${BLFS_BRANCH_ID#branch-} ;;
            * )  BLFS_TREE=tags/${BLFS_BRANCH_ID} ;;
esac

# Check for build prerequisites.
echo
  check_prerequisites
echo "${SD_BORDER}${nl_}"

# Install the files
[[ $VERBOSITY > 0 ]] && echo -n Populating the ${BUILDDIR}${BLFS_ROOT} directory
[[ ! -d ${BUILDDIR}${BLFS_ROOT} ]] && mkdir -pv ${BUILDDIR}${BLFS_ROOT}
cp -r BLFS/* ${BUILDDIR}${BLFS_ROOT}
cp -r menu ${BUILDDIR}${BLFS_ROOT}
cp $COMMON_DIR/progress_bar.sh ${BUILDDIR}${BLFS_ROOT}
cp README.BLFS ${BUILDDIR}${BLFS_ROOT}
[[ $VERBOSITY > 0 ]] && echo "... OK"
[[ $VERBOSITY > 0 ]] && echo -n Cleaning the ${BUILDDIR}${BLFS_ROOT} directory

# Clean-up
make -C ${BUILDDIR}${BLFS_ROOT}/menu clean
rm -rf ${BUILDDIR}${BLFS_ROOT}/libs/.svn
rm -rf ${BUILDDIR}${BLFS_ROOT}/xsl/.svn
rm -rf ${BUILDDIR}${BLFS_ROOT}/menu/.svn
rm -rf ${BUILDDIR}${BLFS_ROOT}/menu/lxdialog/.svn

# Set some harcoded envars to their proper values
sed -i s@tracking-dir@$TRACKING_DIR@ \
    ${BUILDDIR}${BLFS_ROOT}/{Makefile,gen-makefile.sh}
[[ $VERBOSITY > 0 ]] && echo "... OK"

[[ $VERBOSITY > 0 ]] && echo -n "Downloading and validating the book (may take some time)"
make -j1 -C $BUILDDIR$BLFS_ROOT TRACKING_DIR=$TRACKING_DIR \
    $BUILDDIR$BLFS_ROOT/packages.xml
[[ $VERBOSITY > 0 ]] && echo "... OK"

