# $Id$

declare -r dotSTR=".................."


#----------------------------#
validate_config() {          # Are the config values sane (within reason)
#----------------------------#
: <<inline_doc
      Validates the configuration parameters. The global var PROGNAME selects the
    parameter list.

    input vars: none
    externals:  color constants
                PROGNAME (lfs,clfs,hlfs)
    modifies:   none
    returns:    nothing
    on error:   write text to console and dies
    on success: write text to console and returns
inline_doc

  # First internal variables, then the ones that change the book's flavour, and lastly system configuration variables
  local -r  hlfs_PARAM_LIST="BOOK BUILDDIR SRC_ARCHIVE GETPKG RUNMAKE MODEL       GRSECURITY_HOST                   TEST BOMB_TEST OPTIMIZE REPORT COMPARE RUN_ICA RUN_FARCE ITERATIONS STRIP FSTAB             CONFIG GETKERNEL         PAGE TIMEZONE LANG LC_ALL LUSER LGROUP BLFS_TOOL CUSTOM_TOOLS REBUILD_MAKEFILE"
  local -r  clfs_PARAM_LIST="BOOK BUILDDIR SRC_ARCHIVE GETPKG RUNMAKE METHOD ARCH                 TARGET TARGET32   TEST BOMB_TEST OPTIMIZE REPORT COMPARE RUN_ICA RUN_FARCE ITERATIONS STRIP FSTAB BOOT_CONFIG CONFIG GETKERNEL VIMLANG PAGE TIMEZONE LANG        LUSER LGROUP BLFS_TOOL CUSTOM_TOOLS REBUILD_MAKEFILE"
  local -r clfs2_PARAM_LIST="BOOK BUILDDIR SRC_ARCHIVE GETPKG RUNMAKE        ARCH                 TARGET                                    REPORT                                      STRIP FSTAB             CONFIG GETKERNEL VIMLANG PAGE TIMEZONE LANG        LUSER LGROUP BLFS_TOOL CUSTOM_TOOLS REBUILD_MAKEFILE"
  local -r clfs3_PARAM_LIST="BOOK BUILDDIR SRC_ARCHIVE GETPKG RUNMAKE        ARCH PLATFORM        TARGET MIPS_LEVEL                         REPORT                                            FSTAB             CONFIG GETKERNEL VIMLANG PAGE TIMEZONE LANG        LUSER LGROUP           CUSTOM_TOOLS REBUILD_MAKEFILE"
  local -r   lfs_PARAM_LIST="BOOK BUILDDIR SRC_ARCHIVE GETPKG RUNMAKE                                               TEST BOMB_TEST OPTIMIZE REPORT COMPARE RUN_ICA RUN_FARCE ITERATIONS STRIP FSTAB             CONFIG GETKERNEL VIMLANG PAGE TIMEZONE LANG        LUSER LGROUP BLFS_TOOL CUSTOM_TOOLS REBUILD_MAKEFILE"
  local -r  blfs_PARAM_LIST="BRANCH_ID BLFS_ROOT BLFS_XML TRACKING_DIR"

  local -r blfs_tool_PARAM_LIST="BLFS_BRANCH_ID BLFS_ROOT BLFS_XML TRACKING_DIR DEP_LIBXML DEP_LIBXSLT DEP_TIDY DEP_UNZIP DEP_DBXML DEP_DBXSL DEP_LINKS DEP_SUDO DEP_WGET DEP_SVN DEP_GPM"
  local -r custom_tool_PARAM_LIST="TRACKING_DIR"

  local -r ERROR_MSG_pt1='The variable \"${L_arrow}${config_param}${R_arrow}\" value ${L_arrow}${BOLD}${!config_param}${R_arrow} is invalid,'
  local -r ERROR_MSG_pt2='rerun make and fix your configuration settings${OFF}'
  local -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'

  local PARAM_LIST=
  local config_param
  local validation_str
  local save_param

  write_error_and_die() {
    echo -e "\n${DD_BORDER}"
    echo -e "`eval echo ${ERROR_MSG_pt1}`" >&2
    echo -e "`eval echo ${ERROR_MSG_pt2}`" >&2
    echo -e "${DD_BORDER}\n"
    exit 1
  }

  validate_file() {
     # For parameters ending with a '+' failure causes a warning message only
     echo -n "`eval echo $PARAM_VALS`"
     while test $# -gt 0 ; do
       case $1 in
        # Failures caused program exit
        "-z")  [[   -z "${!config_param}" ]] && echo "${tab_}<-- NO file name given"  && write_error_and_die ;;
        "-e")  [[ ! -e "${!config_param}" ]] && echo "${tab_}<-- file does not exist" && write_error_and_die ;;
        "-s")  [[ ! -s "${!config_param}" ]] && echo "${tab_}<-- file has zero bytes" && write_error_and_die ;;
        "-r")  [[ ! -r "${!config_param}" ]] && echo "${tab_}<-- no read permission " && write_error_and_die ;;
        "-w")  [[ ! -w "${!config_param}" ]] && echo "${tab_}<-- no write permission" && write_error_and_die ;;
        "-x")  [[ ! -x "${!config_param}" ]] && echo "${tab_}<-- file cannot be executed" && write_error_and_die ;;
        # Warning messages only
        "-z+") [[   -z "${!config_param}" ]] && echo && return ;;
       esac
       shift 1
     done
     echo
  }

  validate_dir() {
     # For parameters ending with a '+' failure causes a warning message only
     echo -n "`eval echo $PARAM_VALS`"
     while test $# -gt 0 ; do
       case $1 in
        "-z") [[   -z "${!config_param}" ]] && echo "${tab_}NO directory name given" && write_error_and_die ;;
        "-d") [[ ! -d "${!config_param}" ]] && echo "${tab_}This is NOT a directory" && write_error_and_die ;;
        "-w") if [[ ! -w "${!config_param}" ]]; then
                echo "${nl_}${DD_BORDER}"
                echo "${tab_}${RED}You do not have ${L_arrow}write${R_arrow}${RED} access to the directory${OFF}"
                echo "${tab_}${BOLD}${!config_param}${OFF}"
                echo "${DD_BORDER}${nl_}"
                exit 1
              fi  ;;
        # Warnings only
        "-w+") if [[ ! -w "${!config_param}" ]]; then
                 echo "${nl_}${DD_BORDER}"
                 echo "${tab_}WARNING-- You do not have ${L_arrow}write${R_arrow} access to the directory${OFF}"
                 echo "${tab_}       -- ${BOLD}${!config_param}${OFF}"
                 echo "${DD_BORDER}"
               fi  ;;
        "-z+") [[ -z "${!config_param}" ]] && echo "${tab_}<-- NO directory name given" && return
       esac
       shift 1
     done
     echo
  }

  set +e
  PARAM_GROUP=${PROGNAME}_PARAM_LIST
  for config_param in ${!PARAM_GROUP}; do
    case $config_param in
      # Allways display this, if found in ${PROGNAME}_PARAM_LIST
      GETPKG          | \
      RUNMAKE         | \
      TEST            | \
      OPTIMIZE        | \
      STRIP           | \
      VIMLANG         | \
      MODEL           | \
      METHOD          | \
      ARCH            | \
      PLATFORM        | \
      TARGET          | \
      GRSECURITY_HOST | \
      BLFS_TOOL       | \
      CUSTOM_TOOLS    | \
      TIMEZONE        | \
      PAGE            | \
      REBUILD_MAKEFILE ) echo -e "`eval echo $PARAM_VALS`" ;;

      # Envvars that depend on other settings to be displayed
      GETKERNEL ) if [[ -z "$CONFIG" ]] && [[ -z "$BOOT_CONFIG" ]] ; then
                    [[ "$GETPKG" = "y" ]] && echo -e "`eval echo $PARAM_VALS`"
                  fi ;;
      COMPARE)    [[ ! "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      RUN_ICA)    [[ "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      RUN_FARCE)  [[ "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      ITERATIONS) [[ "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      BOMB_TEST)  [[ ! "$TEST" = "0" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      TARGET32)   [[ -n "${TARGET32}" ]] &&  echo -e "`eval echo $PARAM_VALS`" ;;
      MIPS_LEVEL) [[ "${ARCH}" = "mips" ]] && echo -e "`eval echo $PARAM_VALS`" ;;

      # Envars that requires some validation
      LUSER)      echo -e "`eval echo $PARAM_VALS`"
                  [[ "${!config_param}" = "**EDIT ME**" ]] && write_error_and_die
                  ;;
      LGROUP)     echo -e "`eval echo $PARAM_VALS`"
                  [[ "${!config_param}" = "**EDIT ME**" ]] && write_error_and_die
                  ;;
      REPORT)     echo -e "`eval echo $PARAM_VALS`"
                  if [[ "${!config_param}" = "y" ]]; then
                    if [[ `type -p bc` ]]; then
                      continue
                    else
                      echo -e "  ${BOLD}The bc binary was not found${OFF}"
                      echo -e "  The SBU and disk usage report creation will be skiped"
                      REPORT=n
                      continue
                    fi
                  fi ;;

        # BOOK validation. Very ugly, need be fixed
      BOOK)        if [[ "${WORKING_COPY}" = "y" ]] ; then
                     validate_dir -z -d
                   else
                     echo -e "`eval echo $PARAM_VALS`"
                   fi ;;

        # Validate directories, testable states:
        #  fatal   -z -d -w,
        #  warning -z+   -w+
      SRC_ARCHIVE) [[ "$GETPKG" = "y" ]] && validate_dir -z+ -d -w+ ;;
        # The build directory/partition MUST exist and be writable by the user
      BUILDDIR)   validate_dir -z -d -w
                  [[ "xx x/x" =~ x${!config_param}x ]] && write_error_and_die ;;

        # Validate files, testable states:
        #  fatal   -z -e -s -w -x -r,
        #  warning -z+
      FSTAB)       validate_file -z+ -e -s ;;
      CONFIG)      validate_file -z+ -e -s ;;
      BOOT_CONFIG) [[ "${METHOD}" = "boot" ]] && validate_file -z -e -s ;;

        # Treatment of 'special' parameters
      LANG | \
      LC_ALL)  # See it the locale values exist on this machine
               echo -n "`eval echo $PARAM_VALS`"
               [[ -z "${!config_param}" ]] &&
                 echo " -- Variable $config_param cannot be empty!" &&
                 write_error_and_die
               echo
               ;;

      # BLFS params.
      BRANCH_ID | BLFS_ROOT | BLFS_XML )  echo "`eval echo $PARAM_VALS`" ;;
      TRACKING_DIR ) validate_dir -z -d -w ;;

    esac
  done

  if [[ "${BLFS_TOOL}" = "y" ]] ; then
    echo "${nl_}    ${BLUE}blfs-tool settings${OFF}"
    for config_param in ${blfs_tool_PARAM_LIST}; do
      echo -e "`eval echo $PARAM_VALS`"
    done
  fi

  if [[ "${CUSTOM_TOOLS}" = "y" ]] && [[ "${BLFS_TOOL}" = "n" ]]  ; then
    for config_param in ${custom_tool_PARAM_LIST}; do
      echo -e "`eval echo $PARAM_VALS`"
    done
  fi

  set -e
  echo "${nl_}***${BOLD}${GREEN} ${PARAM_GROUP%%_*T} config parameters look good${OFF} ***${nl_}"
}
