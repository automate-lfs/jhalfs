#!/bin/sh
# $Id$


orphan_scripts="" # 2 scripts do not fit BOOT_Makefiles LUSER environment

###################################
###          FUNCTIONS          ###
###################################

#--------------------------------------#
BOOT_wrt_target() {                    # "${this_script}" "$PREV"
#--------------------------------------#
  local i=$1
  local PREV=$2
  case $i in
    iteration* ) local LOGFILE=$this_script.log ;;
             * ) local LOGFILE=$this_script ;;
  esac
(
cat << EOF

$i:  $PREV
	@\$(call echo_message, Building)
	@./progress_bar.sh \$@ \$\$PPID &
	@echo -e "\n\`date\`\n\nKB: \`du -skx --exclude=${SCRIPT_ROOT}\`\n" >logs/$LOGFILE
EOF
) >> $MKFILE.tmp
}

#--------------------------------------#
BOOT_wrt_Unpack() {                    # "$pkg_tarball"
#--------------------------------------#
  local FILE=$1
  local optSAVE_PREVIOUS=$2

  if [ "${optSAVE_PREVIOUS}" != "1" ]; then
(
cat << EOF
	@\$(call remove_existing_dirs2,$FILE)
EOF
) >> $MKFILE.tmp
  fi
(
cat  << EOF
	@\$(call unpack3,$FILE)
	@\$(call get_pkg_root2)
EOF
) >> $MKFILE.tmp
}

#----------------------------------#
BOOT_wrt_RunAsRoot() {             # "${this_script}" "${file}"
#----------------------------------#
  local this_script=$1
  local file=$2
(
cat << EOF
	@( time { source envars && ${PROGNAME}-commands/`dirname $file`/\$@ >>logs/\$@ 2>&1 ; } ) 2>>logs/\$@ && \\
	echo -e "\nKB: \`du -skx --exclude=${SCRIPT_ROOT} \`\n" >>logs/\$@
EOF
) >> $MKFILE.tmp
}

#--------------------------------------#
BOOT_wrt_RemoveBuildDirs() {           # "${name}"
#--------------------------------------#
  local name=$1
(
cat << EOF
	@\$(call remove_build_dirs2,$name)
EOF
) >> $MKFILE.tmp
}

#----------------------------------#
BOOT_wrt_test_log() {              #
#----------------------------------#
  local TESTLOGFILE=$1
(
cat  << EOF
	@echo "export TEST_LOG=/\$(SCRIPT_ROOT)/test-logs/$TESTLOGFILE" >> envars && \\
	echo -e "\n\`date\`\n" >test-logs/$TESTLOGFILE
EOF
) >> $MKFILE.tmp
}

#----------------------------------#
BOOT_wrt_CopyFstab() {             #
#----------------------------------#
(
cat << EOF
	@( time { cp -v /sources/fstab /etc/fstab >>logs/${this_script} 2>&1 ; } ) 2>>logs/${this_script}
EOF
) >> $MKFILE.tmp
}


########################################


#--------------------------------------#
host_prep_Makefiles() {                #
#--------------------------------------#
  local   CLFS_HOST

  echo "${tab_}${GREEN}Processing... ${L_arrow}host prep files  ( SETUP ) ${R_arrow}"

  # defined here, only for ease of reading
  CLFS_HOST="$(echo $MACHTYPE | sed "s/$(echo $MACHTYPE | cut -d- -f2)/cross/")"
(
cat << EOF
023-creatingtoolsdir:
	@\$(call echo_message, Building)
	@mkdir \$(MOUNT_PT)/tools && \\
	rm -f /tools && \\
	ln -s \$(MOUNT_PT)/tools /
	@if [ ! -d \$(MOUNT_PT)/sources ]; then \\
		mkdir \$(MOUNT_PT)/sources; \\
	fi;
	@chmod a+wt \$(MOUNT_PT)/sources && \\
	touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

024-creatingcrossdir: 023-creatingtoolsdir
	@mkdir -v \$(MOUNT_PT)/cross-tools && \\
	rm -f /cross-tools && \\
	ln -s \$(MOUNT_PT)/cross-tools /
	@touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

025-addinguser:  024-creatingcrossdir
	@\$(call echo_message, Building)
	@if [ ! -d /home/\$(LUSER) ]; then \\
		groupadd \$(LGROUP); \\
		useradd -s /bin/bash -g \$(LGROUP) -m -k /dev/null \$(LUSER); \\
	else \\
		touch luser-exist; \\
	fi;
	@chown \$(LUSER) \$(MOUNT_PT) && \\
	chown \$(LUSER) \$(MOUNT_PT)/tools && \\
	chown \$(LUSER) \$(MOUNT_PT)/cross-tools && \\
	chown \$(LUSER) \$(MOUNT_PT)/sources && \\
	touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

026-settingenvironment:  025-addinguser
	@\$(call echo_message, Building)
	@if [ -f /home/\$(LUSER)/.bashrc -a ! -f /home/\$(LUSER)/.bashrc.XXX ]; then \\
		mv /home/\$(LUSER)/.bashrc /home/\$(LUSER)/.bashrc.XXX; \\
	fi;
	@if [ -f /home/\$(LUSER)/.bash_profile  -a ! -f /home/\$(LUSER)/.bash_profile.XXX ]; then \\
		mv /home/\$(LUSER)/.bash_profile /home/\$(LUSER)/.bash_profile.XXX; \\
	fi;
	@echo "set +h" > /home/\$(LUSER)/.bashrc && \\
	echo "umask 022" >> /home/\$(LUSER)/.bashrc && \\
	echo "CLFS=\$(MOUNT_PT)" >> /home/\$(LUSER)/.bashrc && \\
	echo "LC_ALL=POSIX" >> /home/\$(LUSER)/.bashrc && \\
	echo "PATH=/cross-tools/bin:/bin:/usr/bin" >> /home/\$(LUSER)/.bashrc && \\
	echo "export CLFS LC_ALL PATH" >> /home/\$(LUSER)/.bashrc && \\
	echo "" >> /home/\$(LUSER)/.bashrc && \\
	echo "unset CFLAGS" >> /home/\$(LUSER)/.bashrc && \\
	echo "unset CXXFLAGS" >> /home/\$(LUSER)/.bashrc && \\
	echo "" >> /home/\$(LUSER)/.bashrc && \\
	echo "export CLFS_HOST=\"${CLFS_HOST}\"" >> /home/\$(LUSER)/.bashrc && \\
	echo "export CLFS_TARGET=\"${TARGET}\"" >> /home/\$(LUSER)/.bashrc && \\
	echo "export CLFS_TARGET32=\"${TARGET32}\"" >> /home/\$(LUSER)/.bashrc && \\
	echo "source $JHALFSDIR/envars" >> /home/\$(LUSER)/.bashrc
	@chown \$(LUSER):\$(LGROUP) /home/\$(LUSER)/.bashrc && \\
	touch envars && \\
	chmod -R a+wt \$(MOUNT_PT) && \\
	chown -R \$(LUSER) \$(MOUNT_PT)/\$(SCRIPT_ROOT) && \\
	touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)
EOF
) >> $MKFILE.tmp
  host_prep=" 023-creatingtoolsdir 024-creatingcrossdir 026-settingenvironment"

}

#--------------------------------------#
cross_tools_Makefiles() {              #
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}cross tools  ( LUSER ) ${R_arrow}"

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
				  -e 's@-64@@' \
                                  -e 's@-n32@@'`
    pkg_tarball=$(get_package_tarball_name $name)

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    LUSER_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    #
    [[ "$pkg_tarball" != "" ]] && LUSER_wrt_unpack "$pkg_tarball"
    #
    LUSER_wrt_RunAsUser "${file}"
    #
    [[ "$pkg_tarball" != "" ]] && LUSER_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done # for file in ....
}

#--------------------------------------#
temptools_Makefiles() {                #
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}temp system  ( LUSER ) ${R_arrow}"

  for file in temp-system/* ; do
    # Keep the script file name
    this_script=`basename $file`
    #
    #  Deal with any odd scripts..
    case $this_script in
      *choose) # The choose script will fail if you cannot enter the new environment
               # If the 'boot' build method was chosen don't run the script
         [[ $METHOD = "boot" ]] && continue; ;;
      *) ;;
    esac

    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    temptools="$temptools $this_script"

    #
    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`
    #
    pkg_tarball=$(get_package_tarball_name $name)

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    LUSER_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    # Insert instructions for unpacking the package and to set the PKGDIR variable.
    #
    [[ "$pkg_tarball" != "" ]] && LUSER_wrt_unpack "$pkg_tarball"
    [[ "$pkg_tarball" != "" ]] && [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    #
    LUSER_wrt_RunAsUser "${file}"
    #
    [[ "$pkg_tarball" != "" ]] && LUSER_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script
  done # for file in ....
}


#--------------------------------------#
chroot_Makefiles() {                   #
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}tmptools CHROOT        ( CHROOT ) ${R_arrow}"

  for file in chroot/* ; do
    # Keep the script file name
    this_script=`basename $file`
    #
    # Skipping scripts is done now and not included in the build tree.
    case $this_script in
      *chroot*) continue ;;
    esac

    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    case "${this_script}" in
      *util-linux) orphan_scripts="${orphan_scripts} ${this_script}"  ;;
      *kernfs)     orphan_scripts="${orphan_scripts} ${this_script}"  ;;
      *)           chroottools="$chroottools $this_script"            ;;
    esac    

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`

    pkg_tarball=$(get_package_tarball_name $name)
    
    # This is very ugly:: util-linux is in /chroot but must be run under LUSER
    # .. Customized makefile entry 
    case "${this_script}" in
      *util-linux) 
         LUSER_wrt_target "${this_script}" "$PREV"
         LUSER_wrt_unpack "$pkg_tarball"
         [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
         LUSER_wrt_RunAsUser "${file}"
         LUSER_RemoveBuildDirs "${name}"
         wrt_touch
	 temptools="$temptools $this_script"
	 continue ;;
     esac


    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    CHROOT_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    if [ "$pkg_tarball" != "" ] ; then
      case $this_script in
        *util-linux)      ROOT_Unpack  "$pkg_tarball"  ;;
        *)              CHROOT_Unpack "$pkg_tarball"  ;;
      esac
      [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi
    #
    # Select a script execution method
    case $this_script in
      *kernfs)      wrt_RunAsRoot         "${this_script}" "${file}"  ;;
      *util-linux)  ROOT_RunAsRoot        "${file}"  ;;
      *)            CHROOT_wrt_RunAsRoot  "${file}"  ;;
    esac
    #
    # Housekeeping...remove the build directory(ies), except if the package build fails.
    [[ "$pkg_tarball" != "" ]] && CHROOT_wrt_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done # for file in...
}


#--------------------------------------#
boot_Makefiles() {                     #
#--------------------------------------#
  
  echo "${tab_}${GREEN}Processing... ${L_arrow}tmptools BOOT  ( LUSER ) ${R_arrow}"
  #
  # Create a target bootable partition containing a compile environment. Later
  #  on we boot into this environment and contine the build.
  #
  for file in boot/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # A little housekeeping on the scripts
    case $this_script in
      *grub | *aboot | *colo | *silo | *arcload | *lilo )     continue     ;;
      *whatnext*) continue     ;;
      *fstab)   [[ ! -z ${FSTAB} ]] && cp ${FSTAB} $BUILDDIR/sources/fstab ;;
      *kernel)  # if there is no kernel config file do not build the kernel
                [[ -z $CONFIG ]] && continue
                  # Copy the config file to /sources with a standardized name
                cp $BOOT_CONFIG $BUILDDIR/sources/bootkernel-config
          ;;
    esac
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    case "${this_script}" in
      *changingowner)  orphan_scripts="${orphan_scripts} ${this_script}"  ;;
      *devices)        orphan_scripts="${orphan_scripts} ${this_script}"  ;;
      *)               boottools="$boottools $this_script" ;;
    esac
    #
    # Grab the name of the target, strip id number and misc words.
    case $this_script in
      *kernel)        name=linux                   ;;
      *bootscripts)   name="bootscripts-cross-lfs" ;;
      *udev-rules)    name="udev-cross-lfs"        ;;
      *grub-build)    name=grub                    ;;
      *-aboot-build)  name=aboot                   ;;
      *yaboot-build)  name=yaboot                  ;;
      *colo-build)    name=colo                    ;;
      *silo-build)    name=silo                    ;;
      *arcload-build) name=arcload                 ;;
      *lilo-build)    name=lilo                    ;;
      *)              name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' -e 's@-build@@' ` ;;
    esac
      # Identify the unique version naming scheme for the clfs bootscripts..(bad boys)
    pkg_tarball=$(get_package_tarball_name $name)

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    LUSER_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    [[ "$pkg_tarball" != "" ]] && LUSER_wrt_unpack "$pkg_tarball"
    [[ "$pkg_tarball" != "" ]] && [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    #
    # Select a script execution method
    case $this_script in
       # The following 2 scripts are defined in the /boot directory but need
       # to be run as a root user. Set them up here but run them in another phase
      *changingowner*)  wrt_RunAsRoot "${this_script}" "${file}"    ;;
      *devices*)        wrt_RunAsRoot "${this_script}" "${file}"    ;;
      *fstab*)   if [[ -n "$FSTAB" ]]; then
                   LUSER_wrt_CopyFstab
                 else
                   LUSER_wrt_RunAsUser  "${file}"
                 fi
         ;;
      *)         LUSER_wrt_RunAsUser  "${file}"       ;;
    esac
    #
    # Housekeeping...remove any build directory(ies) except if the package build fails.
    [[ "$pkg_tarball" != "" ]] && LUSER_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done
}


#--------------------------------------#
chroot_testsuite_tools_Makefiles() {   #
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) testsuite tools  ( CHROOT ) ${R_arrow}"

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

    pkg_tarball=$(get_package_tarball_name $name)

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    CHROOT_wrt_target "${this_script}" "$PREV"
    #
    CHROOT_Unpack "$pkg_tarball"
    [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    #
    CHROOT_wrt_RunAsRoot "${file}"
    #
    CHROOT_wrt_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done
}

#--------------------------------------#
boot_testsuite_tools_Makefiles() {     #
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) testsuite tools ( ROOT ) ${R_arrow}"
  for file in testsuite-tools/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    PREV=
    testsuitetools="$testsuitetools $this_script"

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'\
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`

    pkg_tarball=$(get_package_tarball_name $name)

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    BOOT_wrt_target "${this_script}" "$PREV"
    #
    BOOT_wrt_Unpack "$pkg_tarball"
    [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    #
    BOOT_wrt_RunAsRoot "${this_script}" "${file}"
    #
    BOOT_wrt_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done

}


#--------------------------------------#
chroot_final_system_Makefiles() {      #
#--------------------------------------#
  # Set envars and scripts for iteration targets
  LOGS="" # Start with an empty global LOGS envar
  if [[ -z "$1" ]] ; then
    local N=""
  else
    local N=-build_$1
    local basicsystem=""
    mkdir final-system$N
    cp final-system/* final-system$N
    for script in final-system$N/* ; do
      # Overwrite existing symlinks, files, and dirs
      sed -e 's/ln -sv/&f/g' \
          -e 's/mv -v/&f/g' \
          -e 's/mkdir -v/&p/g' -i ${script}
    done
    # Remove Bzip2 binaries before make install
    sed -e 's@make install@rm -vf /usr/bin/bz*\n&@' -i final-system$N/*-bzip2
    # Delete *old Readline libraries just after make install
    sed -e 's@make install@&\nrm -v /lib/lib{history,readline}*old@' -i final-system$N/*-readline
  fi

  echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) final system$N ( CHROOT ) ${R_arrow}"

  for file in final-system$N/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Test if the stripping phase must be skipped.
    # Skip alsp temp-perl for iterative runs
    case $this_script in
      *stripping*) [[ "$STRIP" = "n" ]] && continue ;;
      *temp-perl*) [[ -n "$N" ]] && continue ;;
    esac

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' \
                                  -e 's@temp-@@' \
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`

    # Find the version of the command files, if it corresponds with the building of
    # a specific package. We need this here to can skip scripts not needed for
    # iterations rebuilds
    pkg_tarball=$(get_package_tarball_name $name)

    if [[ "$pkg_tarball" = "" ]] && [[ -n "$N" ]] ; then
      case "${this_script}" in
        *stripping*) ;;
        *)  continue ;;
      esac
    fi

    # Append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    basicsystem="$basicsystem ${this_script}${N}"

    # Append each name of the script files to a list (this will become
    # the names of the logs to be moved for each iteration)
    LOGS="$LOGS ${this_script}"

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    CHROOT_wrt_target "${this_script}${N}" "$PREV"

    # If $pkg_tarball isn't empty, we've got a package...
    if [ "$pkg_tarball" != "" ] ; then
      CHROOT_Unpack "$pkg_tarball"
      # If the testsuites must be run, initialize the log file
      case $name in
        binutils | gcc | glibc )
          [[ "$TEST" != "0" ]] && CHROOT_wrt_test_log "${this_script}"
          ;;
        * )
          [[ "$TEST" = "2" ]] || [[ "$TEST" = "3" ]] && CHROOT_wrt_test_log "${this_script}"
          ;;
      esac
      # If using optimizations, write the instructions
      [[ "$OPTIMIZE" != "0" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi
    #
    CHROOT_wrt_RunAsRoot  "${file}"
    #
    [[ "$pkg_tarball" != "" ]] && CHROOT_wrt_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=${this_script}${N}
    # Set system_build envar for iteration targets
    system_build=$basicsystem
  done  # for file in final-system/* ...
}

#--------------------------------------#
boot_final_system_Makefiles() {        #
#--------------------------------------#
  # Set envars and scripts for iteration targets
  LOGS="" # Start with an empty global LOGS envar
  if [[ -z "$1" ]] ; then
    local N=""
    # The makesys phase was initiated in bm_testsuite_tools_makefile
    [[ "$TEST" = 0 ]] && PREV=""
  else
    local N=-build_$1
    local basicsystem=""
    mkdir final-system$N
    cp final-system/* final-system$N
    for script in final-system$N/* ; do
      # Overwrite existing symlinks, files, and dirs
      sed -e 's/ln -sv/&f/g' \
          -e 's/mv -v/&f/g' \
          -e 's/mkdir -v/&p/g' -i ${script}
    done
    # Remove Bzip2 binaries before make install
    sed -e 's@make install@rm -vf /usr/bin/bz*\n&@' -i final-system$N/*-bzip2
    # Delete *old Readline libraries just after make install
    sed -e 's@make install@&\nrm -v /lib/lib{history,readline}*old@' -i final-system$N/*-readline
  fi

  echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) final system$N  ( ROOT ) ${R_arrow}"

  for file in final-system$N/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Test if the stripping phase must be skipped
    # Skip alsp temp-perl for iterative runs
    case $this_script in
      *stripping*) [[ "$STRIP" = "n" ]] && continue ;;
      *temp-perl*) [[ -n "$N" ]] && continue ;;
    esac

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' \
                                  -e 's@temp-@@' \
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`

    # Find the version of the command files, if it corresponds with the building of
    # a specific package. We need this here to can skip scripts not needed for
    # iterations rebuilds

    pkg_tarball=$(get_package_tarball_name $name)

    if [[ "$pkg_tarball" = "" ]] && [[ -n "$N" ]] ; then
      case "${this_script}" in
        *stripping*) ;;
        *)  continue ;;
      esac
    fi

    # Append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    basicsystem="$basicsystem ${this_script}${N}"

    # Append each name of the script files to a list (this will become
    # the names of the logs to be moved for each iteration)
    LOGS="$LOGS ${this_script}"

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    BOOT_wrt_target "${this_script}${N}" "$PREV"

    # If $pkg_tarball isn't empty, we've got a package...
    if [ "$pkg_tarball" != "" ] ; then
      FILE="$pkg_tarball"
      BOOT_wrt_Unpack "$FILE"
      # If the testsuites must be run, initialize the log file
      case $name in
        binutils | gcc | glibc )
          [[ "$TEST" != "0" ]] && BOOT_wrt_test_log "${this_script}"
          ;;
        * )
          [[ "$TEST" = "2" ]] || [[ "$TEST" = "3" ]] && BOOT_wrt_test_log "${this_script}"
          ;;
      esac
      # If using optimizations, write the instructions
      [[ "$OPTIMIZE" != "0" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi
    #
    BOOT_wrt_RunAsRoot "${this_script}" "${file}"
    #
    [[ "$pkg_tarball" != "" ]] && BOOT_wrt_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=${this_script}${N}
    # Set system_build envar for iteration targets
    system_build=$basicsystem
  done  # for file in final-system/* ...

}

#--------------------------------------#
chroot_bootscripts_Makefiles() {       #
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) bootscripts   ( CHROOT ) ${R_arrow}"

  for file in bootscripts/* ; do
    # Keep the script file name
    this_script=`basename $file`

    case $this_script in
      *udev)     continue ;; # This is not a script but a commentary, we want udev-rules
      *console*) continue ;; # Use the files that came with the bootscripts
      *)  ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    bootscripttools="$bootscripttools $this_script"

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'\
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`
    case $name in
      *bootscripts*) name=bootscripts-cross-lfs ;;
      *udev-rules)   name=udev-cross-lfs ;;
    esac

    pkg_tarball=$(get_package_tarball_name $name)

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    CHROOT_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    #
    [[ "$pkg_tarball" != "" ]] && CHROOT_Unpack "$pkg_tarball"
    #
    CHROOT_wrt_RunAsRoot "${file}"
    #
    [[ "$pkg_tarball" != "" ]] && CHROOT_wrt_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done  # for file in bootscripts/* ...
}

#--------------------------------------#
boot_bootscripts_Makefiles() {         #
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) bootscripts     ( ROOT ) ${R_arrow}"

  for file in bootscripts/* ; do
    # Keep the script file name
    this_script=`basename $file`

    case $this_script in
      *udev) continue    ;;  # This is not a script but a commentary
      *console*) continue ;; # Use the files that came with the bootscripts
      *)  ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    bootscripttools="$bootscripttools $this_script"

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'\
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`
    case $name in
      *bootscripts*) name=bootscripts-cross-lfs ;;
      *udev-rules)   name=udev-cross-lfs ;;
    esac

    pkg_tarball=$(get_package_tarball_name $name)

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    BOOT_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    #
    [[ "$pkg_tarball" != "" ]] && BOOT_wrt_Unpack "$pkg_tarball"
    #
    BOOT_wrt_RunAsRoot "${this_script}" "${file}"
    #
    [[ "$pkg_tarball" != "" ]] && BOOT_wrt_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done  # for file in bootscripts/* ...
}

#--------------------------------------#
chroot_bootable_Makefiles() {          #
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) make bootable ( CHROOT ) ${R_arrow}"

  for file in {bootable,the-end}/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # A little housekeeping on the scripts
    case $this_script in
      *grub | *aboot | *colo | *silo | *arcload | *lilo | *reboot* )  continue ;;
      *fstab)  [[ ! -z ${FSTAB} ]] && cp ${FSTAB} $BUILDDIR/sources/fstab ;;
      *kernel) # if there is no kernel config file do not build the kernel
               [[ -z $CONFIG ]] && continue
                 # Copy the config file to /sources with a standardized name
               cp $CONFIG $BUILDDIR/sources/kernel-config
        ;;
    esac
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    bootabletools="$bootabletools $this_script"
    #
    # Grab the name of the target, strip id number and misc words.
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' -e 's@-build@@' `
    case $this_script in
      *kernel*) name=linux
       ;;
    esac

    pkg_tarball=$(get_package_tarball_name $name)

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    CHROOT_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    [[ "$pkg_tarball" != "" ]] && CHROOT_Unpack "$pkg_tarball"
    #
    # Select a script execution method
    case $this_script in
      *fstab*)   if [[ -n "$FSTAB" ]]; then
                   CHROOT_wrt_CopyFstab
                 else
                   CHROOT_wrt_RunAsRoot  "${file}"
                 fi
        ;;
      *)  CHROOT_wrt_RunAsRoot  "${file}"
        ;;
    esac
    #
    # Housekeeping...remove any build directory(ies) except if the package build fails.
    [[ "$pkg_tarball" != "" ]] && CHROOT_wrt_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script

  done

  # Add SBU-disk_usage report target if required
  if [[ "$REPORT" = "y" ]] ; then wrt_report ; fi

}

#--------------------------------------#
boot_bootable_Makefiles() {            #
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) make bootable   ( ROOT ) ${R_arrow}"

  for file in {bootable,the-end}/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # A little housekeeping on the scripts
    case $this_script in
      *grub | *aboot | *colo | *silo | *arcload | *lilo | *reboot* )  continue  ;;
      *kernel) # if there is no kernel config file do not build the kernel
               [[ -z $CONFIG ]] && continue
                 # Copy the named config file to /sources with a standardized name
               cp $CONFIG $BUILDDIR/sources/kernel-config
         ;;
    esac
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    bootabletools="$bootabletools $this_script"
    #
    # Grab the name of the target, strip id number and misc words.
    case $this_script in
      *kernel) name=linux  ;;
      *)       name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' -e 's@-build@@' ` ;;
    esac

    pkg_tarball=$(get_package_tarball_name $name)

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    BOOT_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    [[ "$pkg_tarball" != "" ]] && BOOT_wrt_Unpack "$pkg_tarball"
    #
    # Select a script execution method
    case $this_script in
      *fstab*)  if [[ -n "$FSTAB" ]]; then
                  # Minimal boot mode has no access to original file, store in /sources
                  cp $FSTAB $BUILDDIR/sources/fstab
                  BOOT_wrt_CopyFstab "${this_script}"
                else
                  BOOT_wrt_RunAsRoot  "${this_script}" "${file}"
                fi
          ;;
      *)  BOOT_wrt_RunAsRoot  "${this_script}" "${file}"   ;;
    esac
    #
    # Housekeeping...remove any build directory(ies) except if the package build fails.
    [[ "$pkg_tarball" != "" ]] && BOOT_wrt_RemoveBuildDirs "${name}"
    #
    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#
    #
    # Keep the script file name for Makefile dependencies.
    PREV=$this_script
  done

  # Add SBU-disk_usage report target if required
  if [[ "$REPORT" = "y" ]] ; then wrt_report ; fi


}


#--------------------------------------#
build_Makefile() {                     # Construct a Makefile from the book scripts
#--------------------------------------#
  #
  # Script crashes if error trapping is on
  #
set +e
  declare -f  method_cmds
  declare -f  testsuite_cmds
  declare -f  final_sys_cmds
  declare -f  bootscripts_cmds
  declare -f  bootable_cmds
set -e

  echo "...Creating Makefile... ${BOLD}START${OFF}"

  cd $JHALFSDIR/${PROGNAME}-commands
  # Start with a clean files
  >$MKFILE
  >$MKFILE.tmp

       method_cmds=${METHOD}_Makefiles
    testsuite_cmds=${METHOD}_testsuite_tools_Makefiles
    final_sys_cmds=${METHOD}_final_system_Makefiles
  bootscripts_cmds=${METHOD}_bootscripts_Makefiles
     bootable_cmds=${METHOD}_bootable_Makefiles
  
  host_prep_Makefiles        # mk_SETUP      (SETUP)  $host_prep
  cross_tools_Makefiles      # mk_CROSS      (LUSER)  $cross_tools
  temptools_Makefiles        # mk_TEMP       (LUSER)  $temptools
  $method_cmds               # mk_SYSTOOLS   (CHROOT) $chroottools/$boottools
  if [[ ! $TEST = "0" ]]; then
    $testsuite_cmds          # mk_SYSTOOLS   (CHROOT) $testsuitetools
  fi
  $final_sys_cmds            # mk_FINAL      (CHROOT) $basicsystem
    # Add the iterations targets, if needed
  [[ "$COMPARE" = "y" ]] && wrt_compare_targets
  $bootscripts_cmds          # mk_BOOTSCRIPT (CHROOT) $bootscripttools
  $bootable_cmds             # mk_BOOTABLE   (CHROOT) $bootabletools

  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
(
    cat << EOF
$HEADER

SRC          = /sources
MOUNT_PT     = $BUILDDIR
PKG_LST      = $PKG_LST
LUSER        = $LUSER
LGROUP       = $LGROUP
SCRIPT_ROOT  = $SCRIPT_ROOT

BASEDIR      = \$(MOUNT_PT)
SRCSDIR      = \$(BASEDIR)/sources
CMDSDIR      = \$(BASEDIR)/\$(SCRIPT_ROOT)/$PROGNAME-commands
LOGDIR       = \$(BASEDIR)/\$(SCRIPT_ROOT)/logs
TESTLOGDIR   = \$(BASEDIR)/\$(SCRIPT_ROOT)/test-logs

crSRCSDIR    = /sources
crCMDSDIR    = /\$(SCRIPT_ROOT)/$PROGNAME-commands
crLOGDIR     = /\$(SCRIPT_ROOT)/logs
crTESTLOGDIR = /\$(SCRIPT_ROOT)/test-logs

SU_LUSER     = su - \$(LUSER) -c
LUSER_HOME   = /home/\$(LUSER)
PRT_DU       = echo -e "\nKB: \`du -skx --exclude=jhalfs \$(MOUNT_PT)\`\n"
PRT_DU_CR    = echo -e "\nKB: \`du -skx --exclude=\$(SCRIPT_ROOT) / \`\n"

include makefile-functions

EOF
) > $MKFILE

  # Add chroot commands
  if [ "$METHOD" = "chroot" ] ; then
    CHROOT_LOC="`whereis -b chroot | cut -d " " -f2`"
    chroot=`cat chroot/*chroot* | \
            sed  -e "s@chroot@$CHROOT_LOC@" \
                 -e '/#!\/tools\/bin\/bash/d' \
                 -e '/^export/d' \
                 -e '/^logout/d' \
                 -e 's@ \\\@ @g' | \
            tr -d '\n' |  \
            sed -e 's/  */ /g' \
                -e 's|\\$|&&|g' \
                -e 's|exit||g' \
                -e 's|$| -c|' \
                -e 's|"$$CLFS"|$(MOUNT_PT)|'\
                -e 's|set -e||'`
    echo -e "CHROOT1= $chroot\n" >> $MKFILE
  fi

################## CHROOT ####################

if [[ "${METHOD}" = "chroot" ]]; then
(
cat << EOF

all: ck_UID mk_SETUP mk_CROSS mk_TEMP mk_SUDO mk_SYSTOOLS mk_FINAL mk_BOOTSCRIPT mk_BOOTABLE
	@sudo make do-housekeeping
	@\$(call echo_finished,$VERSION)

ck_UID:
	@if [ \`id -u\` = "0" ]; then \\
	  echo "--------------------------------------------------"; \\
	  echo "You cannot run this makefile from the root account"; \\
	  echo "--------------------------------------------------"; \\
	  exit 1; \\
	fi

#---------------AS ROOT
mk_SETUP:
	@\$(call echo_SU_request)
	@sudo make SETUP
	@touch \$@
	
#---------------AS LUSER
mk_CROSS: mk_SETUP
	@\$(call echo_PHASE,Cross Tool)
	@(sudo \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make CROSS" )
	@touch \$@

mk_TEMP: mk_CROSS
	@\$(call echo_PHASE,Temporary Tools)
	@(sudo  \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make TEMP" )
	@sudo make restore-luser-env
	@touch \$@

mk_SUDO: mk_TEMP
	@sudo make SUDO
	@touch \$@
#
# The convoluted piece of code below is necessary to provide 'make' with a valid shell in the
# chroot environment. (Unless someone knows a different way)
# Manually create the /bin directory and provide link to the /tools dir.
# Also change the original symlink creation to include (f)orce to prevent failure due to 
#  pre-existing links.

#---------------CHROOT JAIL
mk_SYSTOOLS: mk_SUDO 
	@if [ ! -e \$(MOUNT_PT)/bin ]; then \\
	  mkdir \$(MOUNT_PT)/bin; \\
	  cd \$(MOUNT_PT)/bin && \\
	  ln -svf /tools/bin/bash bash; ln -sf bash sh; \\
	fi;
	@sudo sed -e 's|^ln -sv|ln -svf|' -i \$(CMDSDIR)/chroot/082-createfiles
	@\$(call echo_CHROOT_request)
	@\$(call echo_PHASE, Chroot systools)
	@( sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make SYSTOOLS")
	@touch \$@

mk_FINAL: mk_SYSTOOLS
	@\$(call echo_PHASE,Final System)
	@( sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make FINAL")
	@touch \$@

mk_BOOTSCRIPT: mk_FINAL
	@\$(call echo_PHASE,Bootscript)
	@\$(call echo_CHROOT_request)
	@( sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make BOOTSCRIPT")
	@touch \$@

mk_BOOTABLE: mk_BOOTSCRIPT
	@\$(call echo_PHASE, Make bootable )
	@( sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make BOOTABLE")
	@touch \$@

EOF
) >> $MKFILE
fi

################### BOOT #####################

if [[ "${METHOD}" = "boot" ]]; then
(
cat << EOF

all:	ck_UID mk_SETUP mk_CROSS mk_TEMP mk_SYSTOOLS mk_SUDO
	@sudo make restore-luser-env
	@\$(call echo_boot_finished,$VERSION)

makesys: mk_FINAL mk_BOOTSCRIPT mk_BOOTABLE
	@\$(call echo_finished,$VERSION)


ck_UID:
	@if [ \`id -u\` = "0" ]; then \\
	  echo "--------------------------------------------------"; \\
	  echo "You cannot run this makefile from the root account"; \\
	  echo "--------------------------------------------------"; \\
	  exit 1; \\
	fi

#---------------AS ROOT

mk_SETUP:
	@\$(call echo_SU_request)
	@sudo make SETUP
	@touch \$@

#---------------AS LUSER
	
mk_CROSS: mk_SETUP
	@\$(call echo_PHASE,Cross Tool)
	@(sudo \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make CROSS" )
	@touch \$@

mk_TEMP: mk_CROSS
	@\$(call echo_PHASE,Temporary Tools)
	@(sudo \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make TEMP" )
	@touch \$@

mk_SYSTOOLS: mk_TEMP
	@\$(call echo_PHASE,Minimal Boot system)
	@(sudo \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make SYSTOOLS" )
	@touch \$@

mk_SUDO: mk_SYSTOOLS
	@sudo make SUDO
	@touch \$@

#---------------AS ROOT

mk_FINAL:
	@\$(call echo_PHASE,Final System)
	@( make FINAL )
	@touch \$@

mk_BOOTSCRIPT: mk_FINAL
	@\$(call echo_PHASE,Bootscript)
	@( make BOOTSCRIPT )
	@touch \$@

mk_BOOTABLE: mk_BOOTSCRIPT
	@\$(call echo_PHASE,Making Bootable)
	@( make BOOTABLE )
	@touch \$@

EOF
) >> $MKFILE
fi

(
 cat << EOF

SETUP:      $host_prep
CROSS:      $cross_tools
TEMP:       $temptools
SUDO:	    $orphan_scripts
SYSTOOLS:   ${chroottools}${boottools}
FINAL:      $testsuitetools $basicsystem
BOOTSCRIPT: $bootscripttools
BOOTABLE:   $bootabletools

restart:
	@echo "This feature does not exist for the CLFS makefile. (yet)"

restore-luser-env:
	@\$(call echo_message, Building)
	@if [ -f /home/\$(LUSER)/.bashrc.XXX ]; then \\
		mv -f /home/\$(LUSER)/.bashrc.XXX /home/\$(LUSER)/.bashrc; \\
	fi;
	@if [ -f /home/\$(LUSER)/.bash_profile.XXX ]; then \\
		mv /home/\$(LUSER)/.bash_profile.XXX /home/\$(LUSER)/.bash_profile; \\
	fi;
	@chown \$(LUSER):\$(LGROUP) /home/\$(LUSER)/.bash* && \\
	touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

do-housekeeping:
	@-umount \$(MOUNT_PT)/dev/pts
	@-umount \$(MOUNT_PT)/dev/shm
	@-umount \$(MOUNT_PT)/dev
	@-umount \$(MOUNT_PT)/sys
	@-umount \$(MOUNT_PT)/proc
	@-if [ ! -f luser-exist ]; then \\
		userdel \$(LUSER); \\
		rm -rf /home/\$(LUSER); \\
	fi;

########################################################


EOF
) >> $MKFILE

  # Bring over the items from the Makefile.tmp
  cat $MKFILE.tmp >> $MKFILE
  rm $MKFILE.tmp

  echo "Creating Makefile... ${BOLD}DONE${OFF}"
}
