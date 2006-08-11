# $Id$

declare -r dotSTR=".................."

#----------------------------#
validate_target() {          #
#----------------------------#
  local -r ERROR_MSG_pt1='The variable \"${L_arrow}TARGET${R_arrow}\" value ${L_arrow}${BOLD}${TARGET}${R_arrow} is invalid for the ${L_arrow}${BOLD}${ARCH}${R_arrow} architecture'
  local -r ERROR_MSG_pt2='  check the config file ${BOLD}${GREEN}\<$(echo $PROGNAME | tr [a-z] [A-Z])/config\> or \<common/config\>${OFF}'

  local -r PARAM_VALS='TARGET${dotSTR:6} ${L_arrow}${BOLD}${TARGET}${OFF}${R_arrow}'
  local -r PARAM_VALS2='TARGET32${dotSTR:8} ${L_arrow}${BOLD}${TARGET32}${OFF}${R_arrow}'

  write_error_and_die() {
    echo -e "\n${DD_BORDER}"
    echo -e "`eval echo ${ERROR_MSG_pt1}`" >&2
    echo -e "`eval echo ${ERROR_MSG_pt2}`" >&2
    echo -e "${DD_BORDER}\n"
    exit 1
  }

 if [[ ! "${TARGET32}" = "" ]]; then
    echo -e "`eval echo $PARAM_VALS2`"
 fi
 echo -e "`eval echo $PARAM_VALS`"

 case "${ARCH}" in
   "x86")        [[ "${TARGET}" = "i486-pc-linux-gnu" ]] && return
                 [[ "${TARGET}" = "i586-pc-linux-gnu" ]] && return
                 [[ "${TARGET}" = "i686-pc-linux-gnu" ]] && return
    ;;
   "ppc")        [[ "${TARGET}" = "powerpc-unknown-linux-gnu" ]] && return
    ;;
   "mips")       [[ "${TARGET}" = "mipsel-unknown-linux-gnu" ]] && return
                 [[ "${TARGET}" = "mips-unknown-linux-gnu"   ]] && return
    ;;
   "sparc")      [[ "${TARGET}" = "sparcv9-unknown-linux-gnu" ]] && return
    ;;
   "x86_64-64")  [[ "${TARGET}" = "x86_64-unknown-linux-gnu" ]] && return
    ;;
   "mips64-64")  [[ "${TARGET}" = "mips64el-unknown-linux-gnu" ]] && return
                 [[ "${TARGET}" = "mips64-unknown-linux-gnu"   ]] && return
    ;;
   "sparc64-64") [[ "${TARGET}" = "sparc64-unknown-linux-gnu" ]] && return
    ;;
   "alpha")      [[ "${TARGET}" = "alpha-unknown-linux-gnu" ]] && return
    ;;
   "x86_64")     [[ "${TARGET}"   = "x86_64-unknown-linux-gnu" ]] &&
                 [[ "${TARGET32}" = "i686-pc-linux-gnu" ]] && return
    ;;
   "mips64")     [[ "${TARGET}"   = "mips64el-unknown-linux-gnu" ]] &&
                 [[ "${TARGET32}" = "mipsel-unknown-linux-gnu" ]] && return

                 [[ "${TARGET}"   = "mips64-unknown-linux-gnu" ]] &&
                 [[ "${TARGET32}" = "mips-unknown-linux-gnu" ]] && return
    ;;
   "sparc64")    [[ "${TARGET}"   = "sparc64-unknown-linux-gnu" ]] &&
                 [[ "${TARGET32}" = "sparc-unknown-linux-gnu" ]] && return
    ;;
   "ppc64")      [[ "${TARGET}"   = "powerpc64-unknown-linux-gnu" ]] &&
                 [[ "${TARGET32}" = "powerpc-unknown-linux-gnu"   ]] && return
    ;;
   "arm")        [[ "${TARGET}"   = "arm-unknown-linux-gnu" ]] && return
    ;;
   *)  write_error_and_die
   ;;
 esac

   # If you end up here then there was an error SO...
   write_error_and_die
}


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
  local -r  hlfs_PARAM_LIST="BOOK BUILDDIR SRC_ARCHIVE GETPKG RUNMAKE MODEL GRSECURITY_HOST TEST BOMB_TEST OPTIMIZE REPORT COMPARE RUN_ICA RUN_FARCE ITERATIONS STRIP FSTAB             CONFIG GETKERNEL KEYMAP         PAGE TIMEZONE LANG LC_ALL LUSER LGROUP"
  local -r  clfs_PARAM_LIST="BOOK BUILDDIR SRC_ARCHIVE GETPKG RUNMAKE METHOD  ARCH  TARGET  TEST BOMB_TEST OPTIMIZE REPORT COMPARE RUN_ICA RUN_FARCE ITERATIONS STRIP FSTAB BOOT_CONFIG CONFIG GETKERNEL KEYMAP VIMLANG PAGE TIMEZONE LANG        LUSER LGROUP"
  local -r clfs2_PARAM_LIST="BOOK BUILDDIR SRC_ARCHIVE GETPKG RUNMAKE         ARCH  TARGET                 OPTIMIZE REPORT                                      STRIP FSTAB             CONFIG GETKERNEL KEYMAP VIMLANG PAGE TIMEZONE LANG        LUSER LGROUP"
  local -r   lfs_PARAM_LIST="BOOK BUILDDIR SRC_ARCHIVE GETPKG RUNMAKE                       TEST BOMB_TEST OPTIMIZE REPORT COMPARE RUN_ICA RUN_FARCE ITERATIONS STRIP FSTAB             CONFIG GETKERNEL        VIMLANG PAGE TIMEZONE LANG        LUSER LGROUP"

  local -r ERROR_MSG_pt1='The variable \"${L_arrow}${config_param}${R_arrow}\" value ${L_arrow}${BOLD}${!config_param}${R_arrow} is invalid,'
  local -r ERROR_MSG_pt2=' check the config file ${BOLD}${GREEN}\<$(echo $PROGNAME | tr [a-z] [A-Z])/config\> or \<common/config\>${OFF}'
  local -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'

  local    PARAM_LIST=
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

  validate_against_str() {
     # This is the 'regexp' test available in bash-3.0..
     # using it as a poor man's test for substring
     echo -e "`eval echo $PARAM_VALS`"
     if [[ ! "$1" =~ "x${!config_param}x" ]] ; then
       # parameter value entered is no good
       write_error_and_die
     fi
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
    # This is a tricky little piece of code.. executes a cmd string.
    case $config_param in
      TIMEZONE)   echo -e "`eval echo $PARAM_VALS`" ;;

      # Validate general parameters..
      GETPKG)     validate_against_str "x0x x1x" ;;
      GETKERNEL ) if [[ -z "$CONFIG" ]] && [[ -z "$BOOT_CONFIG" ]] ; then
                    [[ "$GETPKG" = "1" ]] && validate_against_str "x0x x1x"
                  fi ;;
      RUNMAKE)    validate_against_str "x0x x1x" ;;
      REPORT)     validate_against_str "x0x x1x"
                  if [[ "${!config_param}" = "1" ]]; then
                    if [[ `type -p bc` ]]; then
                      continue
                    else
                      echo -e "  ${BOLD}The bc binary was not found${OFF}"
                      echo -e "  The SBU and disk usage report creation will be skiped"
                      REPORT=0
                      continue
                    fi
                  fi ;;
      COMPARE)    if [[ ! "$COMPARE" = "1" ]]; then
                    validate_against_str "x0x x1x"
                  else
                    if [[ ! "${RUN_ICA}" = "1" ]] && [[ ! "${RUN_FARCE}" = "1" ]]; then
                       echo  "${nl_}${DD_BORDER}"
                       echo  "You have elected to analyse your build but have failed to select a tool." >&2
                       echo  "Edit /common/config and set ${L_arrow}${BOLD}RUN_ICA${R_arrow} and/or ${L_arrow}${BOLD}RUN_FARCE${R_arrow} to the required values" >&2
                       echo  "${DD_BORDER}${nl_}"
                       exit 1
                    fi
                  fi ;;
      RUN_ICA)    [[ "$COMPARE" = "1" ]] && validate_against_str "x0x x1x" ;;
      RUN_FARCE)  [[ "$COMPARE" = "1" ]] && validate_against_str "x0x x1x" ;;
      ITERATIONS) [[ "$COMPARE" = "1" ]] && validate_against_str "x2x x3x x4x x5x" ;;
      TEST)       validate_against_str "x0x x1x x2x x3x" ;;
      BOMB_TEST)  [[ ! "$TEST" = "0" ]] && validate_against_str "x0x x1x" ;;
      OPTIMIZE)   validate_against_str "x0x x1x x2x" ;;
      STRIP)      validate_against_str "x0x x1x" ;;
      VIMLANG)    validate_against_str "x0x x1x" ;;
      MODEL)      validate_against_str "xglibcx xuclibcx" ;;
      PAGE)       validate_against_str "xletterx xA4x" ;;
      METHOD)     validate_against_str "xchrootx xbootx" ;;
      ARCH)       validate_against_str "xx86x xx86_64x xx86_64-64x xsparcx xsparc64x xsparc64-64x xmipsx xmips64x xmips64-64x xppcx xppc64x xalphax xarmx" ;;
      TARGET)     validate_target ;;
      LUSER)      echo -e "`eval echo $PARAM_VALS`"
                  [[ "${!config_param}" = "**EDIT ME**" ]] && write_error_and_die
		  ;;
      LGROUP)     echo -e "`eval echo $PARAM_VALS`"
                  [[ "${!config_param}" = "**EDIT ME**" ]] && write_error_and_die
                  ;;
      GRSECURITY_HOST)  validate_against_str "x0x x1x" ;;

      # BOOK validation. Very ugly, need be fixed
      BOOK)        if [[ "${WC}" = "1" ]] ; then
                     validate_dir -z -d
                   else
                     validate_against_str "x${PROGNAME}-${LFSVRS}x"
                   fi ;;

      # Validate directories, testable states:
      #  fatal   -z -d -w,
      #  warning -z+   -w+
      SRC_ARCHIVE) [[ "$GETPKG" = "1" ]] && validate_dir -z+ -d -w+ ;;
      BUILDDIR)   # The build directory/partition MUST exist and be writable by the user
                  validate_dir -z -d -w
                  [[ "xx x/x" =~ "x${!config_param}x" ]] &&
                       write_error_and_die
                  ;;

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
      KEYMAP)  echo "`eval echo $PARAM_VALS`"
               save_param=${KEYMAP}
               [[ ! "${!config_param}" = "none" ]] &&
                  KEYMAP="/usr/share/kbd/keymaps/${KEYMAP}" &&
                  validate_file -z -e -s
               KEYMAP=${save_param}
               ;;
    esac
  done
  set -e
  echo "${nl_}***${BOLD}${GREEN} ${PARAM_GROUP%%_*T} config parameters look good${OFF} ***${nl_}"
}
