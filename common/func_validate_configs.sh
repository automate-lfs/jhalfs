
# $Id$

#----------------------------#
validate_config()    {       # Are the config values sane (within reason)
#----------------------------#
: <<inline_doc
      Validates the configuration parameters. The global var PROGNAME selects the
    parameter list.

    input vars: $1 0/1 0=quiet, 1=verbose output
    externals:  color constants
                PROGNAME (lfs,clfs,hlfs,blfs)
    modifies:   none
    returns:    nothing
    on error:	write text to console and dies
    on success: write text to console and returns
inline_doc

  local -r  lfs_PARAM_LIST="VIMLANG"
  local -r blfs_PARAM_LIST="TEST DEPEND"
  local -r hlfs_PARAM_LIST="MODEL GRSECURITY_HOST"
  local -r clfs_PARAM_LIST="ARCH METHOD VIMLANG"
  local -r global_PARAM_LIST="BUILDDIR HPKG RUNMAKE TEST STRIP PAGE TIMEZONE"

  local -r ERROR_MSG='The variable \"${L_arrow}${config_param}${R_arrow}\" value ${L_arrow}${BOLD}${!config_param}${R_arrow} is invalid, ${nl_}check the config file ${BOLD}${GREEN}\<$PROGNAME.conf\>${OFF}'
  local -r PARAM_VALS='${config_param}: ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'

  local    PARAM_LIST=

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
        TEST)      validation_str="x0x x1x x2x x3x"  ;;
        STRIP)     validation_str="x0x x1x"  ;;
        VIMLANG)   validation_str="x0x x1x"  ;;
        DEPEND)    validation_str="x0x x1x x2x" ;;
        MODEL)     validation_str="xglibcx xuclibcx" ;;
        PAGE)      validation_str="xletterx xA4x"  ;;
        ARCH)      validation_str="xx86x xx86_64x xx86_64-64x xsparcx xsparcv8x xsparc64x xsparc64-64x xmipsx xmips64x xmips64-64x xppcx xalphax" ;;
        GRSECURITY_HOST)  validation_str="x0x x1x"  ;;
        METHOD)      validation_str="xchrootx xbootx";;
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


      # No further tests needed on globals
    if [[ "$PARAM_GROUP" = "global_PARAM_LIST" ]]; then

      for config_param in LC_ALL LANG; do
        [[ $1 = "1" ]] && echo "`eval echo $PARAM_VALS`"
        [[ -z "${!config_param}" ]] && continue
          # See it the locale values exist on this machine
        [[ "`locale -a | grep -c ${!config_param}`" > 0 ]] && continue

          # If you make it this far then there is a problem
        write_error_and_die
      done

      for config_param in KEYMAP; do
        [[ $1 = "1" ]] && echo "`eval echo $PARAM_VALS`"
        [[ "${!config_param}" = "none" ]] && continue
        [[ -e "/usr/share/kbd/keymaps/${!config_param}" ]] && [[ -s "/usr/share/kbd/keymaps/${!config_param}" ]] && continue

          # If you make it this far then there is a problem
        write_error_and_die
      done

      # Check out the global param SRC_ARCHIVE
      config_param=SRC_ARCHIVE
      [[ $1 = "1" ]] && echo -n "`eval echo $PARAM_VALS`"
      if [ ! -z ${SRC_ARCHIVE} ]; then
        if [ ! -d ${SRC_ARCHIVE} ]; then
          echo "   -- is NOT a directory"
	  write_error_and_die
        fi
        if [ ! -w ${SRC_ARCHIVE} ]; then
          echo -n "${nl_} [${BOLD}${YELLOW}WARN$OFF] You do not have <write> access to this directory, ${nl_}${tab_}downloaded files can not be saved in this archive"
        fi
      fi
      echo  "${nl_}   ${BOLD}${GREEN}global parameters are valid${OFF}${nl_}"
      continue
    fi


    for config_param in FSTAB BOOK CONFIG; do
      [[ $1 = "1" ]] && echo "`eval echo $PARAM_VALS`"
      if [[ $config_param = BOOK ]]; then
         [[ ! "${WC}" = 1 ]] && continue
      fi
      [[ -z "${!config_param}" ]] && continue
      [[ -e "${!config_param}" ]] && [[ -s "${!config_param}" ]] && continue

      # If you make it this far then there is a problem
      write_error_and_die
    done

    [[ "$PROGNAME" = "clfs" ]] &&
    for config_param in BOOT_CONFIG; do
      if [[ "${METHOD}" = "boot" ]]; then
        [[ $1 = "1" ]] && echo "`eval echo $PARAM_VALS`"
          # There must be a config file when the build method is 'boot'
        [[ -e "${!config_param}" ]] && [[ -s "${!config_param}" ]] && continue
          # If you make it this far then there is a problem
        write_error_and_die
      fi
    done
    echo "   ${BOLD}${GREEN}${PARAM_GROUP%%_*T} specific parameters are valid${OFF}"
  done

  set -e
  echo "$tab_***${BOLD}${GREEN}Config parameters look good${OFF}***"
}
