#!/bin/bash
# $Id$


orphan_scripts="" # 2 scripts do not fit BOOT_Makefiles LUSER environment


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
	ln -s \$(MOUNT_PT)/tools / && \\
	touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

024-creatingcrossdir: 023-creatingtoolsdir
	@\$(call echo_message, Building)
	@mkdir -v \$(MOUNT_PT)/cross-tools && \\
	rm -f /cross-tools && \\
	ln -s \$(MOUNT_PT)/cross-tools / && \\
	touch \$@ && \\
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
	@chown \$(LUSER) \$(MOUNT_PT)/tools && \\
	chown \$(LUSER) \$(MOUNT_PT)/cross-tools && \\
	chmod -R a+wt \$(MOUNT_PT)/\$(SCRIPT_ROOT) && \\
	chmod a+wt \$(SRCSDIR) && \\
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
      CHROOT_Unpack "$pkg_tarball"
      [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi
    #
    # Select a script execution method
    case $this_script in
      *kernfs)      wrt_RunAsRoot         "${file}"  ;;
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
      *changingowner*)  wrt_RunAsRoot "${file}"    ;;
      *devices*)        wrt_RunAsRoot "${file}"    ;;
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
testsuite_tools_Makefiles() {          #
#--------------------------------------#

  if [[ "${METHOD}" = "chroot" ]]; then
    echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) testsuite tools  ( CHROOT ) ${R_arrow}"
  else
    echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) testsuite tools ( ROOT ) ${R_arrow}"
    PREV=""
  fi

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
final_system_Makefiles() {             #
#--------------------------------------#
  # Set envars and scripts for iteration targets
  if [[ -z "$1" ]] ; then
    local N=""
    # In boot method the makesys phase was initiated in testsuite_tools_makefile
    [[ "${METHOD}" = "boot" ]] && [[ "$TEST" = 0 ]] && PREV=""
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
      # Rename the scripts
      mv ${script} ${script}$N
    done
    # Remove Bzip2 binaries before make install
    sed -e 's@make install@rm -vf /usr/bin/bz*\n&@' -i final-system$N/*-bzip2$N
    # Delete *old Readline libraries just after make install
    sed -e 's@make install@&\nrm -v /lib/lib{history,readline}*old@' -i final-system$N/*-readline$N
  fi

  if [[ "${METHOD}" = "chroot" ]]; then
    echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) final system$N ( CHROOT ) ${R_arrow}"
  else
    echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) final system$N  ( ROOT ) ${R_arrow}"
  fi

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
                                  -e 's@n32@@' \
                                  -e 's,'$N',,'`

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
    basicsystem="$basicsystem ${this_script}"

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    CHROOT_wrt_target "${this_script}" "$PREV"

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
    PREV=${this_script}
    # Set system_build envar for iteration targets
    system_build=$basicsystem
  done  # for file in final-system/* ...
}

#--------------------------------------#
bootscripts_Makefiles() {              #
#--------------------------------------#

  if [[ "${METHOD}" = "chroot" ]]; then
    echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) bootscripts   ( CHROOT ) ${R_arrow}"
  else
    echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) bootscripts     ( ROOT ) ${R_arrow}"
  fi

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
bootable_Makefiles() {                 #
#--------------------------------------#

  if [[ "${METHOD}" = "chroot" ]]; then
    echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) make bootable ( CHROOT ) ${R_arrow}"
  else
    echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) make bootable   ( ROOT ) ${R_arrow}"
  fi


  for file in bootable/* ; do
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

}


#--------------------------------------#
build_Makefile() {                     # Construct a Makefile from the book scripts
#--------------------------------------#
  #
  # Script crashes if error trapping is on
  #
set +e
  declare -f  method_cmds
set -e

  echo "...Creating Makefile... ${BOLD}START${OFF}"

  cd $JHALFSDIR/${PROGNAME}-commands
  # Start with a clean files
  >$MKFILE
  >$MKFILE.tmp

  method_cmds=${METHOD}_Makefiles

  host_prep_Makefiles        # mk_SETUP      (SETUP)  $host_prep
  cross_tools_Makefiles      # mk_CROSS      (LUSER)  $cross_tools
  temptools_Makefiles        # mk_TEMP       (LUSER)  $temptools
  $method_cmds               # mk_SYSTOOLS   (CHROOT) $chroottools/$boottools
  if [[ ! $TEST = "0" ]]; then
    testsuite_tools_Makefiles    # mk_SYSTOOLS   (CHROOT) $testsuitetools
  fi
  final_system_Makefiles         # mk_FINAL      (CHROOT) $basicsystem
    # Add the iterations targets, if needed
  [[ "$COMPARE" = "y" ]] && wrt_compare_targets
  bootscripts_Makefiles          # mk_BOOTSCRIPT (CHROOT) $bootscripttools
  bootable_Makefiles             # mk_BOOTABLE   (CHROOT) $bootabletools

  # Add the CUSTOM_TOOLS targets, if needed
  [[ "$CUSTOM_TOOLS" = "y" ]] && wrt_CustomTools_target
  # Add the BLFS_TOOL targets, if needed
  [[ "$BLFS_TOOL" = "y" ]] && wrt_blfs_tool_targets

  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
  wrt_Makefile_header

  # Add chroot commands
  if [ "$METHOD" = "chroot" ] ; then
    CHROOT_LOC="`whereis -b chroot | cut -d " " -f2`"
    chroot=`cat chroot/*chroot* | \
            sed  -e "s@chroot@$CHROOT_LOC@" \
                 -e '/#!\/bin\/bash/d' \
                 -e '/^export/d' \
                 -e '/^logout/d' \
                 -e 's@ \\\@ @g' | \
            tr -d '\n' |  \
            sed -e 's/  */ /g' \
                -e 's|\\$|&&|g' \
                -e 's|exit||g' \
                -e 's|$| -c|' \
                -e 's|"$${CLFS}"|$(MOUNT_PT)|'\
                -e 's|set -e||' \
                -e 's|set +h||'`
    echo -e "CHROOT1= $chroot\n" >> $MKFILE
  fi

################## CHROOT ####################

if [[ "${METHOD}" = "chroot" ]]; then
(
cat << EOF

all: ck_UID mk_SETUP mk_CROSS mk_SUDO mk_SYSTOOLS create-sbu_du-report mk_CUSTOM_TOOLS mk_BLFS_TOOL
	@sudo make do-housekeeping
	@echo "$VERSION - jhalfs build" > clfs-release && \\
	sudo mv clfs-release \$(MOUNT_PT)/etc
	@\$(call echo_finished,$VERSION)

ck_UID:
	@if [ \`id -u\` = "0" ]; then \\
	  echo "+--------------------------------------------------+"; \\
	  echo "|You cannot run this makefile from the root account|"; \\
	  echo "+--------------------------------------------------+"; \\
	  exit 1; \\
	fi

#---------------AS ROOT
mk_SETUP:
	@\$(call echo_SU_request)
	@sudo make SHELL=/bin/bash SETUP
	@touch \$@

#---------------AS LUSER
mk_CROSS: mk_SETUP
	@\$(call echo_PHASE,Cross and Temporary Tools)
	@(sudo \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make SHELL=/bin/bash AS_LUSER" )
	@sudo make restore-luser-env
	@touch \$@

mk_SUDO: mk_CROSS
	@sudo make SHELL=/bin/bash SUDO
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
	  sudo chown -R 0:0 \$(MOUNT_PT)/bin; \\
	fi;
	@sudo sed -e 's|^ln -sv |ln -svf |' -i \$(CMDSDIR)/chroot/*-createfiles
	@\$(call echo_CHROOT_request)
	@\$(call echo_PHASE, CHROOT JAIL )
	@( sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make CHROOT_JAIL")
	@touch \$@

mk_CUSTOM_TOOLS: create-sbu_du-report
	@if [ "\$(ADD_CUSTOM_TOOLS)" = "y" ]; then \\
	  \$(call echo_PHASE,Building CUSTOM_TOOLS); \\
	  \$(call echo_CHROOT_request); \\
	  sudo mkdir -p ${BUILDDIR}${TRACKING_DIR}; \\
	  (sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make CUSTOM_TOOLS"); \\
	fi;
	@touch \$@

mk_BLFS_TOOL: mk_CUSTOM_TOOLS
	@if [ "\$(ADD_BLFS_TOOLS)" = "y" ]; then \\
	  \$(call echo_PHASE,Building BLFS_TOOL); \\
	  \$(call echo_CHROOT_request); \\
	  sudo mkdir -p $BUILDDIR$TRACKING_DIR; \\
	  sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make BLFS_TOOL"; \\
	fi;
	@touch \$@

SETUP:        $host_prep
AS_LUSER:     $cross_tools $temptools
SUDO:	      $orphan_scripts
CHROOT_JAIL:  ${chroottools} $testsuitetools $basicsystem  $bootscripttools  $bootabletools
CUSTOM_TOOLS: $custom_list
BLFS_TOOL:    $blfs_tool


create-sbu_du-report:  mk_SYSTOOLS
	@\$(call echo_message, Building)
	@if [ "\$(ADD_REPORT)" = "y" ]; then \\
	  ./create-sbu_du-report.sh logs $VERSION; \\
	  \$(call echo_report,$VERSION-SBU_DU-$(date --iso-8601).report); \\
	fi;
	@touch  \$@

do-housekeeping:
	@-umount \$(MOUNT_PT)/dev/pts
	@-umount \$(MOUNT_PT)/dev/shm
	@-umount \$(MOUNT_PT)/dev
	@-umount \$(MOUNT_PT)/sys
	@-umount \$(MOUNT_PT)/proc
	@-rm /tools /cross-tools
	@-if [ ! -f luser-exist ]; then \\
		userdel \$(LUSER); \\
		rm -rf /home/\$(LUSER); \\
	fi;

EOF
) >> $MKFILE

fi

################### BOOT #####################

if [[ "${METHOD}" = "boot" ]]; then
(
cat << EOF

all:	ck_UID mk_SETUP mk_CROSS mk_SUDO
	@sudo make restore-luser-env
	@sudo make do-housekeeping
	@\$(call echo_boot_finished,$VERSION)

makesys: mk_FINAL mk_CUSTOM_TOOLS mk_BLFS_TOOL
	@echo "$VERSION - jhalfs build" > /etc/clfs-release
	@\$(call echo_finished,$VERSION)


ck_UID:
	@if [ \`id -u\` = "0" ]; then \\
	  echo "+--------------------------------------------------+"; \\
	  echo "|You cannot run this makefile from the root account|"; \\
	  echo "|However, if this is the boot environment          |"; \\
	  echo "| the command you are looking for is               |"; \\
	  echo "|   make makesys                                   |"; \\
	  echo "| to finish off the build                          |"; \\
	  echo "+--------------------------------------------------+"; \\
	  exit 1; \\
	fi

#---------------AS ROOT

mk_SETUP:
	@\$(call echo_SU_request)
	@sudo make SHELL=/bin/bash SETUP
	@touch \$@

#---------------AS LUSER

mk_CROSS: mk_SETUP
	@\$(call echo_PHASE,Cross Tool)
	@(sudo \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make SHELL=/bin/bash AS_LUSER" )
	@touch \$@

mk_SUDO: mk_CROSS
	@sudo make SHELL=/bin/bash SUDO
	@touch \$@

#---------------AS ROOT

mk_FINAL:
	@\$(call echo_PHASE,Final System)
	@( source /root/.bash_profile && make AS_ROOT )
	@touch \$@

mk_CUSTOM_TOOLS: mk_FINAL
	@if [ "\$(ADD_CUSTOM_TOOLS)" = "y" ]; then \\
	  mkdir -p ${TRACKING_DIR}; \\
	  \$(call echo_PHASE,Building CUSTOM_TOOLS); \\
	  ( source /root/.bash_profile && make CUSTOM_TOOLS"); \\
	fi;
	@touch \$@

mk_BLFS_TOOL: mk_CUSTOM_TOOLS
	@if [ "\$(ADD_BLFS_TOOLS)" = "y" ]; then \\
	  mkdir -p $TRACKING_DIR; \\
	  \$(call echo_PHASE,Building BLFS_TOOL); \\
	  ( source /root/.bash_profile && make BLFS_TOOL ); \\
	fi
	@touch \$@

SETUP:        $host_prep
AS_LUSER:     $cross_tools $temptools ${boottools}
SUDO:	      $orphan_scripts
AS_ROOT:      $testsuitetools $basicsystem $bootscripttools $bootabletools
CUSTOM_TOOLS: $custom_list
BLFS_TOOL:    $blfs_tool

do-housekeeping:
	@-rm /tools /cross-tools
	@-if [ ! -f luser-exist ]; then \\
		userdel \$(LUSER); \\
		rm -rf /home/\$(LUSER); \\
	fi;

EOF
) >> $MKFILE
fi

(
 cat << EOF

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

########################################################


EOF
) >> $MKFILE

  # Bring over the items from the Makefile.tmp
  cat $MKFILE.tmp >> $MKFILE
  rm $MKFILE.tmp

  echo "Creating Makefile... ${BOLD}DONE${OFF}"
}
