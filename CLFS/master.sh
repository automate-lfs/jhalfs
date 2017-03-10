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
	@install -dv \$(MOUNT_PT)/tools && \\
	rm -f /tools && \\
	ln -s \$(MOUNT_PT)/tools /
	@\$(call housekeeping)

024-creatingcrossdir: 023-creatingtoolsdir
	@\$(call echo_message, Building)
	@install -dv \$(MOUNT_PT)/cross-tools && \\
	rm -f /cross-tools && \\
	ln -s \$(MOUNT_PT)/cross-tools /
	@\$(call housekeeping)

025-addinguser:  024-creatingcrossdir
	@\$(call echo_message, Building)
	@if [ ! -d \$(LUSER_HOME) ]; then \\
	    groupadd \$(LGROUP); \\
	    useradd -s /bin/bash -g \$(LGROUP) -d \$(LUSER_HOME) \$(LUSER); \\
	    mkdir -pv \$(LUSER_HOME); \\
	    chown -v \$(LUSER):\$(LGROUP) \$(LUSER_HOME); \\
	else \\
	    touch luser-exist; \\
	fi
	@chown -v \$(LUSER) \$(MOUNT_PT)/tools && \\
	chown -v \$(LUSER) \$(MOUNT_PT)/cross-tools && \\
	chmod -R a+wt \$(MOUNT_PT)/\$(SCRIPT_ROOT) && \\
	chmod a+wt \$(SRCSDIR)
	@\$(call housekeeping)

026-settingenvironment:  025-addinguser
	@\$(call echo_message, Building)
	@if [ -f \$(LUSER_HOME)/.bashrc -a ! -f \$(LUSER_HOME)/.bashrc.XXX ]; then \\
		mv \$(LUSER_HOME)/.bashrc \$(LUSER_HOME)/.bashrc.XXX; \\
	fi
	@if [ -f \$(LUSER_HOME)/.bash_profile  -a ! -f \$(LUSER_HOME)/.bash_profile.XXX ]; then \\
		mv \$(LUSER_HOME)/.bash_profile \$(LUSER_HOME)/.bash_profile.XXX; \\
	fi;
	@echo "set +h" > \$(LUSER_HOME)/.bashrc && \\
	echo "umask 022" >> \$(LUSER_HOME)/.bashrc && \\
	echo "CLFS=\$(MOUNT_PT)" >> \$(LUSER_HOME)/.bashrc && \\
	echo "LC_ALL=POSIX" >> \$(LUSER_HOME)/.bashrc && \\
	echo "PATH=/cross-tools/bin:/bin:/usr/bin" >> \$(LUSER_HOME)/.bashrc && \\
	echo "export CLFS LC_ALL PATH" >> \$(LUSER_HOME)/.bashrc && \\
	echo "" >> \$(LUSER_HOME)/.bashrc && \\
	echo "unset CFLAGS" >> \$(LUSER_HOME)/.bashrc && \\
	echo "unset CXXFLAGS" >> \$(LUSER_HOME)/.bashrc && \\
	echo "unset PKG_CONFIG_PATH" >> \$(LUSER_HOME)/.bashrc && \\
	echo "" >> \$(LUSER_HOME)/.bashrc && \\
EOF
) >> $MKFILE.tmp
if ! [ -e final-preps/*variables ]; then
  (
  cat << EOF
	echo "export CLFS_HOST=\"${CLFS_HOST}\"" >> \$(LUSER_HOME)/.bashrc && \\
	echo "export CLFS_TARGET=\"${TARGET}\"" >> \$(LUSER_HOME)/.bashrc && \\
	echo "export CLFS_TARGET32=\"${TARGET32}\"" >> \$(LUSER_HOME)/.bashrc && \\
EOF
  ) >> $MKFILE.tmp
fi
(
cat << EOF
	echo "source $JHALFSDIR/envars" >> \$(LUSER_HOME)/.bashrc
	@chown \$(LUSER):\$(LGROUP) \$(LUSER_HOME)/.bashrc && \\
	chmod a+wt \$(MOUNT_PT) && \\
	if [ -d \$(MOUNT_PT)/var ]; then \\
	  chown -R \$(LUSER) \$(MOUNT_PT)/var; \\
	fi && \\
	touch envars && \\
	chown \$(LUSER):\$(LGROUP) envars
	@\$(call housekeeping)
EOF
) >> $MKFILE.tmp
  host_prep=" 023-creatingtoolsdir 024-creatingcrossdir 026-settingenvironment"

}

#--------------------------------------#
final_preps_Makefiles() {
#--------------------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}variables  ( LUSER ) ${R_arrow}"
  for file in final-preps/* ; do
    this_script=`basename $file`
    case $this_script in
      *variables )
         ;;
      *) continue; ;;
    esac
    # Set the dependency for the first target.
    if [ -z $PREV ] ; then PREV=026-settingenvironment ; fi

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    final_preps="$final_preps $this_script"

    # No need to grab the package name

    LUSER_wrt_target "${this_script}" "$PREV"
    LUSER_wrt_RunAsUser "${file}"
    wrt_touch
    PREV=$this_script
  done # for file in ....
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
                                  -e 's@-n32@@' \
                                  -e 's@-pass1@@'`
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
    [[ "$pkg_tarball" != "" ]] && [[ "$OPTIMIZE" = 3 ]] && wrt_makeflags "${name}"
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
    [[ "$pkg_tarball" != "" ]] && [[ "$OPTIMIZE" -ge "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
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
      *kernfs)     orphan_scripts="${orphan_scripts} ${this_script}"  ;;
      *)           chroottools="$chroottools $this_script"            ;;
    esac

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`

    pkg_tarball=$(get_package_tarball_name $name)

    # This is very ugly:: util-linux is in /chroot but must be run under LUSER
    # Same for e2fsprogs (in CLFS 1.1.0)
    # .. Customized makefile entry
    case "${this_script}" in
      *util-linux)
         LUSER_wrt_target "${this_script}" "$PREV"
         LUSER_wrt_unpack "$pkg_tarball"
         [[ "$OPTIMIZE" -ge "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
         LUSER_wrt_RunAsUser "${file}"
         LUSER_RemoveBuildDirs "${name}"
         wrt_touch
         temptools="$temptools $this_script"
         continue ;;
      *util-linux-ng)
         LUSER_wrt_target "${this_script}" "$PREV"
         LUSER_wrt_unpack "$pkg_tarball"
         [[ "$OPTIMIZE" -ge "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
         LUSER_wrt_RunAsUser "${file}"
         LUSER_RemoveBuildDirs "${name}"
         wrt_touch
         temptools="$temptools $this_script"
         continue ;;
      *util-linux-libs)
         LUSER_wrt_target "${this_script}" "$PREV"
         LUSER_wrt_unpack "$pkg_tarball"
         [[ "$OPTIMIZE" -ge "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
         LUSER_wrt_RunAsUser "${file}"
         LUSER_RemoveBuildDirs "${name}"
         wrt_touch
         temptools="$temptools $this_script"
         continue ;;
      *e2fsprogs)
         LUSER_wrt_target "${this_script}" "$PREV"
         LUSER_wrt_unpack "$pkg_tarball"
         [[ "$OPTIMIZE" -ge "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
         LUSER_wrt_RunAsUser "${file}"
         LUSER_RemoveBuildDirs "${name}"
         wrt_touch
         temptools="$temptools $this_script"
         continue ;;
      *e2fsprogs-libs)
         LUSER_wrt_target "${this_script}" "$PREV"
         LUSER_wrt_unpack "$pkg_tarball"
         [[ "$OPTIMIZE" -ge "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
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
      [[ "$OPTIMIZE" -ge "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
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
      *grub | *aboot | *colo | *silo | *arcload | *lilo | *introduction ) continue ;;
      *how-to-view*) continue  ;;
      *whatnext*) continue     ;;
      *fstab)   [[ -z "${FSTAB}" ]] ||
                [[ ${FSTAB} == $BUILDDIR/sources/fstab ]] ||
                cp ${FSTAB} $BUILDDIR/sources/fstab ;;
      *kernel)  # if there is no kernel config file do not build the kernel
                [[ -z $BOOT_CONFIG ]] && continue
                  # Copy the config file to /sources with a standardized name
                [[ ${BOOT_CONFIG} == $BUILDDIR/sources/bootkernel-config ]] ||
                cp $BOOT_CONFIG $BUILDDIR/sources/bootkernel-config
          ;;
    esac
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile). Those names differ depending
    # on the version of the book. What makes the difference between those
    # versions is the presence of "how-to-view" in the boot chapter.
    if [ -f boot/*how-to-view ]; then
      case "${this_script}" in
        *changingowner)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *creatingdirs)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *createfiles)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *devices)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *flags)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *fstab)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *pwdgroup)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *settingenvironment)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *)
           boottools="$boottools $this_script"
           ;;
      esac
    else
      case "${this_script}" in
        *changingowner)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *devices)
           orphan_scripts="${orphan_scripts} ${this_script}"
           ;;
        *)
           boottools="$boottools $this_script"
           ;;
      esac
    fi
    #
    # Grab the name of the target, strip id number and misc words.
    case $this_script in
      *kernel)        name=linux                    ;;
      *bootscripts)   name="bootscripts-cross-lfs"  ;;
      *boot-scripts)  name="boot-scripts-cross-lfs" ;;
      *udev-rules)    name="udev-cross-lfs"         ;;
      *grub-build)    name=grub                     ;;
      *-aboot-build)  name=aboot                    ;;
      *yaboot-build)  name=yaboot                   ;;
      *colo-build)    name=colo                     ;;
      *silo-build)    name=silo                     ;;
      *arcload-build) name=arcload                  ;;
      *lilo-build)    name=lilo                     ;;
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
    [[ "$pkg_tarball" != "" ]] && [[ "$OPTIMIZE" -ge "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    #
    # Select a script execution method
    if [ -f boot/*how-to-view ]; then
      case $this_script in
        # The following 8 scripts are defined in the /boot directory but need
        # to be run as a root user. Set them up here but run them in another
        # phase
        *changingowner)      wrt_RunAsRoot "${file}"    ;;
        *creatingdirs)       wrt_RunAsRoot "${file}"    ;;
        *createfiles)        wrt_RunAsRoot "${file}"    ;;
        *devices)            wrt_RunAsRoot "${file}"    ;;
        *flags)              wrt_RunAsRoot "${file}"    ;;
        *fstab)
           if [[ -n "$FSTAB" ]]; then
               LUSER_wrt_CopyFstab
           else
               wrt_RunAsRoot  "${file}"
           fi
           ;;
        *pwdgroup)           wrt_RunAsRoot "${file}"    ;;
        *settingenvironment) wrt_RunAsRoot "${file}"    ;;
        *)               LUSER_wrt_RunAsUser  "${file}" ;;
      esac
    else
      case $this_script in
        # The following 2 scripts are defined in the /boot directory but need
        # to be run as a root user. Set them up here but run them in another
        # phase
        *changingowner)   wrt_RunAsRoot "${file}"    ;;
        *devices)         wrt_RunAsRoot "${file}"    ;;
        *fstab)
           if [[ -n "${FSTAB}" ]]; then
               LUSER_wrt_CopyFstab
           else
               LUSER_wrt_RunAsUser  "${file}"
           fi
           ;;
        *)            LUSER_wrt_RunAsUser  "${file}" ;;
      esac
    fi
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
    [[ "$OPTIMIZE" -ge "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
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
    # Remove Bzip2 binaries before make install (CLFS-1.0 compatibility)
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
    # Skip also temp-perl for iterative runs
    case $this_script in
      *stripping*) [[ "$STRIP" = "n" ]] && continue ;;
      *temp-perl*) [[ -n "$N" ]] && continue ;;
    esac

    # Grab the name of the target, strip id number, XXX-script.
    # name1 is partially stripped and should be used for logging files.
    # name is completely stripped and is used for grabbing
    # the package name.
    name1=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' \
                                   -e 's,'$N',,'`
    name=`echo $name1 | sed -e 's@temp-@@' \
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
      # Touch timestamp file if installed files logs will be created.
      # But only for the firt build when running iterative builds.
      if [ "${INSTALL_LOG}" = "y" ] && [ "x${N}" = "x" ] ; then
        CHROOT_wrt_TouchTimestamp
      fi
      CHROOT_Unpack "$pkg_tarball"
      # If the testsuites must be run, initialize the log file
      case $name in
        binutils | gcc | glibc | eglibc | gmp | mpfr | mpc | isl | cloog )
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
    # Write installed files log and remove the build directory(ies)
    # except if the package build fails.
    if [ "$pkg_tarball" != "" ] ; then
      CHROOT_wrt_RemoveBuildDirs "$name"
      if [ "${INSTALL_LOG}" = "y" ] && [ "x${N}" = "x" ] ; then
        CHROOT_wrt_LogNewFiles "$name1"
      fi
    fi
    #
    # Include a touch of the target name so make can check
    # if it's already been made.
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

# New versions of the book do not have bootscripts anymore
# (use systemd configuration files)
# Define a variable to be used for the right script directory to parse
  if [ -d bootscripts ]; then
    config="bootscripts"
  else
    config="system-config"
  fi

  if [[ "${METHOD}" = "chroot" ]]; then
    echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) $config   ( CHROOT ) ${R_arrow}"
  else
    echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) $config     ( ROOT ) ${R_arrow}"
  fi

  for file in $config/* ; do
    # Keep the script file name
    this_script=`basename $file`

    case $this_script in
      *udev)     continue ;; # This is not a script but a comment, we want udev-rules
      *console*) continue ;; # Use the files that came with the bootscripts
# fstab is now here (for 3.x.y)
      *fstab)  [[ -z "${FSTAB}" ]] ||
               [[ ${FSTAB} == $BUILDDIR/sources/fstab ]] ||
               cp ${FSTAB} $BUILDDIR/sources/fstab ;;
      *)  ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    bootscripttools="$bootscripttools $this_script"

    # Grab the name of the target, strip id number, XXX-script.
    # name1 is partially stripped and should be used for logging files.
    # name is completely stripped and is used for grabbing
    # the package name.
    name1=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`
    name=`echo $name1 | sed -e 's@-64bit@@' \
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
    if [ "$pkg_tarball" != "" ] ; then
      if [ "${INSTALL_LOG}" = "y" ] ; then
        CHROOT_wrt_TouchTimestamp
      fi
      CHROOT_Unpack "$pkg_tarball"
    fi
    #
    case $this_script in
      *fstab*)   if [[ -n "$FSTAB" ]]; then
                   CHROOT_wrt_CopyFstab
                 else
                   CHROOT_wrt_RunAsRoot  "${file}"
                 fi
        ;;
      *) CHROOT_wrt_RunAsRoot "${file}"
        ;;
    esac
    #
    # Write installed files log and remove the build directory(ies)
    # except if the package build fails.
    if [ "$pkg_tarball" != "" ] ; then
      CHROOT_wrt_RemoveBuildDirs "$name"
      if [ "${INSTALL_LOG}" = "y" ] ; then
        CHROOT_wrt_LogNewFiles "$name1"
      fi
    fi
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
network_Makefiles() {                  #
#--------------------------------------#

  if [[ "${METHOD}" = "chroot" ]]; then
    echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) network   ( CHROOT ) ${R_arrow}"
  else
    echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) network     ( ROOT ) ${R_arrow}"
  fi

  for file in network/* ; do
    # Keep the script file name
    this_script=`basename $file`

    case $this_script in
      *choose)   continue ;; # This is not a script but a commentary. 
      *dhcp)    continue ;; # Assume static networking.
      *dhcpcd)    continue ;; # Assume static networking.
      *)  ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    networktools="$networktools $this_script"

    # Grab the name of the target, strip id number, XXX-script
    # name1 is partially stripped and should be used for logging files.
    # name is completely stripped and is used for grabbing
    # the package name.
    name1=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`
    name=`echo $name1 | sed -e 's@-64bit@@' \
                            -e 's@-64@@' \
                            -e 's@64@@' \
                            -e 's@n32@@'`
    case $name in
      network-scripts) name=clfs-network-scripts ;;
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
    if [ "$pkg_tarball" != "" ] ; then
      if [ "${INSTALL_LOG}" = "y" ] ; then
        CHROOT_wrt_TouchTimestamp
      fi
      CHROOT_Unpack "$pkg_tarball"
    fi
    #
    CHROOT_wrt_RunAsRoot "${file}"
    #
    # Write installed files log and remove the build directory(ies)
    # except if the package build fails.
    if [ "$pkg_tarball" != "" ] ; then
      CHROOT_wrt_RemoveBuildDirs "$name"
      if [ "${INSTALL_LOG}" = "y" ] ; then
        CHROOT_wrt_LogNewFiles "$name1"
      fi
    fi
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

  done  # for file in network/* ...
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
      *fstab)  [[ -z "${FSTAB}" ]] ||
               [[ ${FSTAB} == $BUILDDIR/sources/fstab ]] ||
               cp ${FSTAB} $BUILDDIR/sources/fstab ;;
      *kernel) # if there is no kernel config file do not build the kernel
               [[ -z $CONFIG ]] && continue
                 # Copy the config file to /sources with a standardized name
               [[ $CONFIG == $BUILDDIR/sources/kernel-config ]] ||
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
    if [ "$pkg_tarball" != "" ] ; then
      if [ "${INSTALL_LOG}" = "y" ] ; then
        CHROOT_wrt_TouchTimestamp
      fi
      CHROOT_Unpack "$pkg_tarball"
    fi
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
    # Write installed files log and remove the build directory(ies)
    # except if the package build fails.
    if [ "$pkg_tarball" != "" ] ; then
      CHROOT_wrt_RemoveBuildDirs "$name"
      if [ "${INSTALL_LOG}" = "y" ] ; then
        CHROOT_wrt_LogNewFiles "$name"
      fi
    fi
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

  echo "...Creating Makefile... ${BOLD}START${OFF}"

  cd $JHALFSDIR/${PROGNAME}-commands
  # Start with clean files
  >$MKFILE
  >$MKFILE.tmp

  method_cmds=${METHOD}_Makefiles

  host_prep_Makefiles        # mk_SETUP      (SETUP)  $host_prep
  final_preps_Makefiles      # mk_F_PREPS    (LUSER)  $final_preps
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
  if [ -d network ]; then 
     network_Makefiles           # If present, process network setup.
  fi
  bootable_Makefiles             # mk_BOOTABLE   (CHROOT) $bootabletools

  # Add the CUSTOM_TOOLS targets, if needed
  [[ "$CUSTOM_TOOLS" = "y" ]] && wrt_CustomTools_target

  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
  wrt_Makefile_header

  # Add chroot commands
  if [ "$METHOD" = "chroot" ] ; then
    CHROOT_LOC="`whereis -b chroot | cut -d " " -f2`"
    chroot=`cat chroot/???-chroot | \
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

all: ck_UID mk_SETUP mk_F_PREPS mk_SUDO mk_SYSTOOLS create-sbu_du-report mk_CUSTOM_TOOLS mk_BLFS_TOOL
	@sudo make do-housekeeping
	@echo "$VERSION - jhalfs build" > clfs-release && \\
	sudo mv clfs-release \$(MOUNT_PT)/etc && \\
	sudo chown root:root \$(MOUNT_PT)/etc/clfs-release
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
	@sudo make BREAKPOINT=\$(BREAKPOINT) SETUP
	@touch \$@

#---------------AS LUSER
mk_F_PREPS: mk_SETUP
	@\$(call echo_PHASE,Final Preparations Cross and Temporary Tools)
	@( \$(SU_LUSER) "make -C \$(MOUNT_PT)/\$(SCRIPT_ROOT) BREAKPOINT=\$(BREAKPOINT) AS_LUSER" )
	@sudo make restore-luser-env
	@touch \$@

mk_SUDO: mk_F_PREPS
	@sudo make BREAKPOINT=\$(BREAKPOINT) SUDO
	@touch \$@

#---------------CHROOT JAIL
mk_SYSTOOLS: mk_SUDO
	@\$(call echo_CHROOT_request)
	@\$(call echo_PHASE, CHROOT JAIL )
	@( sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) PREP_CHROOT_JAIL")
	@( sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) CHROOT_JAIL")
	@touch \$@

mk_BLFS_TOOL: create-sbu_du-report
	@if [ "\$(ADD_BLFS_TOOLS)" = "y" ]; then \\
	  \$(call sh_echo_PHASE,Building BLFS_TOOL); \\
	  (sudo \$(CHROOT1) "make -C $BLFS_ROOT/work"); \\
	fi;
	@touch \$@

mk_CUSTOM_TOOLS: mk_BLFS_TOOL
	@if [ "\$(ADD_CUSTOM_TOOLS)" = "y" ]; then \\
	  \$(call sh_echo_PHASE,Building CUSTOM_TOOLS); \\
	  sudo mkdir -p ${BUILDDIR}${TRACKING_DIR}; \\
	  (sudo \$(CHROOT1) "cd \$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) CUSTOM_TOOLS"); \\
	fi;
	@touch \$@

SETUP:            $host_prep
AS_LUSER:         $final_preps $cross_tools $temptools
SUDO:	          $orphan_scripts
PREP_CHROOT_JAIL:  SHELL=/tools/bin/bash
PREP_CHROOT_JAIL: ${chroottools}
CHROOT_JAIL:       SHELL=/tools/bin/bash
CHROOT_JAIL:      $testsuitetools $basicsystem  $bootscripttools  $bootabletools
CUSTOM_TOOLS:     $custom_list


create-sbu_du-report:  mk_SYSTOOLS
	@\$(call echo_message, Building)
	@if [ "\$(ADD_REPORT)" = "y" ]; then \\
	  ./create-sbu_du-report.sh logs $VERSION; \\
	  \$(call echo_report,$VERSION-SBU_DU-$(date --iso-8601).report); \\
	fi;
	@touch  \$@

do-housekeeping:
	@-umount \$(MOUNT_PT)/dev/pts
	@-if [ -h \$(MOUNT_PT)/dev/shm ]; then \\
	  link=\$\$(readlink \$(MOUNT_PT)/dev/shm); \\
	  umount \$(MOUNT_PT)/\$\$link; \\
	  unset link; \\
	else \\
	  umount \$(MOUNT_PT)/dev/shm; \\
	fi
	@-umount \$(MOUNT_PT)/dev
	@-umount \$(MOUNT_PT)/sys
	@-umount \$(MOUNT_PT)/proc
	@-rm /tools /cross-tools
	@-if [ ! -f luser-exist ]; then \\
		userdel \$(LUSER); \\
		rm -rf \$(LUSER_HOME); \\
	fi;

EOF
) >> $MKFILE

fi

################### BOOT #####################

if [[ "${METHOD}" = "boot" ]]; then
(
cat << EOF

all:	ck_UID mk_SETUP mk_F_PREPS mk_SUDO
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
	  echo "| to complete the build                            |"; \\
	  echo "+--------------------------------------------------+"; \\
	  exit 1; \\
	fi

#---------------AS ROOT

mk_SETUP:
	@\$(call echo_SU_request)
	@sudo make BREAKPOINT=\$(BREAKPOINT) SETUP
	@touch \$@

#---------------AS LUSER

mk_F_PREPS: mk_SETUP
	@\$(call echo_PHASE,Final Preparations and Cross Tools)
	@( \$(SU_LUSER) "make -C \$(MOUNT_PT)/\$(SCRIPT_ROOT) BREAKPOINT=\$(BREAKPOINT) AS_LUSER" )
	@touch \$@

mk_SUDO: mk_F_PREPS
	@sudo make BREAKPOINT=\$(BREAKPOINT) SUDO
	@touch \$@

#---------------AS ROOT

mk_FINAL:
	@\$(call echo_PHASE,Final System)
	@( source /root/.bash_profile && make BREAKPOINT=\$(BREAKPOINT) AS_ROOT )
	@touch \$@

mk_BLFS_TOOL: mk_FINAL
	@if [ "\$(ADD_BLFS_TOOLS)" = "y" ]; then \\
	  \$(call sh_echo_PHASE,Building BLFS_TOOL); \\
	  ( make -C $BLFS_ROOT/work ); \\
	fi;
	@touch \$@

mk_CUSTOM_TOOLS: mk_BLFS_TOOL
	@if [ "\$(ADD_CUSTOM_TOOLS)" = "y" ]; then \\
	  \$(call sh_echo_PHASE,Building CUSTOM_TOOLS); \\
	  mkdir -p ${TRACKING_DIR}; \\
	  ( source /root/.bash_profile && make BREAKPOINT=\$(BREAKPOINT) CUSTOM_TOOLS ); \\
	fi;
	@touch \$@

SETUP:        $host_prep
AS_LUSER:     $final_preps $cross_tools $temptools ${boottools}
SUDO:	      $orphan_scripts
AS_ROOT:      SHELL=/tools/bin/bash
AS_ROOT:      $testsuitetools $basicsystem $bootscripttools $bootabletools
CUSTOM_TOOLS: $custom_list

do-housekeeping:
	@-rm /tools /cross-tools
	@-if [ ! -f luser-exist ]; then \\
		userdel \$(LUSER); \\
		rm -rf \$(LUSER_HOME); \\
	fi;

EOF
) >> $MKFILE
fi

(
 cat << EOF

restore-luser-env:
	@\$(call echo_message, Building)
	@if [ -f \$(LUSER_HOME)/.bashrc.XXX ]; then \\
		mv -f \$(LUSER_HOME)/.bashrc.XXX \$(LUSER_HOME)/.bashrc; \\
	fi;
	@if [ -f \$(LUSER_HOME)/.bash_profile.XXX ]; then \\
		mv \$(LUSER_HOME)/.bash_profile.XXX \$(LUSER_HOME)/.bash_profile; \\
	fi;
	@chown \$(LUSER):\$(LGROUP) \$(LUSER_HOME)/.bash* && \\
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
