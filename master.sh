#!/bin/bash
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
    echo -e "\n\t${BOLD}Goodbye and thank you for choosing ${L_arrow}JHALFS${R_arrow}\n"
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


     PROGNAME=$(basename $0)
      VERSION="0.0.1"
       MODULE=$PROGNAME.module
MODULE_CONFIG=$PROGNAME.conf

echo -n "Loading common-func.module..."
source common-func.module
[[ $? > 0 ]] && echo "common-func.module did not load.." && exit
echo "OK"
#

if [ ! -L $0 ] ; then
  echo "${nl_}${tab_}${BOLD}${RED}This script cannot be called directly: EXITING ${OFF}${nl_}"
  exit 1
fi

echo -n "Loading masterscript.conf..."
source masterscript.conf
[[ $? > 0 ]] && echo "masterscript.conf did not load.." && exit 
echo "OK"
#
echo -n "Loading config module <$MODULE_CONFIG>..."
source $MODULE_CONFIG
[[ $? > 0 ]] && echo "$MODULE_CONFIG did not load.." && exit 1
echo "OK"
#
echo -n "Loading code module <$MODULE>..."
source $MODULE
if [[ $? > 0 ]]; then
 echo "$MODULE did not load.."
 exit 2
fi
echo "OK"
#
echo "---------------${nl_}"


#===========================================================
# If the var BOOK contains something then, maybe, it points
# to a working doc.. set WC=1, else 'null'
#===========================================================
WC=${BOOK:+1}
#===========================================================


#*******************************************************************#


#----------------------------#
check_requirements() {       # Simple routine to validate gcc and kernel versions against requirements
#----------------------------#
  # Minimum values acceptable
  #   bash  3.0>
  #    gcc  3.0>
  # kernel  2.6.2>

  [[ $1 = "1" ]] && echo "${nl_}BASH: ${L_arrow}${BOLD}${BASH_VERSION}${R_arrow}"
  case $BASH_VERSION in
    [3-9].*) ;;
    *) 'clear'
        echo -e "
$DD_BORDER
\t\t${OFF}${RED}BASH version ${BOLD}${YELLOW}-->${WHITE} $BASH_VERSION ${YELLOW}<--${OFF}${RED} is too old.
\t\t    This script requires 3.0${OFF}${RED} or greater
$DD_BORDER"
        exit 1
      ;;
  esac

  [[ $1 = "1" ]] && echo "GCC: ${L_arrow}${BOLD}`gcc -dumpversion`${R_arrow}"
    case `gcc -dumpversion` in
      [3-9].[0-9].* ) ;;
      *)  'clear'
           echo -e "
$DD_BORDER
\t\t${OFF}${RED}GCC version ${BOLD}${YELLOW}-->${WHITE} $(gcc -dumpversion) ${YELLOW}<--${OFF}${RED} is too old.
\t\t This script requires ${BOLD}${WHITE}3.0${OFF}${RED} or greater
$DD_BORDER"
           exit 1
      ;;
    esac

  #
  # >>>> Check kernel version against the minimum acceptable level <<<<
  #
  [[ $1 = "1" ]] && echo "LINUX: ${L_arrow}${BOLD}`uname -r`${R_arrow}"

  local IFS
  declare -i major minor revision change
  min_kernel_vers=2.6.2

  IFS=".-"   # Split up w.x.y.z as well as w.x.y-rc  (catch release candidates)
  set -- $min_kernel_vers # set postional parameters to minimum ver values
  major=$1; minor=$2; revision=$3
  #
  set -- `uname -r` # Set postional parameters to user kernel version
  #Compare against minimum acceptable kernel version..
  (( $1  > major )) && return
  (( $1 == major )) && (((  $2 >  minor )) ||
                       (((  $2 == minor )) && (( $3 >= revision )))) && return

  # oops.. write error msg and die
  echo -e "
$DD_BORDER
\t\t${OFF}${RED}The kernel version ${BOLD}${YELLOW}-->${WHITE} $(uname -r) ${YELLOW}<--${OFF}${RED} is too old.
\t\tThis script requires version ${BOLD}${WHITE}$min_kernel_vers${OFF}${RED} or greater
$DD_BORDER"
  exit 1
}


#----------------------------#
validate_config()    {       # Are the config values sane (within reason)
#----------------------------#
  local -r  lfs_PARAM_LIST="BUILDDIR HPKG TEST TOOLCHAINTEST STRIP VIMLANG PAGE RUNMAKE"
  local -r blfs_PARAM_LIST="BUILDDIR TEST DEPEND"
  local -r hlfs_PARAM_LIST="BUILDDIR HPKG MODEL TEST TOOLCHAINTEST STRIP VIMLANG PAGE GRSECURITY_HOST RUNMAKE TIMEZONE"
  local -r clfs_PARAM_LIST="ARCH BOOTMINIMAL RUNMAKE MKFILE"
  local -r global_PARAM_LIST="BUILDDIR HPKG RUNMAKE TEST TOOLCHAINTEST STRIP PAGE TIMEZONE VIMLANG"
  
  local    PARAM_LIST=

  local -r ERROR_MSG='The variable \"${L_arrow}${config_param}${R_arrow}\" value ${L_arrow}${BOLD}${!config_param}${R_arrow} is invalid, ${nl_}check the config file ${BOLD}${GREEN}\<$PROGNAME.conf\>${OFF}'
  local -r PARAM_VALS='${config_param}: ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'
  local config_param
  local validation_str

  write_error_and_die() {
    echo -e "\n${DD_BORDER}"
    echo -e "`eval echo ${ERROR_MSG}`" >&2
    echo -e "${DD_BORDER}\n"
    exit 1
  }

  set +e
  for PARAM_GROUP in global_PARAM_LIST ${PROGNAME}_PARAM_LIST; do
    for config_param in ${!PARAM_GROUP}; do
      # This is a tricky little piece of code.. executes a cmd string.
      [[ $1 = "1" ]] && echo -e "`eval echo $PARAM_VALS`"
      case $config_param in
        BUILDDIR) # We cannot have an <empty> or </> root mount point
            if [[ "xx x/x" =~ "x${!config_param}x" ]]; then
              write_error_and_die
            fi
            continue  ;;
        TIMEZONE)  continue;;
	MKFILE)    continue;;
        HPKG)      validation_str="x0x x1x"  ;;
        RUNMAKE)   validation_str="x0x x1x"  ;;
        TEST)      validation_str="x0x x1x"  ;;
        STRIP)     validation_str="x0x x1x"  ;;
        VIMLANG)   validation_str="x0x x1x"  ;;
        DEPEND)    validation_str="x0x x1x x2x" ;;
        MODEL)     validation_str="xglibcx xuclibcx" ;;
        PAGE)      validation_str="xletterx xA4x"  ;;
        ARCH)      validation_str="xx86x xx86_64x xx86_64-64x xsparcx xsparcv8x xsparc64x xsparc64-64x xmipsx xmips64x xmips64-64x xppcx xalphax" ;;
        TOOLCHAINTEST)    validation_str="x0x x1x"  ;;
        GRSECURITY_HOST)  validation_str="x0x x1x"  ;;
        BOOTMINIMAL)      validation_str="x0x x1x";;
        *)
          echo "WHAT PARAMETER IS THIS.. <<${config_param}>>"
          exit
        ;;
      esac
        #
        # This is the 'regexp' test available in bash-3.0..
        # using it as a poor man's test for substring
      if [[ ! "${validation_str}" =~ "x${!config_param}x" ]] ; then
        # parameter value entered is no good
        write_error_and_die
      fi
    done # for loop

      # Not further tests needed on globals
    if [[ "$PARAM_GROUP" = "global_PARAM_LIST" ]]; then
      echo "   ${BOLD}${GREEN}${PARAM_GROUP%%_*T} parameters are valid${OFF}"
      continue
    fi
    
    for config_param in LC_ALL LANG; do
      [[ $1 = "1" ]] && echo "`eval echo $PARAM_VALS`"
      [[ -z "${!config_param}" ]] && continue
      # See it the locale values exist on this machine
      [[ "`locale -a | grep -c ${!config_param}`" > 0 ]] && continue
  
      # If you make it this far then there is a problem
      write_error_and_die
    done

    for config_param in FSTAB CONFIG KEYMAP BOOK; do
      [[ $1 = "1" ]] && echo "`eval echo $PARAM_VALS`"
      if [[ $config_param = BOOK ]]; then
         [[ ! "${WC}" = 1 ]] && continue
      fi
      [[ -z "${!config_param}" ]] && continue
      [[ -e "${!config_param}" ]] && [[ -s "${!config_param}" ]] && continue
  
      # If you make it this far then there is a problem
      write_error_and_die
    done
      echo "   ${BOLD}${GREEN}${PARAM_GROUP%%_*T} parameters are valid${OFF}"
  done
  set -e
  echo "$tab_***${BOLD}${GREEN}Config parameters look good${OFF}***"
}



###################################
###		MAIN		###
###################################

# Evaluate any command line switches

while test $# -gt 0 ; do
  case $1 in
    --version | -V )
        clear
        echo "$version"
        exit 0
      ;;

    --help | -h )
        if [[ "$PROGNAME" = "blfs" ]]; then
          blfs_usage
        else
          usage
        fi
      ;;

    --LFS-version | -L )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        dev* | SVN | trunk )
          LFSVRS=development
          ;;
        6.1.1 )
          echo "For stable 6.1.1 book, please use jhalfs-0.2."
          exit 0
          ;;
	alpha*)
	  LFSVRS=alphabetical
	  ;;
        * )
          echo "$1 is an unsupported version at this time."
          exit 1
          ;;
      esac
      ;;

    --directory | -d )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      BUILDDIR=$1
      JHALFSDIR=$BUILDDIR/jhalfs
      LOGDIR=$JHALFSDIR/logs
      MKFILE=$JHALFSDIR/${PROGNAME}-Makefile
      ;;

    --rebuild )	  CLEAN=1 ;;

    --download-client | -D )
      echo "The download feature is temporarily disable.."
      exit
      test $# = 1 && eval "$exit_missing_arg"
      shift
      DL=$1
      ;;

    --working-copy | -W )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f $1/patches.ent ] ; then
      WC=1
      BOOK=$1
      else
        echo -e "\nLook like $1 isn't a supported working copy."
        echo -e "Verify your selection and the command line.\n"
        exit 1
      fi
      ;;

    --testsuites | -T )		TEST=1    ;;
    --get-packages | -P )	HPKG=1    ;;
    --run-make | -M )		RUNMAKE=1 ;;
    --no-toolchain-test )	TOOLCHAINTEST=0 ;;
    --no-strip )	STRIP=0   ;;
    --no-vim-lang )	VIMLANG=0 ;;

    --page_size )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      case $1 in
        letter | A4 )
          PAGE=$1
          ;;
        * )
          echo "$1 isn't a supported page size."
          exit 1
          ;;
      esac
      ;;

    --timezone )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f /usr/share/zoneinfo/$1 ] ; then
        TIMEZONE=$1
      else
        echo -e "\nLooks like $1 isn't a valid timezone description."
        echo -e "Verify your selection and the command line.\n"
        exit 1
      fi
      ;;

    --fstab )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f $1 ] ; then
        FSTAB=$1
      else
        echo -e "\nFile $1 not found. Verify your command line.\n"
        exit 1
      fi
      ;;

    --kernel-config | -C )
      test $# = 1 && eval "$exit_missing_arg"
      shift
      if [ -f $1 ] ; then
        CONFIG=$1
      else
        echo -e "\nFile $1 not found. Verify your command line.\n"
        exit 1
      fi
      ;;

    * )
      if [[ "$PROGNAME" = "blfs" ]]; then
        blfs_usage
      else
        usage
      fi
      ;;
  esac
  shift
done


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
# If set by conf file leave or cmd line leave it
# alone otherwise load the default version
#===================================================
BOOK=${BOOK:=$PROGNAME-$LFSVRS}
#===================================================

if [[ ! -d $JHALFSDIR ]]; then
  mkdir -pv $JHALFSDIR
fi

if [[ "$PWD" != "$JHALFSDIR" ]]; then 
  cp -v makefile-functions $JHALFSDIR/
  if [[ -n "$FILES" ]]; then
    cp -v $FILES $JHALFSDIR/ 
  fi
  sed 's,FAKEDIR,'$BOOK',' $XSL > $JHALFSDIR/${XSL}
  export XSL=$JHALFSDIR/${XSL}
fi

if [[ ! -d $LOGDIR ]]; then
  mkdir -v $LOGDIR
fi
>$LOGDIR/$LOG
echo "---------------${nl_}"


# Check for minumum gcc and kernel versions
check_requirements  1 # 0/1  0-do not display values.
echo "---------------${nl_}"
validate_config     1 # 0/1  0-do not display values
echo "---------------${nl_}"
get_book
echo "---------------${nl_}"
build_Makefile
echo "---------------${nl_}"
#run_make

