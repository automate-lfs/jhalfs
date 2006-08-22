#!/bin/bash
#
# $Id$
#
#  Read and parse the configuration parameters..
#
ConfigFile="configuration"
while [ 0 ]; do
  read || break 1

  # Garbage collection
  case ${REPLY} in
    \#* | '') continue ;;
  esac

  case "${REPLY}" in
    CONFIG_ALSA=* | \
    CONFIG_GNOME-CORE=* | \
    CONFIG_GNOME-FULL=* | \
    CONFIG_KDE-CORE=* | \
    CONFIG_KDE-FULL=* | \
    CONFIG_KDE-KOFFICE=* | \
    CONFIG_XORG7=* ) REPLY=${REPLY%=*}  # Strip the trailing '=y' test.. unecessary
                     echo -n "${REPLY}"
		     if [[ $((++cntr)) > 1 ]]; then
                       echo "  <<-- ERROR:: SELECT ONLY 1 PACKAGE AT A TIME, META-PACKAGE NOT SELECTED"
                     else
                       echo ""
                       optTARGET=$(echo $REPLY | cut -d "_" -f2 | tr [A-Z] [a-z])
                     fi
                     continue ;;

    # Create global variables for these parameters.
    optDependency=* | \
    PRINT_SERVER=*  | \
    MAIL_SERVER=*   | \
    GHOSTSCRIPT=*   | \
    KBR5=*  | \
    X11=*   | \
    SUDO=*  )  eval ${REPLY} # Define/set a global variable..
                      continue ;;
  esac

  if [[ "${REPLY}" =~ "^CONFIG_" ]]; then
    echo -n "$REPLY"
    if [[ $((++cntr)) > 1 ]]; then
      echo "  <<-- ERROR SELECT ONLY 1 PACKAGE AT A TIME, WILL NOT BUILD"
    else
      echo ""
      optTARGET=$( echo $REPLY | sed -e 's@CONFIG_@@' -e 's@=y@@' )
    fi
  fi
done <$ConfigFile
if [[ $optTARGET = "" ]]; then
  echo -e "\n>>> NO TARGET SELECTED.. applicaton terminated"
  echo -e "    Run <make> again and select a package to build\n"
  exit 0
fi

#
# Regenerate the META-package dependencies from the configuration file
#
rm -f libs/*.dep-MOD
while [ 0 ]; do
  read || break 1
  case ${REPLY} in
  \#* | '') continue ;;
  esac

    # Drop the "=y"
  REPLY=${REPLY%=*}
  if [[ "${REPLY}" =~ "^DEP_" ]]; then
    META_PACKAGE=$(echo $REPLY | cut -d "_" -f2 | tr [A-Z] [a-z])
    DEP_FNAME=$(echo $REPLY | cut -d "_" -f3)
     echo "${DEP_FNAME}" >>libs/${META_PACKAGE}.dep-MOD
  fi

done <$ConfigFile
#
# Replace to 'old' dependency file with a new one.
#
for dst in `ls ./libs/*.dep-MOD 2>/dev/null`; do
    cp -vf $dst ${dst%-MOD}
done


set -e
declare TARGET=$optTARGET
declare DEP_LEVEL=$optDependency
declare PKGXML
declare BLFS_XML
declare VERBOSITY=1
[[ -z $SUDO ]] && SUDO=y

#---------------------
# Constants
source libs/constants.inc
[[ $? > 0 ]] && echo -e "\n\tERROR: constants.inc did not load..\n" && exit

#---------------------
# Dependencies module
source libs/func_dependencies
[[ $? > 0 ]] && echo -e "\n\tERROR: func_dependencies did not load..\n" && exit

#---------------------
# parser module
source libs/func_parser
[[ $? > 0 ]] && echo -e "\n\tERROR: func_parser did not load..\n" && exit


#------- MAIN --------
if [[ ! -f packages ]] ; then
  echo -e "\tNo packages file has been found.\n"
  echo -e "\tExecution aborted.\n"
  exit 1
fi

generate_dependency_tree
generate_TARGET_xml
generate_target_book
create_build_scripts "${SUDO}"
