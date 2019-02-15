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
  declare -r spaceSTR="                   "

  shopt -s extglob	#needed for ${x##*(0)} below

  ref_version=$1
  tst_version=$2
  TXT=$3

  # This saves us the save/restore hassle of the system IFS value
  local IFS

  write_error_and_die() {
     echo -e "\n\t\t$TXT is missing or version -->${tst_version}<-- is too old.
		    This script requires ${ref_version} or greater\n"
   # Ask the user instead of bomb, to make happy that packages which version
   # ouput don't follow our expectations
    echo "If you are sure that you have installed a proper version of ${BOLD}$TXT${OFF}"
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
  IFS=".-(pab"   # Split up w.x.y.z as well as w.x.y-rc  (catch release candidates)
  set -- $ref_version # set positional parameters to minimum ver values
  ref_major=$1; ref_minor=$2; ref_revision=$3
  #
  set -- $tst_version # Set positional parameters to test version values
  # Values beginning with zero are taken as octal, so that for example
  # 2.07.08 gives an error because 08 cannot be octal. The ## stuff supresses
  # leading zero's
  major=${1##*(0)}; minor=${2##*(0)}; revision=${3##*(0)}
  #
  # Compare against minimum acceptable version..
  (( major > ref_major )) &&
    echo " ${spaceSTR:${#tst_version}}${GREEN}OK${OFF} (Min version: ${ref_version})" &&
    return
  (( major < ref_major )) && write_error_and_die
    # major=ref_major
  (( minor < ref_minor )) && write_error_and_die
  (( minor > ref_minor )) &&
    echo " ${spaceSTR:${#tst_version}}${GREEN}OK${OFF} (Min version: ${ref_version})" &&
    return
    # minor=ref_minor
  (( revision >= ref_revision )) &&
    echo " ${spaceSTR:${#tst_version}}${GREEN}OK${OFF} (Min version: ${ref_version})" &&
    return

  # oops.. write error msg and die
  write_error_and_die
}
#  local -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'

#----------------------------#
check_prerequisites() {      #
#----------------------------#

  HOSTREQS=$(find $BOOK -name hostreqs.xml)

  eval $(xsltproc $COMMON_DIR/hostreqs.xsl $HOSTREQS)
  # Avoid translation of version strings
  local LC_ALL=C
  export LC_ALL

  # LFS/HLFS/CLFS prerequisites
  if [ -n "$MIN_Linux_VER" ]; then
    check_version "$MIN_Linux_VER"     "`uname -r`"          "KERNEL"
  fi
  if [ -n "$MIN_Bash_VER" ]; then
    check_version "$MIN_Bash_VER"      "$BASH_VERSION"       "BASH"
  fi
  if [ ! -z $MIN_GCC_VER ]; then
    check_version "$MIN_GCC_VER"     "`gcc -dumpversion`"  "GCC"
    check_version "$MIN_GCC_VER"     "`g++ -dumpversion`"  "G++"
  elif [ ! -z $MIN_Gcc_VER ]; then
    check_version "$MIN_Gcc_VER"     "`gcc -dumpversion`"  "GCC"
  fi
  if [ -n "$MIN_Glibc_VER" ]; then
    check_version "$MIN_Glibc_VER"     "$(ldd --version  | head -n1 | awk '{print $NF}')"   "GLIBC"
  fi
  if [ -n "$MIN_Binutils_VER" ]; then
    check_version "$MIN_Binutils_VER"  "$(ld --version  | head -n1 | awk '{print $NF}')"    "BINUTILS"
  fi
  if [ -n "$MIN_Tar_VER" ]; then
    check_version "$MIN_Tar_VER"       "$(tar --version | head -n1 | cut -d" " -f4)"        "TAR"
  fi
  if [ -n "$MIN_Bzip2_VER" ]; then
  bzip2Ver="$(bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f8)"
    check_version "$MIN_Bzip2_VER"     "${bzip2Ver%%,*}"     "BZIP2"
  fi
  if [ -n "$MIN_Bison_VER" ]; then
    check_version "$MIN_Bison_VER"     "$(bison --version | head -n1 | cut -d" " -f4)"      "BISON"
  fi
  if [ -n "$MIN_Coreutils_VER" ]; then
    check_version "$MIN_Coreutils_VER" "$(chown --version | head -n1 | cut -d" " -f4)"      "COREUTILS"
  fi
  if [ -n "$MIN_Diffutils_VER" ]; then
    check_version "$MIN_Diffutils_VER" "$(diff --version  | head -n1 | cut -d" " -f4)"      "DIFF"
  fi
  if [ -n "$MIN_Findutils_VER" ]; then
    check_version "$MIN_Findutils_VER" "$(find --version  | head -n1 | cut -d" " -f4)"      "FIND"
  fi
  if [ -n "$MIN_Gawk_VER" ]; then
    check_version "$MIN_Gawk_VER"      "$(gawk --version  | head -n1 | awk -F'[ ,]+' '{print $3}')" "GAWK"
  fi
  if [ -n "$MIN_Grep_VER" ]; then
    check_version "$MIN_Grep_VER"      "$(grep --version  | head -n1 | awk '{print $NF}')"  "GREP"
  fi
  if [ -n "$MIN_Gzip_VER" ]; then
    check_version "$MIN_Gzip_VER"      "$(gzip --version 2>&1 | head -n1 | cut -d" " -f2)"  "GZIP"
  fi
  if [ -n "$MIN_M4_VER" ]; then
    check_version "$MIN_M4_VER"        "$(m4 --version 2>&1 | head -n1 | awk '{print $NF}')" "M4"
  fi
  if [ -n "$MIN_Make_VER" ]; then
    check_version "$MIN_Make_VER"      "$(make --version  | head -n1 | cut -d " " -f3 | cut -c1-4)" "MAKE"
  fi
  if [ -n "$MIN_Patch_VER" ]; then
    check_version "$MIN_Patch_VER"     "$(patch --version | head -n1 | sed 's/.*patch //')" "PATCH"
  fi
  if [ -n "$MIN_Perl_VER" ]; then
    check_version "$MIN_Perl_VER"      "$(perl -V:version | cut -f2 -d\')"                  "PERL"
  fi
  if [ -n "$MIN_Sed_VER" ]; then
    check_version "$MIN_Sed_VER"       "$(sed --version   | head -n1 | cut -d" " -f4)"      "SED"
  fi
  if [ -n "$MIN_Texinfo_VER" ]; then
    check_version "$MIN_Texinfo_VER"   "$(makeinfo --version | head -n1 | awk '{ print$NF }')" "TEXINFO"
  fi
  if [ -n "$MIN_Xz_VER" ]; then
    check_version "$MIN_Xz_VER"        "$(xz --version | head -n1 | cut -d" " -f4)"         "XZ"
  fi
  if [ -n "$MIN_Python_VER" ]; then
    check_version "$MIN_Python_VER"    "3.$(python3 -c"import sys; print(sys.version_info.minor,'.',sys.version_info.micro,sep='')")" "PYTHON"
  fi
}

#----------------------------#
check_alfs_tools() {         #
#----------------------------#
: << inline_doc
Those tools are needed for the proper operation of jhalfs
inline_doc

  # Avoid translation of version strings
  local LC_ALL=C
  export LC_ALL

  # Check for minimum sudo version
  SUDO_LOC="$(whereis -b sudo | cut -d" " -f2)"
  if [ -x $SUDO_LOC ]; then
    sudoVer="$(sudo -V | head -n1 | cut -d" " -f3)"
    check_version "1.7.0"  "${sudoVer}"      "SUDO"
  else
    echo "${nl_}\"${RED}sudo${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    exit 1
  fi

  # Check for wget presence (using a dummy version)
  WGET_LOC="$(whereis -b wget | cut -d" " -f2)"
  if [ -x $WGET_LOC ]; then
    wgetVer="$(wget --version | head -n1 | cut -d" " -f3)"
    if echo "$wgetVer" | grep -q '^[[:digit:]]'; then
      check_version "1.0.0"  "${wgetVer}"      "WGET"
    else echo Wget detected, but no version found. Continuing anyway.
    fi
  else
    echo "${nl_}\"${RED}wget${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    exit 1
  fi

  # Before checking libxml2 and libxslt version information, ensure tools
  # needed from those packages are actually available. Avoids a small
  # cosmetic bug of book version information not being retrieved if
  # xmllint is unavailable, especially when on recent non-LFS hosts.

  XMLLINT_LOC="$(whereis -b xmllint | cut -d" " -f2)"
  XSLTPROC_LOC="$(whereis -b xsltproc | cut -d" " -f2)"

  if [ ! -x $XMLLINT_LOC ]; then
    echo "${nl_}\"${RED}xmllint${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    exit 1
  fi

  if [ -x $XSLTPROC_LOC ]; then

    # Check for minimum libxml2 and libxslt versions
    xsltprocVer=$(xsltproc -V | head -n1 )
    libxmlVer=$(echo $xsltprocVer | cut -d " " -f3)
    libxsltVer=$(echo $xsltprocVer | cut -d " " -f5)

    # Version numbers are packed strings not xx.yy.zz format.
    check_version "2.06.20"  "${libxmlVer:0:1}.${libxmlVer:1:2}.${libxmlVer:3:2}"     "LIBXML2"
    check_version "1.01.14"  "${libxsltVer:0:1}.${libxsltVer:1:2}.${libxsltVer:3:2}"  "LIBXSLT"

  else
    echo "${nl_}\"${RED}xsltproc${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    exit 1
  fi
}

#----------------------------#
check_blfs_tools() {         #
#----------------------------#
: << inline_doc
In addition to the tools needed for the LFS part, docbook-xml
is needed for installing the BLFS tools
inline_doc

  # Avoid translation of version strings
  local LC_ALL=C
  export LC_ALL

  # Minimal docbook-xml code for testing
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

  if `echo $XML_FILE | xmllint -nonet -noout -postvalid - 2>/dev/null` ; then
    check_version "4.5" "4.5" "DocBook XML DTD"
  else
    echo "Error: you need the Docbook XML DTD for installing BLFS tools"
    exit 2
  fi
}
