#!/bin/sh
# $Id$

###################################
###          FUNCTIONS          ###
###################################

unset extract_commands
#----------------------------#
extract_commands() {         #
#----------------------------#

  #Check for libxslt instead of just letting the script hit 'xsltproc' and fail.
  test `type -p xsltproc` || eval "echo \"This feature requires libxslt.\"
  exit 1"

  cd $JHALFSDIR
  VERSION=`grep "ENTITY version " $BOOK/general.ent | sed 's@<!ENTITY version "@@;s@">@@'`

  # Start clean
  if [ -d ${PROGNAME}-commands ]; then
    rm -rf ${PROGNAME}-commands
  else
    mkdir -v ${PROGNAME}-commands
  fi
  echo "Extracting commands... ${BOLD}START${OFF}"

  echo "${tab_}Extracting commands for ${L_arrow}${BOLD}$ARCH${R_arrow} target architecture"
  xsltproc --xinclude \
           --nonet \
           --output ./${PROGNAME}-commands/ \
           $BOOK/stylesheets/dump-commands.xsl $BOOK/$ARCH-index.xml

  # Grab the patches and package names.
  cd $JHALFSDIR

  echo "${tab_}Creating the packages and patches files" ;
  for i in patches packages ; do rm -f $i ; done

  grep "\-version " $BOOK/packages.ent | sed -e 's@<!ENTITY @@' \
                                             -e 's@">@"@' \
                                             -e '/generic/d' >> packages

  # Download the vim-lang package if it must be installed
  if [ "$VIMLANG" = "1" ] ; then
    echo `grep "vim" packages | sed 's@vim@&-lang@'` >> packages
  fi

  grep "^<\!ENTITY" $BOOK/patches.ent | sed -e 's/.* "//' -e 's/">//' >> patches
  # Needed for Groff patchlevel patch
  GROFFLEVEL=`grep "groff-patchlevel" $BOOK/general.ent | sed -e 's/groff-patchlevel //' \
                                                              -e 's/"//g' \
                                                              -e 's@<!ENTITY @@' \
                                                              -e 's|>||'`
  sed -i 's|&groff-patchlevel;|'$GROFFLEVEL'|' patches


  # Preprocess the cmd scripts..
  echo "${tab_}Preprocessing the cmd scripts"
  #
  local file this_script package vrs URLs
  #
  # Create a list of URLs..
  echo "${tab_}${tab_}Writing a list of URLs to filelist_.wget "
  xsltproc --nonet \
           --xinclude \
           -o filelist_.wget \
           $BOOK/stylesheets/wget.xsl \
           $BOOK/$ARCH-index.xml > /dev/null 2>&1
  #
  # Loop through all the command scripts
  echo "${tab_}${tab_}Modifying the cmd scripts"
  for file in `ls ${PROGNAME}-commands/*/*`;do
    #
    # 1. Compress the script file (remove blank lines)
    # 2. Add a variable header and a footer to selected scripts
    this_script=`basename $file`
    #
    # DO NOT play with the chroot scripts.. they are used as is later
    [[ `_IS_ $this_script "chroot"` ]] && continue
    #
    # Strip leading index number and misc test.. This is a miserable method
    package=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' \
                                     -e 's@-static@@' \
                                     -e 's@-final@@' \
                                     -e 's@temp-@@' \
                                     -e 's@-64bit@@' \
                                     -e 's@-64@@' \
                                     -e 's@64@@' \
                                     -e 's@-n32@@' \
                                     -e 's@-build@@' \
                                     -e 's@glibc-headers@glibc@'`
    #
    # Find the package version of the command files
    #
    # A little package name manipulation
    case $package in
      bootscripts)    package="lfs-bootscripts" ;;
      kernel)         package="linux" ;;
    esac
    vrs=`grep "^$package-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`
    #
    # If $vrs isn't empty, we've got a package...
    # NOTE: The included \n causes the separator to be written
    # on the next line. This is for cosmetic purposes only...
    #
    # Set the appropriate 'sha-bang'.. depending of the phase..
    case $package in
      *introduction* | \
      *changingowner* | \
      *creatingdirs* | \
      *createfiles* ) sha_bang=''
         ;;
      *)  sha_bang='#!/bin/bash'
         ;;
    esac
    #
    #
    if [ "$vrs" != "" ] ; then
      HEADER_STR="cd \$PKGDIR${nl_}#------------------"
      FOOTER_STR="#------------------${nl_}exit"
    else
      HEADER_STR="#------------------"
      FOOTER_STR="#------------------${nl_}exit"
    fi
    PKG_URL=`grep -e "$package-$vrs.*tar." $JHALFSDIR/filelist_.wget` && true
    PATCHES=`grep "$package-$vrs.*patch" $JHALFSDIR/filelist_.wget` && true
    #
    # There would be no URL for a cmd only script, reset package name
    if [[ $PKG_URL = "" ]]; then
      package=""
    fi
(
cat << EOF
${sha_bang}
set -e

#####################################
    NAME=${this_script}
    PACKAGE=${package}
    VERSION=${vrs}
    PKG_URL=( ${PKG_URL} )
    PATCHES=( ${PATCHES} )
#####################################

${HEADER_STR}
`grep '.' ${file}`
${FOOTER_STR}
EOF
) > tmp.script
mv tmp.script ${file}

  done # for file in `ls $PROGNAME-commands/*/*`
  #
  # Make the scripts executable.
  chmod -R +x $JHALFSDIR/${PROGNAME}-commands

  # Done. Moving on...
  echo "Extracting commands... ${BOLD}DONE${OFF}"
  get_sources

}



#----------------------------#
host_prep_Makefiles() {       # Initialization of the system
#----------------------------#
  local   LFS_HOST

  echo "${tab_}${GREEN}Processing... ${L_arrow}host prep files${R_arrow}"

  # defined here, only for ease of reading
  LFS_HOST="`echo ${MACHTYPE} | sed -e 's/unknown/cross/g' -e 's/-pc-/-cross-/g'`"
(
cat << EOF
023-creatingtoolsdir:
	@\$(call echo_message, Building)
	@mkdir -v \$(MOUNT_PT)/tools && \\
	rm -fv /tools && \\
	ln -sv \$(MOUNT_PT)/tools /
	@if [ ! -d \$(MOUNT_PT)/sources ]; then \\
		mkdir \$(MOUNT_PT)/sources; \\
	fi;
	@chmod a+wt \$(MOUNT_PT)/sources && \\
	touch \$@

024-creatingcrossdir: 023-creatingtoolsdir
	@mkdir -v \$(MOUNT_PT)/cross-tools && \\
	rm -fv /cross-tools && \\
	ln -sv \$(MOUNT_PT)/cross-tools /
	@touch \$@

025-addinguser:  024-creatingcrossdir
	@\$(call echo_message, Building)
	@if [ ! -d /home/lfs ]; then \\
		groupadd lfs; \\
		useradd -s /bin/bash -g lfs -m -k /dev/null lfs; \\
	else \\
		touch user-lfs-exist; \\
	fi;
	@chown lfs \$(MOUNT_PT) && \\
	chown lfs \$(MOUNT_PT)/tools && \\
	chown lfs \$(MOUNT_PT)/cross-tools && \\
	chown lfs \$(MOUNT_PT)/sources && \\
	touch \$@

026-settingenvironment:  025-addinguser
	@\$(call echo_message, Building)
	@if [ -f /home/lfs/.bashrc -a ! -f /home/lfs/.bashrc.XXX ]; then \\
		mv -v /home/lfs/.bashrc /home/lfs/.bashrc.XXX; \\
	fi;
	@if [ -f /home/lfs/.bash_profile  -a ! -f /home/lfs/.bash_profile.XXX ]; then \\
		mv -v /home/lfs/.bash_profile /home/lfs/.bash_profile.XXX; \\
	fi;
	@echo "set +h" > /home/lfs/.bashrc && \\
	echo "umask 022" >> /home/lfs/.bashrc && \\
	echo "LFS=\$(MOUNT_PT)" >> /home/lfs/.bashrc && \\
	echo "LC_ALL=POSIX" >> /home/lfs/.bashrc && \\
	echo "PATH=/cross-tools/bin:/bin:/usr/bin" >> /home/lfs/.bashrc && \\
	echo "export LFS LC_ALL PATH" >> /home/lfs/.bashrc && \\
	echo "" >> /home/lfs/.bashrc && \\
	echo "unset CFLAGS" >> /home/lfs/.bashrc && \\
	echo "unset CXXFLAGS" >> /home/lfs/.bashrc && \\
	echo "" >> /home/lfs/.bashrc && \\
	echo "export LFS_HOST=\"${LFS_HOST}\"" >> /home/lfs/.bashrc && \\
	echo "export LFS_TARGET=\"${TARGET}\"" >> /home/lfs/.bashrc && \\
	echo "export LFS_TARGET32=\"${TARGET32}\"" >> /home/lfs/.bashrc && \\
	echo "source $JHALFSDIR/envars" >> /home/lfs/.bashrc
	@chown lfs:lfs /home/lfs/.bashrc && \\
	touch envars && \\
	touch \$@
EOF
) >> $MKFILE.tmp

}



#-----------------------------#
cross_tools_Makefiles() {     #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}cross tools${R_arrow}"

  for file in cross-tools/* ; do
    # Keep the script file name
    this_script=`basename $file`
    #
    # Skip this script...
    case $this_script in
      *cflags* | *variables* )  # work done in host_prep_Makefiles
         continue; ;;
      *) ;;
    esac
    #
    # Set the dependency for the first target.
    if [ -z $PREV ] ; then PREV=026-settingenvironment ; fi

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    cross_tools="$cross_tools $this_script"

    # Grab the name of the target (minus the -headers or -cross in the case of gcc
    # and binutils in chapter 5)
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' \
                                  -e 's@-static@@' \
                                  -e 's@-final@@' \
                                  -e 's@-headers@@' \
                                  -e 's@-64@@' \
                                  -e 's@-n32@@'`
    # Adjust 'name' and patch a few scripts on the fly..
    case $name in
      linux-libc) name=linux-libc-headers ;;
    esac
    #
    # Find the version of the command files, if it corresponds with the building of a specific package
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`


    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    # If $vrs isn't empty, we've got a package...
    #
    [[ "$vrs" != "" ]] && wrt_unpack "$name-$vrs.tar.*" &&  echo -e '\ttrue' >> $MKFILE.tmp
    #
    wrt_run_as_lfs "${this_script}" "${file}"
    #
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done # for file in ....
}


#-----------------------------#
temptools_Makefiles() {       #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}temp system${R_arrow}"

  for file in temp-system/* ; do
    # Keep the script file name
    this_script=`basename $file`
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    temptools="$temptools $this_script"

    #
    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`
    #
    # Find the version of the command files, if it corresponds with the building of a specific package
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`


    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and to set the PKGDIR variable.
    #
    [[ "$vrs" != "" ]] && wrt_unpack "$name-$vrs.tar.*" && echo -e '\ttrue' >> $MKFILE.tmp
    #
    wrt_run_as_lfs "${this_script}" "${file}"
    #
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script
  done # for file in ....
}


#-----------------------------#
boot_Makefiles() {            #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}boot${R_arrow}"

  for file in boot/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # A little housekeeping on the scripts
    case $this_script in
      *grub*)     continue     ;;
      *whatnext*) continue     ;;
      *settingenvironment*) sed 's@PS1=@set +h\nPS1=@' -i $file  ;;
      *kernel)   # if there is no kernel config file do not build the kernel
                [[ -z $CONFIG ]] && continue
                sed "s|make mrproper|make mrproper\ncp $CONFIG .config|" -i $file
                # You cannot run menuconfig from within the makefile
                sed 's|menuconfig|oldconfig|'     -i $file
                #If defined include the keymap in the kernel
                if [[ -n "$KEYMAP" ]]; then
                  sed "s|^loadkeys -m.*>|loadkeys -m $KEYMAP >|" -i $file
                else
                  sed '/loadkeys -m/d'    -i $file
                  sed '/drivers\/char/d'  -i $file
                fi
          ;;
    esac
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    boottools="$boottools $this_script"
    #
    # Grab the name of the target, strip id number and misc words.
    case $this_script in
      *kernel)        name=linux           ;;
      *bootscripts)   name=lfs-bootscripts ;;
      *)              name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' -e 's@-build@@' ` ;;
    esac

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    [[ "$vrs" != "" ]] && wrt_unpack "$name-$vrs.tar.*"
    #
    # Select a script execution method
    case $this_script in
      *changingowner*)  wrt_run_as_root "${this_script}" "${file}"    ;;
      *devices*)        wrt_run_as_root "${this_script}" "${file}"    ;;
      *fstab*)   if [[ -n "$FSTAB" ]]; then
                   wrt_copy_fstab "${this_script}"
                 else
                   wrt_run_as_lfs  "${this_script}" "${file}"
                 fi
         ;;
      *)         wrt_run_as_lfs  "${this_script}" "${file}"       ;;
    esac
    #
    # Housekeeping...remove any build directory(ies) except if the package build fails.
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done
  # This will force the Makefile to exit and not allow it to be restarted with
  # the command <make>, The user will have to issue the cmd  <make chapterXX>
  echo -e "\t@\$(call echo_boot_finished,$VERSION) && \\" >> $MKFILE.tmp
  echo -e "\tfalse" >> $MKFILE.tmp
}


#-----------------------------#
chroot_Makefiles() {          #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}chroot${R_arrow}"

  for file in chroot/* ; do
    # Keep the script file name
    this_script=`basename $file`
    #
    # Skipping scripts is done now and not included in the build tree.
    [[ `_IS_ $this_script chroot` ]]   && continue

    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    chroottools="$chroottools $this_script"

    #
    # A little housekeeping on the script contents
    case $this_script in
      *kernfs*)     sed '/exit/d' -i $file   ;;
      *pwdgroup*)   sed '/exec/d' -i $file   ;;
    esac
    #
    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    if [ "$vrs" != "" ] ; then
      case $this_script in
        *util-linux)    wrt_unpack  "$name-$vrs.tar.*"
                        echo -e '\ttrue' >> $MKFILE.tmp
            ;;
        *)              wrt_unpack2 "$name-$vrs.tar.*"
            ;;
      esac
    fi
    #
    # Select a script execution method
    case $this_script in
      *kernfs)        wrt_run_as_root    "${this_script}" "${file}"  ;;
      *util-linux)    wrt_run_as_lfs     "${this_script}" "${file}"  ;;
      *)              wrt_run_as_chroot1 "${this_script}" "${file}"  ;;
    esac
    #
    # Housekeeping...remove the build directory(ies), except if the package build fails.
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done # for file in...
}


#-----------------------------#
testsuite_tools_Makefiles() { #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}testsuite tools${R_arrow}"

  for file in testsuite-tools/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    testsuitetools="$testsuitetools $this_script"

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'\
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    case $name in
      tcl)    wrt_unpack2 "$name$vrs-src.tar.*" ;;
      *)      wrt_unpack2 "$name-$vrs.tar.*"    ;;
    esac
    #
    wrt_run_as_chroot1 "${this_script}" "${file}"
    #
    wrt_remove_build_dirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done
}


#--------------------------------#
bm_testsuite_tools_Makefiles() { #
#--------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(minimal boot) testsuite tools${R_arrow}"

  for file in testsuite-tools/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    testsuitetools="$testsuitetools $this_script"

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'\
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    case $name in
      tcl)    wrt_unpack3 "$name$vrs-src.tar.*" ;;
      *)      wrt_unpack3 "$name-$vrs.tar.*"    ;;
    esac
    #
    wrt_run_as_root2 "${this_script}" "${file}"
    #
    wrt_remove_build_dirs2 "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done
}


#-----------------------------#
final_system_Makefiles() {    #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}final system${R_arrow}"

  for file in final-system/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Skipping scripts is done now so they are not included in the Makefile.
    case $this_script in
      *stripping*) continue  ;;
      *grub*)      continue  ;;
    esac
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    basicsystem="$basicsystem $this_script"
    #
    # A little customizing via sed scripts first..
    if [[ $TEST = "0" ]]; then
      # Drop any package checks..
      sed -e '/make check/d' -e '/make test/d' -i $file
    fi
    case $this_script in
      *coreutils*) sed 's@set -e@set -e; set +h@' -i $file        ;;
      *groff*)     sed "s@\*\*EDITME.*EDITME\*\*@$PAGE@" -i $file  ;;
      *vim*)      sed '/vim -c/d' -i $file  ;;
      *bash*)     sed '/exec /d' -i $file   ;;
      *shadow*)   sed -e '/grpconv/d' -e '/pwconv/d' -e '/passwd root/d' -i $file
      		  sed '/sed -i libtool/d' -i $file
		  sed '/search_path/d'    -i $file
        ;;
      *glibc*)    sed '/tzselect/d' -i $file
                  sed "s@\*\*EDITME.*EDITME\*\*@$TIMEZONE@" -i $file
                  # Manipulate glibc's test to work with Makefile
                  sed -e 's/glibc-check-log.*//' \
                      -e 's@make -k check >@make -k check >glibc-check-log 2>\&1 || true\ngrep Error glibc-check-log || true@' -i $file
        ;;
      *binutils*) sed '/expect /d' -i $file
                  if [[ $TOOLCHAINTEST = "0" ]]; then
                    sed '/make check/d' -i $file
                  fi
        ;;
      *gcc*)      # Ignore all gcc testing for now..
                  sed -e '/make -k check/d' -i $file
                  sed -e '/test_summary/d' -i $file
        ;;
      *texinfo*)  # This sucks as a way to trim a script
                  sed -e '/cd \/usr/d' \
                      -e '/rm dir/d' \
                      -e '/for f in/d' \
                      -e '/do inst/d' \
                      -e '/done/d' -i $file
        ;;
    esac

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' \
                                  -e 's@temp-@@' \
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp

    # If $vrs isn't empty, we've got a package...
    if [ "$vrs" != "" ] ; then
      case $name in
        temp-perl) wrt_unpack2 "perl-$vrs.tar.*"    ;;
        *)         wrt_unpack2 "$name-$vrs.tar.*"   ;;
      esac
      #
      # Export a few 'config' vars..
      case $this_script in
        *glibc*) # For glibc we can set then TIMEZONE envar.
	   wrt_export_timezone           ;;
        *groff*) # For Groff we need to set PAGE envar.
	   wrt_export_pagesize           ;;
      esac
    fi
    #
    wrt_run_as_chroot1 "${this_script}" "${file}"
    #
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done  # for file in final-system/* ...
}


#-----------------------------#
bm_final_system_Makefiles() { #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(minimal boot) final system${R_arrow}"

  for file in final-system/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Skipping scripts is done now so they are not included in the Makefile.
    case $this_script in
      *stripping*) continue   ;;
      *grub*)      continue   ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    basicsystem="$basicsystem $this_script"

    #
    # A little customizing via sed scripts first..
    if [[ $TEST = "0" ]]; then
      # Drop any package checks..
      sed -e '/make check/d' -e '/make test/d' -i $file
    fi
    case $this_script in
      *coreutils*) sed 's@set -e@set -e; set +h@' -i $file        ;;
      *groff*)    sed "s@\*\*EDITME.*EDITME\*\*@$PAGE@" -i $file  ;;
      *vim*)      sed '/vim -c/d' -i $file      ;;
      *bash*)     sed '/exec /d' -i $file       ;;
      *shadow*)   sed -e '/grpconv/d' \
                      -e '/pwconv/d' \
		      -e '/passwd root/d' -i $file
      		  sed  '/sed -i libtool/d' -i $file
		  sed  '/search_path/d'    -i $file
        ;;
      *psmisc*)   # Build fails on creation of this link. <pidof> installed in sysvinit
                  sed -e 's/^ln -s/#ln -s/' -i $file
        ;;
      *glibc*)    sed '/tzselect/d' -i $file
                  sed "s@\*\*EDITME.*EDITME\*\*@$TIMEZONE@" -i $file
                  # Manipulate glibc's test to work with Makefile
                  sed -e 's/glibc-check-log.*//' -e 's@make -k check >@make -k check >glibc-check-log 2>\&1 || true\ngrep Error glibc-check-log || true@' -i $file
        ;;
      *binutils*) sed '/expect /d' -i $file
                  if [[ $TOOLCHAINTEST = "0" ]]; then
                    sed '/make check/d' -i $file
                  fi
        ;;
      *gcc*)      # Ignore all gcc testing for now..
                  sed -e '/make -k check/d' -i $file
                  sed -e '/test_summary/d' -i $file
        ;;
      *texinfo*)  # This sucks as a way to trim a script
                  sed -e '/cd \/usr/d' \
                      -e '/rm dir/d' \
                      -e '/for f in/d' \
                      -e '/do inst/d' \
                      -e '/done/d' -i $file
        ;;
    esac

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' \
                                  -e 's@temp-@@' \
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp

    # If $vrs isn't empty, we've got a package...
    if [ "$vrs" != "" ] ; then
      case $name in
        temp-perl) wrt_unpack3 "perl-$vrs.tar.*"    ;;
        *)         wrt_unpack3 "$name-$vrs.tar.*"   ;;
      esac
      #
      # Export a few 'config' vars..
      case $this_script in
        *glibc*) # For glibc we can set then TIMEZONE envar.
                  echo -e '\t@echo "export TIMEZONE=$(TIMEZONE)" >> envars' >> $MKFILE.tmp   ;;
        *groff*) # For Groff we need to set PAGE envar.
                  echo -e '\t@echo "export PAGE=$(PAGE)" >> envars' >> $MKFILE.tmp           ;;
      esac
    fi
    #
    wrt_run_as_root2 "${this_script}" "${file}"
    #
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs2 "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done  # for file in final-system/* ...
}


#-----------------------------#
bootscripts_Makefiles() {     #
#-----------------------------#
    echo "${tab_}${GREEN}Processing... ${L_arrow}bootscripts${R_arrow}"

  for file in bootscripts/* ; do
    # Keep the script file name
    this_script=`basename $file`

    case $this_script in
      *udev*) continue    ;;  # This is not a script but a commentary
      *console*) continue ;; # Use the files that came with the bootscripts
      *)  ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    bootscripttools="$bootscripttools $this_script"

    # A little bit of script modification
    case $this_script in
      *profile*)  # Over-ride the book cmds, write our own simple one.
(
cat <<- EOF
	cat > /etc/profile << "_EOF_"
	# Begin /etc/profile

	export LC_ALL=${LC_ALL}
	export LANG=${LANG}
	export INPUTRC=/etc/inputrc

	# End /etc/profile
	_EOF_
EOF
) > $file
           ;;
    esac

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'\
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`
    if [[ `_IS_ $name bootscripts` ]]; then name=lfs-bootscripts; fi

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    # If $vrs isn't empty, we've got a package...
    #
    [[ "$vrs" != "" ]] && wrt_unpack2 "$name-$vrs.tar.*"
    #
    wrt_run_as_chroot1 "${this_script}" "${file}"
    #
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done  # for file in bootscripts/* ...

}

#-----------------------------#
bm_bootscripts_Makefiles() {  #
#-----------------------------#
    echo "${tab_}${GREEN}Processing... ${L_arrow}(minimal boot) bootscripts${R_arrow}"

  for file in bootscripts/* ; do
    # Keep the script file name
    this_script=`basename $file`

    case $this_script in
      *udev*) continue    ;;  # This is not a script but a commentary
      *console*) continue ;; # Use the files that came with the bootscripts
      *)  ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    bootscripttools="$bootscripttools $this_script"

    # A little bit of script modification
    case $this_script in
      *profile*)  # Over-ride the book cmds, write our own simple one.
(
cat <<- EOF
	cat > /etc/profile << "_EOF_"
	# Begin /etc/profile

	export LC_ALL=${LC_ALL}
	export LANG=${LANG}
	export INPUTRC=/etc/inputrc

	# End /etc/profile
	_EOF_
EOF
) > $file
           ;;
    esac

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'\
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`
    if [[ `_IS_ $name bootscripts` ]]; then name=lfs-bootscripts; fi

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    # If $vrs isn't empty, we've got a package...
    #
    [[ "$vrs" != "" ]] && wrt_unpack3 "$name-$vrs.tar.*"
    #
    wrt_run_as_root2 "${this_script}" "${file}"
    #
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs2 "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done  # for file in bootscripts/* ...

}



#-----------------------------#
bootable_Makefiles() {        #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}make bootable${R_arrow}"

  for file in bootable/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # A little housekeeping on the scripts
    case $this_script in
      *grub*)     continue ;;
      *kernel)
               # if there is no kernel config file do not build the kernel
               [[ -z $CONFIG ]] && continue
               sed "s|make mrproper|make mrproper\ncp $CONFIG .config|" -i $file
               # You cannot run menuconfig from within the makefile
               sed 's|menuconfig|oldconfig|'     -i $file
               # If defined include the keymap in the kernel
               if [[ -n "$KEYMAP" ]]; then
                 sed "s|^loadkeys -m.*>|loadkeys -m $KEYMAP >|" -i $file
               else
                 sed '/loadkeys -m/d'    -i $file
                 sed '/drivers\/char/d'  -i $file
               fi
         ;;
    esac
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    bootabletools="$bootabletools $this_script"
    #
    # Grab the name of the target, strip id number and misc words.
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' -e 's@-build@@' `
    [[ `_IS_ $this_script "kernel"` ]] && name=linux

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    [[ "$vrs" != "" ]] && wrt_unpack "$name-$vrs.tar.*"
    #
    # Select a script execution method
    case $this_script in
      *fstab*)  if [[ -n "$FSTAB" ]]; then
                  wrt_copy_fstab "${this_script}"
                else
                  wrt_run_as_lfs  "${this_script}" "${file}"
                fi
          ;;
      *)  wrt_run_as_lfs  "${this_script}" "${file}"   ;;
    esac
    #
    # Housekeeping...remove any build directory(ies) except if the package build fails.
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done

}



#-----------------------------#
bm_bootable_Makefiles() {     #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(minimal boot) make bootable${R_arrow}"

  for file in bootable/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # A little housekeeping on the scripts
    case $this_script in
      *grub*)     continue  ;;
      *kernel)
               # if there is no kernel config file do not build the kernel
               [[ -z $CONFIG ]] && continue
               cfg_file="/sources/`basename $CONFIG`"
               sed "s|make mrproper|make mrproper\ncp $cfg_file .config|" -i $file
               # You cannot run menuconfig from within the makefile
               sed 's|menuconfig|oldconfig|'     -i $file
               # If defined include the keymap in the kernel
               if [[ -n "$KEYMAP" ]]; then
                 sed "s|^loadkeys -m.*>|loadkeys -m $KEYMAP >|" -i $file
               else
                 sed '/loadkeys -m/d'    -i $file
                 sed '/drivers\/char/d'  -i $file
               fi
         ;;
    esac
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    bootabletools="$bootabletools $this_script"
    #
    # Grab the name of the target, strip id number and misc words.
    case $this_script in
      *kernel) name=linux
         ;;
      *)       name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' -e 's@-build@@' ` ;;
    esac

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    echo -e "\n$this_script:  $PREV\n\t@\$(call echo_message, Building)" >> $MKFILE.tmp
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    [[ "$vrs" != "" ]] && wrt_unpack3 "$name-$vrs.tar.*"
    #
    # Select a script execution method
    case $this_script in
      *fstab*)  if [[ -n "$FSTAB" ]]; then
                  wrt_copy_fstab2 "${this_script}"
                else
                  wrt_run_as_root2  "${this_script}" "${file}"
                fi
          ;;
      *)  wrt_run_as_root2  "${this_script}" "${file}"   ;;
    esac
    #
    # Housekeeping...remove any build directory(ies) except if the package build fails.
    [[ "$vrs" != "" ]] && wrt_remove_build_dirs2 "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done

}



#-----------------------------#
the_end_Makefiles() {         #
#-----------------------------#
    echo "${tab_}${GREEN}Processing... ${L_arrow}THE END${R_arrow}"
}


#-----------------------------#
build_Makefile() {            # Construct a Makefile from the book scripts
#-----------------------------#
  echo "Creating Makefile... ${BOLD}START${OFF}"

  cd $JHALFSDIR/${PROGNAME}-commands
  # Start with a clean Makefile.tmp file
  >$MKFILE.tmp

  host_prep_Makefiles
  cross_tools_Makefiles
  temptools_Makefiles
  if [[ $BOOTMINIMAL = "0" ]]; then
    chroot_Makefiles
    if [[ $TOOLCHAINTEST = "1" ]]; then
      testsuite_tools_Makefiles
    fi
    final_system_Makefiles
    bootscripts_Makefiles
    bootable_Makefiles
  else
    boot_Makefiles	# This phase must die at the end of its run..
    if [[ $TOOLCHAINTEST = "1" ]]; then
      bm_testsuite_tools_Makefiles
    fi
    bm_final_system_Makefiles
    bm_bootscripts_Makefiles
    bm_bootable_Makefiles
  fi
#   the_end_Makefiles


  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
(
    cat << EOF
$HEADER

SRC= /sources
MOUNT_PT= $BUILDDIR
PAGE= $PAGE
TIMEZONE= $TIMEZONE

include makefile-functions

EOF
) > $MKFILE

  # Add chroot commands
  i=1
  for file in chroot/*chroot* ; do
    chroot=`cat $file | sed -e '/#!\/bin\/sh/d' \
                            -e '/^export/d' \
                            -e '/^logout/d' \
                            -e 's@ \\\@ @g' | tr -d '\n' |  sed -e 's/  */ /g' \
                                                                -e 's|\\$|&&|g' \
                                                                -e 's|exit||g' \
                                                                -e 's|$| -c|' \
                                                                -e 's|"$$LFS"|$(MOUNT_PT)|'\
                                                                -e 's|set -e||'`
    echo -e "CHROOT$i= $chroot\n" >> $MKFILE
    i=`expr $i + 1`
  done

  # Drop in the main target 'all:' and the chapter targets with each sub-target
  # as a dependency.
(
	cat << EOF
all:  chapter2 chapter3 chapter4 chapter5 chapter6 chapter7 chapter8
	@\$(call echo_finished,$VERSION)

chapter2:  023-creatingtoolsdir 024-creatingcrossdir 025-addinguser 026-settingenvironment

chapter3:  chapter2 $cross_tools

chapter4:  chapter3 $temptools

chapter5:  chapter4 $chroottools $boottools

chapter6:  chapter5 $basicsystem

chapter7:  chapter6 $bootscripttools

chapter8:  chapter7 $bootabletools

clean-all:  clean
	rm -rf ./{${PROGNAME}-commands,logs,Makefile,dump-clfs-scripts.xsl,functions,packages,patches}

clean:  clean-chapter4 clean-chapter3 clean-chapter2

clean-chapter2:
	-if [ ! -f user-lfs-exist ]; then \\
		userdel lfs; \\
		rm -rf /home/lfs; \\
	fi;
	rm -rf \$(MOUNT_PT)/tools
	rm -f /tools
	rm -rf \$(MOUNT_PT)/cross-tools
	rm -f /cross-tools
	rm -f envars user-lfs-exist
	rm -f 02* logs/02*.log

clean-chapter3:
	rm -rf \$(MOUNT_PT)/tools/*
	rm -f $cross_tools restore-lfs-env sources-dir
	cd logs && rm -f $cross_tools && cd ..

clean-chapter4:
	-umount \$(MOUNT_PT)/sys
	-umount \$(MOUNT_PT)/proc
	-umount \$(MOUNT_PT)/dev/shm
	-umount \$(MOUNT_PT)/dev/pts
	-umount \$(MOUNT_PT)/dev
	rm -rf \$(MOUNT_PT)/{bin,boot,dev,etc,home,lib,lib64,media,mnt,opt,proc,root,sbin,srv,sys,tmp,usr,var}
	rm -f $temptools
	cd logs && rm -f $temptools && cd ..


restore-lfs-env:
	@\$(call echo_message, Building)
	@if [ -f /home/lfs/.bashrc.XXX ]; then \\
		mv -fv /home/lfs/.bashrc.XXX /home/lfs/.bashrc; \\
	fi;
	@if [ -f /home/lfs/.bash_profile.XXX ]; then \\
		mv -v /home/lfs/.bash_profile.XXX /home/lfs/.bash_profile; \\
	fi;
	@chown lfs:lfs /home/lfs/.bash* && \\
	touch \$@

EOF
) >> $MKFILE


  # Bring over the items from the Makefile.tmp
  cat $MKFILE.tmp >> $MKFILE
  rm $MKFILE.tmp
  echo "Creating Makefile... ${BOLD}DONE${OFF}"

}

