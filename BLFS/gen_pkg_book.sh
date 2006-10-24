#!/bin/bash
#
# $Id$
#
#  Read and parse the configuration parameters..
#
set -e

declare -r ConfigFile="configuration"
declare TARGET
declare DEP_LEVEL
declare SUDO
declare PKGXML
declare BLFS_XML
declare VERBOSITY=1

#--------------------------#
parse_configuration() {    #
#--------------------------#
  local	cntr
  local	optTARGET

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

    if [[ "${REPLY}" =~ ^CONFIG_ ]]; then
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

  TARGET=$optTARGET
  DEP_LEVEL=$optDependency
  SUDO=${SUDO:-n}
}

#--------------------------#
validate_configuration() { #
#--------------------------#
  local -r dotSTR=".................."
  local -r PARAM_LIST="TARGET DEP_LEVEL SUDO PRINT_SERVER MAIL_SERVER GHOSTSCRIPT KBR5 X11"
  local -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'
  local config_param

  for config_param in ${PARAM_LIST}; do
    echo -e "`eval echo $PARAM_VALS`"
  done
}

#
# Regenerate the META-package dependencies from the configuration file
#
#--------------------------#
regenerate_deps() {        #
#--------------------------#

  rm -f libs/*.dep-MOD
  while [ 0 ]; do
    read || break 1
    case ${REPLY} in
      \#* | '') continue ;;
    esac

    # Drop the "=y"
    REPLY=${REPLY%=*}
    if [[ "${REPLY}" =~ ^DEP_ ]]; then
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
}

#
# Clean configuration file keeping only global default settings.
# That prevent "trying to assign nonexistent symbol" messages
# and assures that there is no TARGET selected from a previous run
#
#--------------------------#
clean_configuration() {    #
#--------------------------#

tail -n 30 configuration > configuration.tmp
mv configuration.tmp configuration

}

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


parse_configuration
validate_configuration
echo "${SD_BORDER}${nl_}"
echo -n "Are you happy with these settings? yes/no (no): "
read ANSWER
if [ x$ANSWER != "xyes" ] ; then
  echo "${nl_}Rerun make and fix your settings.${nl_}"
  exit 1
fi
echo "${nl_}${SD_BORDER}${nl_}"
regenerate_deps
generate_dependency_tree
generate_TARGET_xml
generate_target_book
create_build_scripts "${SUDO}"
clean_configuration
