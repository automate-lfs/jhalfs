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

  ref_version=$1
  tst_version=$2
  TXT=$3

  # This saves us the save/restore hassle of the system IFS value
  local IFS

  write_error_and_die() {
     echo -e "\n\t\t$TXT version -->${tst_version}<-- is too old.
		    This script requires ${ref_version} or greater\n"
     exit 1
  }

  echo -ne "${TXT}${dotSTR:${#TXT}}${L_arrow}${BOLD}${tst_version}${OFF}${R_arrow}"

#  echo -ne "$TXT:\t${L_arrow}${BOLD}${tst_version}${OFF}${R_arrow}"
  IFS=".-(p"   # Split up w.x.y.z as well as w.x.y-rc  (catch release candidates)
  set -- $ref_version # set postional parameters to minimum ver values
  ref_major=$1; ref_minor=$2; ref_revision=$3
  #
  set -- $tst_version # Set postional parameters to test version values
  major=$1; minor=$2; revision=$3
  #
  # Compare against minimum acceptable version..
  (( major > ref_major )) && echo " ..${GREEN}OK${OFF}" && return
  (( major < ref_major )) && write_error_and_die
    # major=ref_major
  (( minor < ref_minor )) && write_error_and_die
  (( minor > ref_minor )) && echo " ..${GREEN}OK${OFF}" && return
    # minor=ref_minor
  (( revision >= ref_revision )) && echo " ..${GREEN}OK${OFF}" && return

  # oops.. write error msg and die
  write_error_and_die
}

