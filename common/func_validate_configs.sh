# $Id$
# $Author$$Rev$$Date$
#----------------------------#
validate_config()    {       # Are the config values sane (within reason)
#----------------------------#
: <<inline_doc
      Validates the configuration parameters. The global var PROGNAME selects the 
    parameter list.
    
    input vars: none
    externals:  color constants
                PROGNAME (lfs,clfs,hlfs,blfs)
    modifies:   none
    returns:    nothing
    on error:	write text to console and dies
    on success: write text to console and returns
inline_doc

  local svn_tracking='$Id$'
  local -r  lfs_PARAM_LIST="BUILDDIR HPKG TEST TOOLCHAINTEST STRIP VIMLANG PAGE RUNMAKE"
  local -r blfs_PARAM_LIST="BUILDDIR TEST DEPEND"
  local -r hlfs_PARAM_LIST="BUILDDIR HPKG MODEL TEST TOOLCHAINTEST STRIP VIMLANG PAGE GRSECURITY_HOST RUNMAKE TIMEZONE"
  local -r clfs_PARAM_LIST="ARCH BOOTMINIMAL RUNMAKE MKFILE"
  local -r global_PARAM_LIST="BUILDDIR HPKG RUNMAKE TEST TOOLCHAINTEST STRIP PAGE TIMEZONE VIMLANG"

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
