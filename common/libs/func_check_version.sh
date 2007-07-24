# $Id$

check_version() {
: <<inline_doc
      Tests for a minimum version level. Compares to version numbers and forces an
        exit if minimum level not met.
      NOTE: This test will fail on versions containing alpha chars. ie. jpeg 6b

    usage:	check_version "2.6.2" "`uname -r`"         "KERNEL"
		check_version "3.0"   "$BASH_VERSION"      "BASH"
		check_version "3.0"   "`gcc -dumpversion`" "GCC"

    input vars: $1=min acceptable version
    		$2=version to check
		$3=app name
    externals:  --
    modifies:   --
    returns:    nothing
    on error:	write text to console and dies
    on success: write text to console and returns
inline_doc

  declare -i major minor revision change
  declare -i ref_major ref_minor ref_revision ref_change
  declare -r spaceSTR="         "

  ref_version=$1
  tst_version=$2
  TXT=$3

  # This saves us the save/restore hassle of the system IFS value
  local IFS

  write_error_and_die() {
     echo -e "\n\t\t$TXT version -->${tst_version}<-- is too old.
		    This script requires ${ref_version} or greater\n"
   # Ask the user instead of bomb, to make happy that packages which version
   # ouput don't follow our expectations
    echo "If you are sure that you have instaled a proper version of ${BOLD}$TXT${OFF}"
    echo "but jhalfs has failed to detect it, press 'c' and 'ENTER' keys to continue,"
    echo -n "otherwise press 'ENTER' key to stop jhalfs.  "
    read ANSWER
    if [ x$ANSWER != "xc" ] ; then
      echo "${nl_}Please, install a proper $TXT version.${nl_}"
      exit 1
    else
      minor=$ref_minor
      revision=$ref_revision
    fi
  }

  echo -ne "${TXT}${dotSTR:${#TXT}} ${L_arrow}${BOLD}${tst_version}${OFF}${R_arrow}"

#  echo -ne "$TXT:\t${L_arrow}${BOLD}${tst_version}${OFF}${R_arrow}"
  IFS=".-(pa"   # Split up w.x.y.z as well as w.x.y-rc  (catch release candidates)
  set -- $ref_version # set postional parameters to minimum ver values
  ref_major=$1; ref_minor=$2; ref_revision=$3
  #
  set -- $tst_version # Set postional parameters to test version values
  major=$1; minor=$2; revision=$3
  #
  # Compare against minimum acceptable version..
  (( major > ref_major )) && echo " ${spaceSTR:${#tst_version}}${GREEN}OK${OFF}" && return
  (( major < ref_major )) && write_error_and_die
    # major=ref_major
  (( minor < ref_minor )) && write_error_and_die
  (( minor > ref_minor )) && echo " ${spaceSTR:${#tst_version}}${GREEN}OK${OFF}" && return
    # minor=ref_minor
  (( revision >= ref_revision )) && echo " ${spaceSTR:${#tst_version}}${GREEN}OK${OFF}" && return

  # oops.. write error msg and die
  write_error_and_die
}
#  local -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'

#----------------------------#
check_prerequisites() {      #
#----------------------------#

  # LFS/HLFS/CLFS prerequisites
  check_version "2.6.2"   "`uname -r`"          "KERNEL"
  check_version "3.0"     "$BASH_VERSION"       "BASH"
  check_version "3.0.1"   "`gcc -dumpversion`"  "GCC"
  libcVer="`/lib/libc.so.6 | head -n1`"
  libcVer="${libcVer##*version }"
  check_version "2.2.5"   ${libcVer%%,*}        "GLIBC"
  check_version "2.12"    "$(ld --version  | head -n1 | cut -d" " -f4)"        "BINUTILS"
  check_version "1.15"    "$(tar --version | head -n1 | cut -d" " -f4)"        "TAR"
  bzip2Ver="$(bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f8)"
  check_version "1.0.2"   "${bzip2Ver%%,*}"                                    "BZIP2"
  check_version "1.875"   "$(bison --version | head -n1 | cut -d" " -f4)"      "BISON"
  check_version "5.0"     "$(chown --version | head -n1 | cut -d")" -f2)"      "COREUTILS"
  check_version "2.8"     "$(diff --version  | head -n1 | cut -d" " -f4)"      "DIFF"
  check_version "4.1.20"  "$(find --version  | head -n1 | cut -d" " -f4)"      "FIND"
  check_version "3.0"     "$(gawk --version  | head -n1 | cut -d" " -f3)"      "GAWK"
  check_version "2.5"     "$(grep --version  | head -n1 | cut -d" " -f4)"      "GREP"
  check_version "1.2.4"   "$(gzip --version 2>&1 | head -n1 | cut -d" " -f2)"  "GZIP"
  check_version "3.79.1"  "$(make --version  | head -n1 | cut -d " " -f3 | cut -c1-4)"  "MAKE"
  check_version "2.5.4"   "$(patch --version | head -n1 | cut -d" " -f2)"      "PATCH"
  check_version "3.0.2"   "$(sed --version   | head -n1 | cut -d" " -f4)"      "SED"

  # Check for minimum sudo version
  SUDO_LOC="$(whereis -b sudo | cut -d" " -f2)"
  if [ -x $SUDO_LOC ]; then
    sudoVer="$(sudo -V | head -n1 | cut -d" " -f3)"
    check_version "1.6.8"  "${sudoVer}"      "SUDO"
  else
    echo "${nl_}\"${RED}sudo${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    exit 1
  fi

  # Check for minimum libxml2 and libxslt versions
  xsltprocVer=$(xsltproc -V | head -n1 )
  libxmlVer=$(echo $xsltprocVer | cut -d " " -f3)
  libxsltVer=$(echo $xsltprocVer | cut -d " " -f5)

  # Version numbers are packed strings not xx.yy.zz format.
  check_version "2.06.20"  "${libxmlVer:0:1}.${libxmlVer:1:2}.${libxmlVer:3:2}"     "LIBXML2"
  check_version "1.01.14"  "${libxsltVer:0:1}.${libxsltVer:1:2}.${libxsltVer:3:2}"  "LIBXSLT"

  # The next versions checks are required only when BLFS_TOOL is set and
  # this dependencies has not be selected for installation
  if [[ "$BLFS_TOOL" = "y" ]] ; then

    if [[ -z "$DEP_TIDY" ]] ; then
      tidyVer=$(tidy -V | cut -d " " -f9)
      check_version "2004" "${tidyVer}" "TIDY"
    fi

    # Check if the proper DocBook-XML-DTD and DocBook-XSL are correctly installed
XML_FILE="<?xml version='1.0' encoding='ISO-8859-1'?>
<?xml-stylesheet type='text/xsl' href='http://docbook.sourceforge.net/release/xsl/1.69.1/xhtml/docbook.xsl'?>
<!DOCTYPE article PUBLIC '-//OASIS//DTD DocBook XML V4.5//EN'
  'http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd'>
<article>
  <title>Test file</title>
  <sect1>
    <title>Some title</title>
    <para>Some text</para>
  </sect1>
</article>"

    if [[ -z "$DEP_DBXML" ]] ; then
      if `echo $XML_FILE | xmllint -noout -postvalid - 2>/dev/null` ; then
        check_version "4.5" "4.5" "DocBook XML DTD"
      else
        echo "Warning: not found a working DocBook XML DTD 4.5 installation"
        exit 2
      fi
    fi

#     if [[ -z "$DEP_DBXSL" ]] ; then
#       if `echo $XML_FILE | xsltproc --noout - 2>/dev/null` ; then
#         check_version "1.69.1" "1.69.1" "DocBook XSL"
#       else
#         echo "Warning: not found a working DocBook XSL 1.69.1 installation"
#         exit 2
#       fi
#     fi

  fi # end BLFS_TOOL=Y

}