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
                PROGNAME (lfs,hlfs,clfs,clfs2,clfs3,blfs)
    modifies:   none
    returns:    nothing
    on error:   write text to console and dies
    on success: write text to console and returns
inline_doc

  # Common settings by Config.in sections and books family
  local -r     BOOK_common="BOOK CUSTOM_TOOLS"
  local -r      BOOK_clfsX="ARCH TARGET"
  local -r  GENERAL_common="LUSER LGROUP LHOME BUILDDIR CLEAN GETPKG SRC_ARCHIVE \
                            SERVER RETRYSRCDOWNLOAD RETRYDOWNLOADCNT DOWNLOADTIMEOUT \
                            GETKERNEL RUNMAKE"
  local -r    BUILD_chroot="TEST BOMB_TEST STRIP"
  local -r    BUILD_common="FSTAB CONFIG TIMEZONE PAGE LANG INSTALL_LOG"
  local -r ADVANCED_chroot="COMPARE RUN_ICA RUN_FARCE ITERATIONS OPTIMIZE"
  local -r ADVANCED_common="REPORT REBUILD_MAKEFILE"

  # BOOK Settings by book
  local -r   LFS_book="$BOOK_common BLFS_TOOL"
  #local -r HLFS_added="SET_SSP SET_ASLR SET_PAX SET_HARDENED_TMP SET_WARNINGS \
  #                     SET_MISC SET_BLOWFISH"
  local -r HLFS_added=""
  local -r  HLFS_book="$BOOK_common BLFS_TOOL MODEL KERNEL GRSECURITY_HOST $HLFS_added"
  local -r  CLFS_book="$BOOK_common BLFS_TOOL METHOD $BOOK_clfsX TARGET32 BOOT_CONFIG"
  local -r CLFS2_book="$BOOK_common BLFS_TOOL        $BOOK_clfsX"
  local -r CLFS3_book="$BOOK_common                  $BOOK_clfsX PLATFORM MIPS_LEVEL"

  # Build Settings by book
  local -r   LFS_build="$BUILD_chroot VIMLANG $BUILD_common"
  local -r  HLFS_build="$BUILD_chroot         $BUILD_common"
  local -r  CLFS_build="$BUILD_chroot VIMLANG $BUILD_common"
  local -r CLFS2_build="STRIP         VIMLANG $BUILD_common"
  local -r CLFS3_build="                      $BUILD_common"

  # Full list of books settings
  local -r   lfs_PARAM_LIST="$LFS_book   $GENERAL_common $LFS_build   $ADVANCED_chroot $ADVANCED_common"
  local -r  hlfs_PARAM_LIST="$HLFS_book  $GENERAL_common $HLFS_build  $ADVANCED_chroot $ADVANCED_common"
  local -r  clfs_PARAM_LIST="$CLFS_book  $GENERAL_common $CLFS_build  $ADVANCED_chroot $ADVANCED_common"
  local -r clfs2_PARAM_LIST="$CLFS2_book $GENERAL_common $CLFS2_build                  $ADVANCED_common"
  local -r clfs3_PARAM_LIST="$CLFS3_book $GENERAL_common $CLFS3_build                  $ADVANCED_common"
  local -r  blfs_PARAM_LIST="BRANCH_ID BLFS_ROOT BLFS_XML TRACKING_DIR"

  # Additional variables (add DEP_DBXSL when required again)
  local -r blfs_tool_PARAM_LIST="BLFS_BRANCH_ID BLFS_ROOT BLFS_XML TRACKING_DIR \
                                 DEP_LIBXML DEP_LIBXSLT DEP_TIDY DEP_UNZIP \
                                 DEP_DBXML DEP_LYNX DEP_SUDO DEP_WGET \
                                 DEP_SVN DEP_GPM"
  local -r custom_tool_PARAM_LIST="TRACKING_DIR"

  # Internal variables
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
      # Envvars that depend on other settings to be displayed
      GETKERNEL ) if [[ -z "$CONFIG" ]] && [[ -z "$BOOT_CONFIG" ]] ; then
                    [[ "$GETPKG" = "y" ]] && echo -e "`eval echo $PARAM_VALS`"
                  fi ;;
      COMPARE)          [[ ! "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      RUN_ICA)          [[ "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      RUN_FARCE)        [[ "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      ITERATIONS)       [[ "$COMPARE" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      BOMB_TEST)        [[ ! "$TEST" = "0" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      TARGET32)         [[ -n "${TARGET32}" ]] &&  echo -e "`eval echo $PARAM_VALS`" ;;
      MIPS_LEVEL)       [[ "${ARCH}" = "mips" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      SERVER)           [[ "$GETPKG" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      RETRYSRCDOWNLOAD) [[ "$GETPKG" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      RETRYDOWNLOADCNT) [[ "$GETPKG" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;
      DOWNLOADTIMEOUT)  [[ "$GETPKG" = "y" ]] && echo -e "`eval echo $PARAM_VALS`" ;;

      # Envars that requires some validation
      LUSER)      echo -e "`eval echo $PARAM_VALS`"
                  [[ "${!config_param}" = "**EDIT ME**" ]] && write_error_and_die
                  ;;
      LGROUP)     echo -e "`eval echo $PARAM_VALS`"
                  [[ "${!config_param}" = "**EDIT ME**" ]] && write_error_and_die
                  ;;
        # BOOK validation. Very ugly, need be fixed
      BOOK)        if [[ "${WORKING_COPY}" = "y" ]] ; then
                     validate_dir -z -d
                   else
                     echo -e "`eval echo $PARAM_VALS`"
                   fi
                  ;;
        # Validate directories, testable states:
        #  fatal   -z -d -w,
        #  warning -z+   -w+
      SRC_ARCHIVE) [[ "$GETPKG" = "y" ]] && validate_dir -z+ -d -w+ ;;
        # The build directory/partition MUST exist and be writable by the user
      BUILDDIR)   validate_dir -z -d -w
                  [[ "xx x/x" =~ x${!config_param}x ]] && write_error_and_die ;;
      LHOME)      validate_dir -z -d ;;

        # Validate files, testable states:
        #  fatal   -z -e -s -w -x -r,
        #  warning -z+
      FSTAB)       validate_file -z+ -e -s ;;
      CONFIG)      validate_file -z+ -e -s ;;
      BOOT_CONFIG) [[ "${METHOD}" = "boot" ]] && validate_file -z -e -s ;;

        # Treatment of LANG parameter
      LANG )  # See it the locale value has been set
               echo -n "`eval echo $PARAM_VALS`"
               [[ -z "${!config_param}" ]] &&
                 echo " -- Variable $config_param cannot be empty!" &&
                 write_error_and_die
               echo
               ;;

      # BLFS params.
      BRANCH_ID | BLFS_ROOT | BLFS_XML )  echo "`eval echo $PARAM_VALS`" ;;
      TRACKING_DIR ) validate_dir -z -d -w ;;

      # Display non-validated envars found in ${PROGNAME}_PARAM_LIST
      * ) echo -e "`eval echo $PARAM_VALS`" ;;

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
