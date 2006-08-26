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


#>>>>>>>>>>>>>>>ERROR TRAPPING >>>>>>>>>>>>>>>>>>>>
#-----------------------#
simple_error() {        # Basic error trap.... JUST DIE
#-----------------------#
  # If +e then disable text output
  if [[ "$-" =~ "e" ]]; then
    echo -e "\n${RED}ERROR:${GREEN} basic error trapped!${OFF}\n" >&2
  fi
}

see_ya() {
    echo -e "\n${L_arrow}${BOLD}jhalfs-X${R_arrow} exit${OFF}\n"
}
##### Simple error TRAPS
# ctrl-c   SIGINT
# ctrl-y
# ctrl-z   SIGTSTP
# SIGHUP   1 HANGUP
# SIGINT   2 INTRERRUPT FROM KEYBOARD Ctrl-C
# SIGQUIT  3
# SIGKILL  9 KILL
# SIGTERM 15 TERMINATION
# SIGSTOP 17,18,23 STOP THE PROCESS
#####
set -e
trap see_ya 0
trap simple_error ERR
trap 'echo -e "\n\n${RED}INTERRUPT${OFF} trapped\n" &&  exit 2'  1 2 3 15 17 18 23
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

version="
${BOLD}  \"jhalfs-X\"${OFF} builder tool (experimental) \$Rev$
  \$Date$

  Written by George Boudreau and Manuel Canales Esparcia,
  plus several contributions.

  Based on an idea from Jeremy Huntwork

  This set of files are published under the
  ${BOLD}Gnu General Public License, Version 2.${OFF}
"

if [ ! -L $0 ] ; then
  echo "$version"
  echo "${nl_}${tab_}${BOLD}${RED}This script cannot be called directly: EXITING ${OFF}${nl_}"
  exit 1
fi

    PROGNAME=$(basename $0)
  COMMON_DIR="common"
PACKAGE_DIR=$(echo $PROGNAME | tr [a-z] [A-Z])
      MODULE=$PACKAGE_DIR/master.sh
   VERBOSITY=1


[[ $VERBOSITY > 0 ]] && echo -n "Loading config params from <configuration>..."
source configuration
[[ $? > 0 ]] && echo "file:configuration did not load.." && exit 1
[[ $VERBOSITY > 0 ]] && echo "OK"

      #--- Envars not sourced from configuration (yet)
declare -r SVN="svn://svn.linuxfromscratch.org"
declare -r LOG=000-masterscript.log

case $PROGNAME in
  clfs2) LFSVRS=development; TREE=branches/clfs-2.0/BOOK ;;
      *) LFSVRS=development; TREE=trunk/BOOK             ;;
esac

if [[ ! -z ${BRANCH_ID} ]]; then
  case $BRANCH_ID in
    dev* | SVN | trunk )
      case $PROGNAME in
        clfs2 ) TREE=branches/clfs-2.0/BOOK ;;
             *) TREE=trunk/BOOK ;;
      esac
      LFSVRS=development
      ;;
    branch-* )
      LFSVRS=${BRANCH_ID}
      TREE=branches/${BRANCH_ID#branch-}/BOOK
      ;;
    * )
      case $PROGNAME in
        lfs | hlfs )
          LFSVRS=${BRANCH_ID}
          TREE=tags/${BRANCH_ID}/BOOK
          ;;
        clfs | clfs2 )
          LFSVRS=${BRANCH_ID}
          TREE=tags/${BRANCH_ID}
          ;;
      esac
      ;;
  esac
fi
# These are boolean vars generated from Config.in.
# ISSUE: If a boolean parameter is not set <true> that
# variable is not defined by the menu app. This can
# cause a headache if you are not careful.
#  The following parameters MUST be created and have a
#  default value.
RUNMAKE=${RUNMAKE:-n}
GETPKG=${GETPKG:-n}
GETKERNEL=${GETKERNEL:-n}
COMPARE=${COMPARE:-n}
RUN_FARCE=${RUN_FARCE:-n}
RUN_ICA=${RUN_ICA:-n}
BOMB_TEST=${BOMB_TEST:-n}
STRIP=${STRIP:=n}
REPORT=${REPORT:=n}
VIMLANG=${VIMLANG:-n}
KEYMAP=${KEYMAP:=none}
GRSECURITY_HOST=${GRSECURITY_HOST:-n}


[[ $VERBOSITY > 0 ]] && echo -n "Loading common-functions module..."
source $COMMON_DIR/common-functions
[[ $? > 0 ]] && echo " $COMMON_DIR/common-functions did not load.." && exit
[[ $VERBOSITY > 0 ]] && echo "OK"
[[ $VERBOSITY > 0 ]] && echo -n "Loading code module <$MODULE>..."
source $MODULE
[[ $? > 0 ]] && echo "$MODULE did not load.." && exit 2
[[ $VERBOSITY > 0 ]] && echo "OK"
#
[[ $VERBOSITY > 0 ]] && echo "${SD_BORDER}${nl_}"


#===========================================================
# If the var BOOK contains something then, maybe, it points
# to a working doc.. set WC=1, else 'null'
#===========================================================
WC=${BOOK:+y}
#===========================================================

#===================================================
# Set the document location...
#===================================================
BOOK=${BOOK:=$PROGNAME-$LFSVRS}
#===================================================


#*******************************************************************#
[[ $VERBOSITY > 0 ]] && echo -n "Loading function <func_check_version.sh>..."
source $COMMON_DIR/func_check_version.sh
[[ $? > 0 ]] && echo " function module did not load.." && exit 2
[[ $VERBOSITY > 0 ]] && echo "OK"

[[ $VERBOSITY > 0 ]] && echo -n "Loading function <func_validate_configs.sh>..."
source $COMMON_DIR/func_validate_configs.sh
[[ $? > 0 ]] && echo " function module did not load.." && exit 2
[[ $VERBOSITY > 0 ]] && echo "OK"
[[ $VERBOSITY > 0 ]] && echo "${SD_BORDER}${nl_}"


###################################
###          MAIN               ###
###################################

# Check for minimum bash,tar,gcc and kernel versions
echo
check_version "2.6.2" "`uname -r`"         "KERNEL"
check_version "3.0"   "$BASH_VERSION"      "BASH"
check_version "3.0"   "`gcc -dumpversion`" "GCC"
tarVer=`tar --version | head -n1 | cut -d " " -f4`
check_version "1.15.0" "${tarVer}"      "TAR"
echo "${SD_BORDER}${nl_}"

validate_config
echo "${SD_BORDER}${nl_}"
echo -n "Are you happy with these settings? yes/no (no): "
read ANSWER
if [ x$ANSWER != "xyes" ] ; then
  echo "${nl_}Fix the configuration options and rerun the script.${nl_}"
  exit 1
fi
echo "${nl_}${SD_BORDER}${nl_}"

# Load additional modules or configuration files based on global settings
# compare module
if [[ "$COMPARE" = "y" ]]; then
  [[ $VERBOSITY > 0 ]] && echo -n "Loading compare module..."
  source $COMMON_DIR/func_compare.sh
  [[ $? > 0 ]] && echo "$COMMON_DIR/func_compare.sh did not load.." && exit
  [[ $VERBOSITY > 0 ]] && echo "OK"
fi
#
# optimize module
if [[ "$OPTIMIZE" != "0" ]]; then
  [[ $VERBOSITY > 0 ]] && echo -n "Loading optimization module..."
  source optimize/optimize_functions
  [[ $? > 0 ]] && echo " optimize/optimize_functions did not load.." && exit
  [[ $VERBOSITY > 0 ]] && echo "OK"
  #
  # optimize configurations
  [[ $VERBOSITY > 0 ]] && echo -n "Loading optimization config..."
  source optimize/opt_config
  [[ $? > 0 ]] && echo " optimize/opt_config did not load.." && exit
  [[ $VERBOSITY > 0 ]] && echo "OK"
  # Validate optimize settings, if required
  validate_opt_settings
fi
#

# If $BUILDDIR has subdirectories like tools/ or bin/, stop the run
# and notify the user about that.
if [ -d $BUILDDIR/tools -o -d $BUILDDIR/bin ] && [ -z $CLEAN ] ; then
  eval "$no_empty_builddir"
fi

# If requested, clean the build directory
clean_builddir

if [[ ! -d $JHALFSDIR ]]; then
  mkdir -p $JHALFSDIR
fi
#
# Create $BUILDDIR/sources even though it could be created by get_sources()
if [[ ! -d $BUILDDIR/sources ]]; then
  mkdir -p $BUILDDIR/sources
fi
#
# Create the log directory
if [[ ! -d $LOGDIR ]]; then
  mkdir $LOGDIR
fi
>$LOGDIR/$LOG
#
[[ "$TEST" != "0" ]] && [[ ! -d $TESTLOGDIR ]] && install -d -m 1777 $TESTLOGDIR
#
cp $COMMON_DIR/{makefile-functions,progress_bar.sh} $JHALFSDIR/
#
[[ "$OPTIMIZE" != "0" ]] && cp optimize/opt_override $JHALFSDIR/
#
if [[ "$COMPARE" = "y" ]]; then
  mkdir -p $JHALFSDIR/extras
  cp extras/* $JHALFSDIR/extras
fi
#
if [[ -n "$FILES" ]]; then
  # pushd/popd necessary to deal with multiple files
  pushd $PACKAGE_DIR 1> /dev/null
    cp $FILES $JHALFSDIR/
  popd 1> /dev/null
fi
#
if [[ "$REPORT" = "y" ]]; then
  cp $COMMON_DIR/create-sbu_du-report.sh  $JHALFSDIR/
  # After being sure that all looks sane, dump the settings to a file
  # This file will be used to create the REPORT header
  validate_config > $JHALFSDIR/jhalfs.config
fi
#
[[ "$GETPKG" = "y" ]] && cp $COMMON_DIR/urls.xsl  $JHALFSDIR/
#
cp $COMMON_DIR/packages.xsl  $JHALFSDIR/
#
sed 's,FAKEDIR,'$BOOK',' $PACKAGE_DIR/$XSL > $JHALFSDIR/${XSL}
export XSL=$JHALFSDIR/${XSL}

get_book
echo "${SD_BORDER}${nl_}"

build_Makefile
echo "${SD_BORDER}${nl_}"

run_make
