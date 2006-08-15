#!/bin/bash
#
# $Id:$
#

export outFile=aConfig.in	# file for reading and writing to.
export inFile=packages.sorted	# file for reading and writing to.

declare TRACKING_DIR=/var/lib/jhalfs/BLFS

declare PKG_NAME
declare PKG_XML_FILE
declare PKG_DIR
declare SAVE_IFS=${IFS}
declare -a DIR_TREE
declare PREV_DIR1="none"
declare PREV_DIR2="none"
declare MENU_SET1="n"
declare MENU_SET2="n"

declare PKG_VER

get_pkg_ver() {
  local this_script=$1
  
  PKG_VER=$(xmllint --noent ./blfs-xml/book/bookinfo.xml 2>/dev/null | \
            grep -i " ${this_script#*-?-}-version " | cut -d "\"" -f2 )

}

sort packages -b --key=2 --field-separator=/ --output=packages.sorted

> $outFile

#---------------------#
#         MAIN        #
#---------------------#
: <<enddoc
  This script will create a Config.in file from the contents
  of the file <packages>.
  Packages previously installed will not be included.
enddoc

while [ 0 ]
do

#  read -r || break 1
  read || break 1
  if [[ "${REPLY}" = "" ]] || \
     [[ "${REPLY:0:1}" = "=" ]] || \
     [[ "${REPLY:0:1}" = "#" ]]; then
    continue
  fi
  
  set -- $REPLY
  PKG_NAME=$1 
  PKG_XML_FILE=$(basename $2)
  PKG_DIR=$(dirname $2)
  if [ $PKG_DIR = "." ]; then
    if [ -e $TRACKING_DIR/${PKG_NAME} ]; then continue; fi
    PKG_NAME=$(echo ${PKG_NAME} | tr [a-z] [A-Z])
    echo -e "config CONFIG_$PKG_NAME" >> $outFile
    echo -e "\tbool \"$PKG_NAME\"" >> $outFile
    echo -e "\tdefault n" >> $outFile
    continue
  fi

    # Deal with a few unusable chapter names
  case ${PKG_NAME} in
     other-* | others-* ) continue
      ;;
     xorg7-* ) # Deal with sub-elements of Xorg7, mandatory for build. 
               # No need to (even possible?) to build separately
         continue
      ;;
  esac

    # IF this package name-version exists in the tracking dir
    # do not add this package to the list of installable pkgs.
  get_pkg_ver "${PKG_NAME}"
  if [ -e $TRACKING_DIR/${PKG_NAME}-${PKG_VER} ]; then continue; fi
  
  IFS="/"
  DIR_TREE=(${PKG_DIR})
  IFS="$SAVE_IFS"

	# Define a top level menu  
  if [ "$PREV_DIR1" != "${DIR_TREE[1]}" ]; then
    if [ $MENU_SET1 = "y" ]; then 
      # Close out any open secondary menu
      if [ $MENU_SET2 = "y" ]; then 
        echo -e "\tendmenu" >> $outFile
        # Reset 'menu open' flag
        MENU_SET2="n"
      fi
      # Close the current top level menu
      echo -e "endmenu\n" >> $outFile
    fi
    # Open a new top level menu
    echo -e "menu "$(echo ${DIR_TREE[1]:0:1} | tr [a-z] [A-Z])${DIR_TREE[1]:1}"" >> $outFile
    MENU_SET1="y"    
  fi

	# Define a secondary menu
  if [ "$PREV_DIR2" != "${DIR_TREE[2]}" ]; then
      # Close out the previous open menu structure
    if [ $MENU_SET2 = "y" ]; then 
      echo -e "\tendmenu\n"  >> $outFile
    fi
      # Initialize a new 2nd level menu structure. 
    echo -e "\tmenu "$(echo ${DIR_TREE[2]:0:1} | tr [a-z] [A-Z])${DIR_TREE[2]:1}"" >> $outFile
    MENU_SET2="y"    
  fi
(
cat << EOF
	config CONFIG_$PKG_NAME
		bool "$PKG_NAME ${PKG_VER}"
		default n		
EOF
) >> $outFile

  PREV_DIR1=${DIR_TREE[1]}
  PREV_DIR2=${DIR_TREE[2]}
done <"$inFile"

if [ $MENU_SET2 = "y" ]; then echo -e "\tendmenu" >> $outFile; fi
if [ $MENU_SET1 = "y" ]; then echo "endmenu" >> $outFile; fi

(
cat << EOF
config optDependency
	int "Dependency level 1/2/3"
	default 2
	range 1 3
	help
		1 for required
		2 for required and recommended
		3 for required, recommended, and optional


config SUDO
	bool "Build as User"
	default	y
	help
		Select if sudo will be used (you want build as a normal user)
		        otherwise sudo is not needed (you want build as root)

EOF
) >> $outFile




