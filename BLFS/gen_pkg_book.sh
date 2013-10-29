#!/bin/bash
#
# $Id$
#
#  Read and parse the configuration parameters..
#
set -e

TOPDIR=$1
if test -z "$TOPDIR"; then
  TOPDIR=$(pwd)
fi
BLFS_FULL=$2
if test -z "$BLFS_FULL"; then
  BLFS_FULL=${TOPDIR}/blfs-xml/tmp/blfs-full.xml
fi
declare -r ConfigFile="${TOPDIR}/configuration"
declare DepDir="${TOPDIR}/dependencies"
declare LibDir="${TOPDIR}/libs"
declare PackFile="${TOPDIR}/packages.xml"
declare BookXml="${TOPDIR}/book.xml"
declare MakeBook="${TOPDIR}/xsl/make_book.xsl"
declare MakeScripts="${TOPDIR}/xsl/scripts.xsl"
declare BookHtml="${TOPDIR}/book-html"
declare BLFS_XML="${TOPDIR}/blfs-xml"
declare -a TARGET
declare DEP_LEVEL
declare SUDO

#--------------------------#
parse_configuration() {    #
#--------------------------#
  local	-i cntr=0
  local	-a optTARGET

  while read; do

    # Garbage collection
    case ${REPLY} in
      \#* | '') continue ;;
    esac

    case "${REPLY}" in
      # Create global variables for these parameters.
      optDependency=* | \
      MAIL_SERVER=*   | \
      SUDO=*  )  eval ${REPLY} # Define/set a global variable..
                      continue ;;
    esac

    if [[ "${REPLY}" =~ ^CONFIG_ ]]; then
      echo "$REPLY"
      optTARGET[$((cntr++))]=$( echo $REPLY | sed -e 's@CONFIG_@@' -e 's@=y@@' )
    fi
  done < $ConfigFile

  if (( $cntr == 0 )); then
    echo -e "\n>>> NO TARGET SELECTED.. application terminated"
    echo -e "    Run <make> again and select (a) package(s) to build\n"
    exit 0
  fi
  TARGET=(${optTARGET[*]})
  DEP_LEVEL=$optDependency
  SUDO=${SUDO:-n}
}

#--------------------------#
validate_configuration() { #
#--------------------------#
  local -r dotSTR=".................."
  local -r PARAM_LIST="DEP_LEVEL SUDO MAIL_SERVER"
  local -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'
  local config_param
  local -i index

  for config_param in ${PARAM_LIST}; do
    echo -e "`eval echo $PARAM_VALS`"
  done
  for (( index=0 ; index < ${#TARGET[*]} ; index ++ )); do
    echo -e "TARGET${index}${dotSTR:6} ${L_arrow}${BOLD}${TARGET[${index}]}${OFF}${R_arrow}"
  done
}

#
# Generates the root of the dependency tree
#
#--------------------------#
generate_deps() {        #
#--------------------------#

  local -i index
  local DepDir=$1
  rm -f $DepDir/*.dep
  echo 1 > $DepDir/root.dep
  for (( index=0 ; index < ${#TARGET[*]} ; index ++ )); do
    echo ${TARGET[${index}]} >> $DepDir/root.dep
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

tail -n 15 ${ConfigFile} > ${ConfigFile}.tmp
mv ${ConfigFile}.tmp ${ConfigFile}

}

#---------------------
# Constants
source ${LibDir}/constants.inc
[[ $? > 0 ]] && echo -e "\n\tERROR: constants.inc did not load..\n" && exit

#---------------------
# Dependencies module
source ${LibDir}/func_dependencies
[[ $? > 0 ]] && echo -e "\n\tERROR: func_dependencies did not load..\n" && exit

#------- MAIN --------
if [[ ! -f ${PackFile} ]] ; then
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

rm -rf $DepDir
mkdir $DepDir
generate_deps $DepDir
pushd $DepDir > /dev/null
set +e
generate_dependency_tree root.dep
echo
LIST="$(tree_browse root.dep)"
set -e
popd > /dev/null
rm -f ${BookXml}
echo Making XML book
xsltproc --stringparam list "$LIST" \
         -o ${BookXml} \
         ${MakeBook} \
         $BLFS_FULL
echo "making HTML book (may take some time...)"
xsltproc -o ${BookHtml}/ \
         -stringparam chunk.quietly 1 \
         ${BLFS_XML}/stylesheets/blfs-chunked.xsl \
         ${BookXml}
if [ ! -d ${BookHtml}/stylesheets ]
  then mkdir -p ${BookHtml}/stylesheets
  cp ${BLFS_XML}/stylesheets/lfs-xsl/*.css ${BookHtml}/stylesheets
fi
if [ ! -d ${BookHtml}/images ]
  then mkdir -p ${BookHtml}/images
  cp ${BLFS_XML}/images/*.png ${BookHtml}/images
fi
for ht in ${BookHtml}/*.html
  do sed -i 's@../stylesheets@stylesheets@' $ht
  sed -i 's@../images@images@' $ht
done
echo -en "\n\tGenerating the build scripts ...\n"
rm -rf scripts
xsltproc --xinclude --nonet \
         --stringparam sudo $SUDO \
         -o ./scripts/ ${MakeScripts} \
         ${BookXml}
# Make the scripts executable.
chmod -R +x scripts
echo -e "done\n"

#clean_configuration
