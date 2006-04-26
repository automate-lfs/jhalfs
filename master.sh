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
    echo -e "\n\t${BOLD}Goodbye and thank you for choosing ${L_arrow}jhalfs-X${R_arrow}\n"
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

[[ $VERBOSITY > 0 ]] && echo -n "Loading common-functions module..."
source $COMMON_DIR/common-functions
[[ $? > 0 ]] && echo " $COMMON_DIR/common-functions did not load.." && exit
[[ $VERBOSITY > 0 ]] && echo "OK"
#
[[ $VERBOSITY > 0 ]] && echo -n "Loading masterscript conf..."
source $COMMON_DIR/config
[[ $? > 0 ]] && echo "$COMMON_DIR/conf did not load.." && exit
[[ $VERBOSITY > 0 ]] && echo "OK"
#
[[ $VERBOSITY > 0 ]] && echo -n "Loading compare module..."
source $COMMON_DIR/func_compare.sh
[[ $? > 0 ]] && echo "$COMMON_DIR/func_compare.sh did not load.." && exit
[[ $VERBOSITY > 0 ]] && echo "OK"
#
[[ $VERBOSITY > 0 ]] && echo -n "Loading config module <$MODULE_CONFIG>..."
source $MODULE_CONFIG
[[ $? > 0 ]] && echo "$MODULE_CONFIG did not load.." && exit 1
[[ $VERBOSITY > 0 ]] && echo "OK"
#
[[ $VERBOSITY > 0 ]] && echo -n "Loading code module <$MODULE>..."
source $MODULE
[[ $? > 0 ]] && echo "$MODULE did not load.." && exit 2
[[ $VERBOSITY > 0 ]] && echo "OK"
#
[[ $VERBOSITY > 0 ]] && echo "---------------${nl_}"


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
[[ $VERBOSITY > 0 ]] && echo "---------------${nl_}"


###################################
###          MAIN               ###
###################################

# Evaluate any command line switches

while test $# -gt 0 ; do
  case $1 in
  # Common options for all books
    --book | -B )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        dev* | SVN | trunk )
          LFSVRS=development
          ;;
        *) if [[ "$PROGNAME" = "lfs" ]]; then
             case $1 in
               6.1.1 )
                 echo "For stable 6.1.1 book, please use jhalfs-0.2."
                 exit 0
                ;;
               udev*)  LFSVRS=udev_update   ;;
               * )
                 echo "$1 is an unsupported version at this time."
                 exit 0
                ;;
             esac
           else
             echo "The requested version, ${L_arrow} ${BOLD}$1${OFF} ${R_arrow}, is undefined in the ${BOLD}$(echo $PROGNAME | tr [a-z] [A-Z])${OFF} series."
             exit 0
           fi
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
          JHALFSDIR=$BUILDDIR/jhalfs
          LOGDIR=$JHALFSDIR/logs
          MKFILE=$JHALFSDIR/Makefile
          ;;
      esac
      ;;

    --get-packages | -G )      HPKG=1    ;;

    --help | -h )  usage | more && exit  ;;

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
          if [ -f $1/patches.ent ] ; then
            WC=1
            BOOK=$1
          else
            echo -e "\nLooks like $1 isn't a LFS working copy."
            exit 1
          fi
          ;;
        clfs)
          if [ -f $1/patches.ent ] && [ -f $1/packages.ent ]; then
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
            echo -e "\nLooks like $1 isn't a HLFS working copy."
            exit 1
          fi
          ;;
        blfs)
          if [ -f $1/use-unzip.xml ] ; then
            WC=1
            BOOK=$1
          else
            echo -e "\nLooks like $1 isn't a BLFS working copy."
            exit 1
          fi
          ;;
      esac
      ;;

    # Common options for LFS, CLFS and HLFS
    --comparasion | -C )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        ICA)              RUN_ICA=1
                        RUN_FARCE=0
                          COMPARE=1
        ;;
        farce)            RUN_ICA=0
                        RUN_FARCE=1
                          COMPARE=1
        ;;
        both)             RUN_ICA=1
                        RUN_FARCE=1
                          COMPARE=1
        ;;
        *)
          echo -e "\n$1 is an unknown analisys method."
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

    --make | -M )          RUNMAKE=1 ;;

    --rebuild | -R )       CLEAN=1   ;;

    # CLFS options
    --arch | -A )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        x86 )
          ARCH=x86
          TARGET="i686-pc-linux-gnu"
          ;;
        i486 )
          ARCH=x86
          TARGET="i486-pc-linux-gnu"
          ;;
        i586 )
          ARCH=x86
          TARGET="i586-pc-linux-gnu"
          ;;
        ppc )
          ARCH=ppc
          TARGET="powerpc-unknown-linux-gnu"
          ;;
        mips )
          ARCH=mips
          TARGET="mips-unknown-linux-gnu"
          ;;
        mipsel )
          ARCH=mips
          TARGET="mipsel-unknown-linux-gnu"
          ;;
        sparc )
          ARCH=sparc
          TARGET="sparcv9-unknown-linux-gnu"
          ;;
        sparcv8 )
          ARCH=sparcv8
          TARGET="sparc-unknown-linux-gnu"
          ;;
        x86_64-64 )
          ARCH=x86_64-64
          TARGET="x86_64-unknown-linux-gnu"
          ;;
        mips64-64 )
          ARCH=mips64-64
          TARGET="mips-unknown-linux-gnu"
          ;;
        mipsel64-64 )
          ARCH=mips64-64
          TARGET="mipsel-unknown-linux-gnu"
          ;;
        sparc64-64 )
          ARCH=sparc64-64
          TARGET="sparc64-unknown-linux-gnu"
          ;;
        alpha )
          ARCH=alpha
          TARGET="alpha-unknown-linux-gnu"
          ;;
        x86_64 )
          ARCH=x86_64
          TARGET="x86_64-unknown-linux-gnu"
          TARGET32="i686-pc-linux-gnu"
          ;;
        mips64 )
          ARCH=mips64
          TARGET="mips-unknown-linux-gnu"
          TARGET32="mips-unknown-linux-gnu"
          ;;
        mipsel64 )
          ARCH=mips64
          TARGET="mipsel-unknown-linux-gnu"
          TARGET32="mipsel-unknown-linux-gnu"
          ;;
        sparc64 )
          ARCH=sparc64
          TARGET="sparc64-unknown-linux-gnu"
          TARGET32="sparcv9-unknown-linux-gnu"
          ;;
        ppc64 )
          ARCH=ppc64
          TARGET="powerpc64-unknown-linux-gnu"
          TARGET32="powerpc-unknown-linux-gnu"
          ;;
        * )
          echo -e "\n$1 is an unknown or unsopported arch."
          exit 1
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

    # BLFS options
    --dependencies )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        0 | 1 | 2 )
          DEPEND=$1
          ;;
        * )
          echo -e "\n$1 isn't a valid dependencies level."
          exit 1
          ;;
      esac
      ;;

    # Unknown options
    * )   usage   ;;
  esac
  shift
done

# Find the download client to use, if not already specified.

if [ -z $DL ] ; then
  if [ `type -p wget` ] ; then
    DL=wget
  elif [ `type -p curl` ] ; then
    DL=curl
  else
    eval "$no_dl_client"
  fi
fi

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


# Check for minumum gcc and kernel versions
#check_requirements  1 # 0/1  0-do not display values.
echo
check_version "2.6.2" "`uname -r`"         "KERNEL"
check_version "3.0"   "$BASH_VERSION"      "BASH"
check_version "3.0"   "`gcc -dumpversion`" "GCC"
tarVer=`tar --version`
check_version "1.15.0" "${tarVer##* }"      "TAR"
echo "---------------${nl_}"

validate_config
echo "---------------${nl_}"

echo -n "Are you happy with these settings? yes/no (no): "
read ANSWER
if [ x$ANSWER != "xyes" ] ; then
  echo "${nl_}Fix the configuration options and rerun the script.${nl_}"
  exit 1
fi
echo "${nl_}---------------${nl_}"

# Prevents setting "-d /" by mistake.

if [ $BUILDDIR = / ] ; then
  echo -ne "\nThe root directory can't be used to build LFS.\n\n"
  exit 1
fi

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

if [[ "$PWD" != "$JHALFSDIR" ]]; then
  cp $COMMON_DIR/makefile-functions $JHALFSDIR/
  if [[ "$COMPARE" != "0" ]] ; then
    mkdir -p $JHALFSDIR/extras
    cp extras/* $JHALFSDIR/extras
  fi
  if [[ -n "$FILES" ]]; then
    # pushd/popd necessary to deal with mulitiple files
    pushd $PACKAGE_DIR 1> /dev/null
      cp $FILES $JHALFSDIR/
    popd 1> /dev/null
  fi
  [[ "$REPORT" = "1" ]] && cp $COMMON_DIR/create-sbu_du-report.sh  $JHALFSDIR/
  sed 's,FAKEDIR,'$BOOK',' $PACKAGE_DIR/$XSL > $JHALFSDIR/${XSL}
  export XSL=$JHALFSDIR/${XSL}
fi

if [[ ! -d $LOGDIR ]]; then
  mkdir $LOGDIR
fi
>$LOGDIR/$LOG

get_book
echo "---------------${nl_}"

build_Makefile
echo "---------------${nl_}"

run_make

