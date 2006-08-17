#!/bin/bash
# $Id$
set -e


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
    echo -e "\n${L_arrow}${BOLD}jhalfs${R_arrow} exit${OFF}\n"
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


if [ ! -L $0 ] ; then
  echo "${nl_}${tab_}${BOLD}${RED}This script cannot be called directly: EXITING ${OFF}${nl_}"
  exit 1
fi

     PROGNAME=$(basename $0)
   COMMON_DIR="common"
  PACKAGE_DIR=$(echo $PROGNAME | tr [a-z] [A-Z])
       MODULE=$PACKAGE_DIR/master.sh
MODULE_CONFIG=$PACKAGE_DIR/config
    VERBOSITY=0


if [[ -e using_menuconfig ]]; then
  [[ $VERBOSITY > 0 ]] && echo -n "Loading config params from <configuration>..."
  source configuration
  [[ $? > 0 ]] && echo "file:configuration did not load.." && exit 1
  [[ $VERBOSITY > 0 ]] && echo "OK"

        #--- CONSTANTS
  declare -r SVN="svn://svn.linuxfromscratch.org"
  declare -r LOG=000-masterscript.log
        # --- Server used if the file isn't found in SRC_ARCHIVE.
        # As a last resort, the file will dowloaded from upstream, if possible.
       SERVER=ftp://ftp.lfs-matrix.net
	#--- Working directories
  SCRIPT_ROOT=jhalfs
    JHALFSDIR=$BUILDDIR/$SCRIPT_ROOT
       LOGDIR=$JHALFSDIR/logs
   TESTLOGDIR=$JHALFSDIR/test-logs
       MKFILE=$JHALFSDIR/Makefile
	#--- ICA report log directory
    ICALOGDIR=$LOGDIR/ICA
	#--- farce report log directory
  FARCELOGDIR=$LOGDIR/farce
          XSL=$PROGNAME.xsl
      PKG_LST=unpacked

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

else
  #
  [[ $VERBOSITY > 0 ]] && echo -n "Loading masterscript conf..."
  source $COMMON_DIR/config
  [[ $? > 0 ]] && echo "$COMMON_DIR/conf did not load.." && exit
  [[ $VERBOSITY > 0 ]] && echo "OK"
  #
  [[ $VERBOSITY > 0 ]] && echo -n "Loading config module <$MODULE_CONFIG>..."
  source $MODULE_CONFIG
  [[ $? > 0 ]] && echo "$MODULE_CONFIG did not load.." && exit 1
  [[ $VERBOSITY > 0 ]] && echo "OK"
  #
fi


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
WC=${BOOK:+1}
#===========================================================


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

# Evaluate any command line switches

while test $# -gt 0 ; do
  case $1 in
  # Common options for {C,H}LFS books
    --book | -B )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        dev* | SVN | trunk )
          LFSVRS=development
          TREE=trunk/BOOK
          ;;
        branch-* )
          LFSVRS=$1
          TREE=branches/${1#branch-}/BOOK
          ;;
        * )
          case $PROGNAME in
            lfs | hlfs )
              LFSVRS=$1
              TREE=tags/$1/BOOK
              ;;
            clfs )
              LFSVRS=$1
              TREE=tags/$1
              ;;
          esac
          ;;
      esac
      ;;

    --directory | -D )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        -* )
          echo -e "\n$1 isn't a valid build directory."
          echo -e "Directory names can't start with - .\n"
          exit 1
          ;;
        * )
          BUILDDIR=$1
          JHALFSDIR=$BUILDDIR/${SCRIPT_ROOT}
          LOGDIR=$JHALFSDIR/logs
          TESTLOGDIR=$JHALFSDIR/test-logs
          MKFILE=$JHALFSDIR/Makefile
          ;;
      esac
      ;;

    --get-packages | -G )      GETPKG=y    ;;

    --help | -h )  usage | more && exit  ;;

    --optimize | -O )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        0 | 1 | 2 )
          OPTIMIZE=$1
          ;;
        * )
          echo -e "\n$1 isn't a valid optimize level value."
          echo -e "You must use 0, 1, or 2.\n"
          exit 1
          ;;
      esac
      ;;

    --testsuites | -T )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        0 | 1 | 2 | 3 )
          TEST=$1
          ;;
        * )
          echo -e "\n$1 isn't a valid testsuites level value."
          echo -e "You must to use 0, 1, 2, or 3.\n"
          exit 1
          ;;
      esac
      ;;

    --version | -V )
        echo "$version"
        exit 0
      ;;

    --working-copy | -W )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $PROGNAME in # Poor checks. We should find better ones.
        lfs)
          if [ -d $1/chapter09 ] ; then
            WC=1
            BOOK=$1
          else
            echo -e "\nLooks like $1 isn't an LFS working copy."
            exit 1
          fi
          ;;
        clfs)
          if [ -d $1/cross-tools ] ; then
            WC=1
            BOOK=$1
          else
            echo -e "\nLooks like $1 isn't a CLFS working copy."
            exit 1
          fi
          ;;
        hlfs)
          if [ -f $1/template.xml ] ; then
            WC=1
            BOOK=$1
          else
            echo -e "\nLooks like $1 isn't an HLFS working copy."
            exit 1
          fi
          ;;
      esac
      ;;

    --comparison | -C )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        ICA)    RUN_ICA=y; RUN_FARCE=n; COMPARE=y  ;;
        farce)  RUN_ICA=n; RUN_FARCE=y; COMPARE=y  ;;
        both)   RUN_ICA=y; RUN_FARCE=y; COMPARE=y  ;;
        *)
          echo -e "\n$1 is an unknown analysis method."
          exit 1
          ;;
      esac
      ;;

    --fstab | -F )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f $1 ] ; then
        FSTAB=$1
      else
        echo -e "\nFile $1 not found. Verify your command line.\n"
        exit 1
      fi
      ;;

    --kernel-config | -K )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f $1 ] ; then
        CONFIG=$1
      else
        echo -e "\nFile $1 not found. Verify your command line.\n"
        exit 1
      fi
      ;;

    --run-make | -M )      RUNMAKE=y ;;

    --rebuild | -R )       CLEAN=y   ;;

    # CLFS options
    --arch | -A )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $PROGNAME in
        CLFS2)
	  case $1 in
            arm) ARCH=arm; TARGET="arm-unknown-linux-gnu" ;;
            x86) ARCH=x86; TARGET="i686-pc-linux-gnu"     ;;
	      *) echo -e "\n$1 is an unknown or unsupported arch.";  exit 1
          esac
	  ;;
        CLFS)
          case $1 in
            arm )   ARCH=arm;   TARGET="arm-unknown-linux-gnu" ;;
            x86 )   ARCH=x86;   TARGET="i686-pc-linux-gnu"     ;;
           i486 )   ARCH=x86;   TARGET="i486-pc-linux-gnu"     ;;
           i586 )   ARCH=x86;   TARGET="i586-pc-linux-gnu"     ;;
            ppc )   ARCH=ppc;   TARGET="powerpc-unknown-linux-gnu"   ;;
           mips )   ARCH=mips;  TARGET="mips-unknown-linux-gnu"      ;;
           mipsel ) ARCH=mips;  TARGET="mipsel-unknown-linux-gnu"    ;;
            sparc ) ARCH=sparc; TARGET="sparcv9-unknown-linux-gnu"   ;;

           x86_64-64 )   ARCH=x86_64-64;  TARGET="x86_64-unknown-linux-gnu"   ;;
           mips64-64 )   ARCH=mips64-64;  TARGET="mips-unknown-linux-gnu"     ;;
           mipsel64-64 ) ARCH=mips64-64;  TARGET="mipsel-unknown-linux-gnu" ;;
           sparc64-64 )  ARCH=sparc64-64; TARGET="sparc64-unknown-linux-gnu" ;;
           alpha )       ARCH=alpha;      TARGET="alpha-unknown-linux-gnu"   ;;

           x86_64 )   ARCH=x86_64;  TARGET="x86_64-unknown-linux-gnu";    TARGET32="i686-pc-linux-gnu"        ;;
           mips64 )   ARCH=mips64;  TARGET="mips-unknown-linux-gnu";      TARGET32="mips-unknown-linux-gnu"   ;;
           mipsel64 ) ARCH=mips64;  TARGET="mipsel-unknown-linux-gnu";    TARGET32="mipsel-unknown-linux-gnu"  ;;
           sparc64 )  ARCH=sparc64; TARGET="sparc64-unknown-linux-gnu";   TARGET32="sparcv9-unknown-linux-gnu"  ;;
            ppc64 )   ARCH=ppc64;   TARGET="powerpc64-unknown-linux-gnu"; TARGET32="powerpc-unknown-linux-gnu"  ;;

            * )  echo -e "\n$1 is an unknown or unsupported arch.";   exit 1  ;;
          esac
	  ;;
      esac
      ;;

    --boot-config )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f $1 ] ; then
        BOOT_CONFIG=$1
      else
        echo -e "\nFile $1 not found. Verify your command line.\n"
        exit 1
      fi
      ;;

    --method )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        chroot | boot )
          METHOD=$1
          ;;
        * )
          echo -e "\n$1 isn't a valid build method."
          exit 1
          ;;
      esac
      ;;

    # HLFS options
    --model )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        glibc | uclibc )
          MODEL=$1
          ;;
        * )
          echo -e "\n$1 isn't a valid libc model."
          exit 1
          ;;
      esac
      ;;

    # Unknown options
    * )   usage   ;;
  esac
  shift
done


#===================================================
# Set the document location...
# BOOK is either defined in
#   xxx.config
#   comand line
#   default
# If set by conf file or cmd line leave it
# alone otherwise load the default version
#===================================================
BOOK=${BOOK:=$PROGNAME-$LFSVRS}
#===================================================


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
if [[ "$PWD" != "$JHALFSDIR" ]]; then
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
fi

get_book
echo "${SD_BORDER}${nl_}"

build_Makefile
echo "${SD_BORDER}${nl_}"

run_make
