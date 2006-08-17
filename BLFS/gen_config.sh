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
    # These are the META packages. for gnome and kde (soon ALSA and Xorg7)
  if [ $PKG_DIR = "." ]; then
    SET_COMMENT=y
      # Do not include previously installed packages....
    if [ -e $TRACKING_DIR/${PKG_NAME} ]; then continue; fi
    
    META_PKG=$(echo ${PKG_NAME} | tr [a-z] [A-Z])
    echo -e "config CONFIG_$META_PKG" >> $outFile
    echo -e "\tbool \"$META_PKG\"" >> $outFile
    echo -e "\tdefault n" >> $outFile

    echo -e "menu \"$(echo ${PKG_NAME} | tr [a-z] [A-Z]) components\"" >> $outFile
    echo -e "\tdepends\tCONFIG_$META_PKG\"" >> $outFile
       # Include the dependency data for this meta package
       while [ 0 ]; do
         read || break 1
	 PKG_NAME=${REPLY}
	 get_pkg_ver "${PKG_NAME}"
(
cat << EOF
	config	DEP_${META_PKG}_${PKG_NAME}
		bool	"$PKG_NAME ${PKG_VER}"
		default	y

EOF
) >> $outFile	 
       done <./libs/${PKG_NAME}.dep
     echo -e "endmenu" >> $outFile
    continue
  fi
  [[ "${SET_COMMENT}" = "y" ]] && echo "comment \"\"" >>$outFile; unset SET_COMMENT 
  
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
    [[ "${DIR_TREE[1]}" = "kde" ]] && continue
    [[ "${DIR_TREE[1]}" = "gnome" ]] && continue
    
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

comment	""

menu	"Default packages for resolving dependencies"

choice
	prompt	"Default print server"
	config	PS_cups
		bool	"cups"
	config	PS_LPRng
		bool	"LPRng"
endchoice
config	PRINT_SERVER
	string
	default	cups	if PS_cups
	default	LPRng	if PS_LPRng	

choice
	prompt	"Mail server"
	config	MS_sendmail
		bool	"sendmail'
	config	MS_postfix
		bool	"postfix"
	config	MS_exim"
		bool	"exim"
endchoice
config	MAIL_SERVER
	string
	default	sendmail	if MS_sendmail
	default	postfix		if MS_postfix
	default	exim		if MS_exim

choice
	prompt	"Postscript package"
	config	GS_espgs
		bool	"espgs"
	config	GS_ghostscript
		bool	"ghostscript"
endchoice
config	GHOSTSCRIPT
	string
	default	espgs       if GS_espgs
	default ghostscript if GS_ghostscript

choice
	prompt	"Kerberos 5"
	config	KER_mitkrb
		bool	"mitkrb"
	config	KER_heimdal
		bool	"heimdal"	
endchoice
config	KBR5
	string
	default	heimdal	if KER_heimdal
	default mitkrb	if KER_mitkrb

choice
	prompt	"Window package
	config	WIN_xorg7
	bool	"Xorg7"
	config	WIN_xorg
	bool	"Xorg"
	config	WIN_xfree86
	bool	"xfree86"
endchoice	
config	X11
	string
	default	xorg7	if WIN_xorg7
	default	xorg	if WIN_xorg
	default xfree86	if WIN_xfree86
endmenu

choice	
	prompt	"Dependency level"
	default DEPLVL_2
	
	config	DEPLVL_1
	bool	"Required dependencies only"
	
	config	DEPLVL_2
	bool	"Required and recommended dependencies"
	
	config	DEPLVL_3
	bool	"Required, recommended and optional dependencies"
	
endchoice
config	optDependency
	int
	default	1	if DEPLVL_1
	default	2	if DEPLVL_2
	default	3	if DEPLVL_3
	
	
config	SUDO
	bool "Build as User"
	default	y
	help
		Select if sudo will be used (you want build as a normal user)
		        otherwise sudo is not needed (you want build as root)

EOF
) >> $outFile



