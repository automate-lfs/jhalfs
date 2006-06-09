#!/bin/sh
# $Id$

###################################
###          FUNCTIONS          ###
###################################



#----------------------------#
host_prep_Makefiles() {      # Initialization of the system
#----------------------------#
  local   LFS_HOST

  echo "${tab_}${GREEN}Processing... ${L_arrow}host prep files${R_arrow}"

  # defined here, only for ease of reading
  LFS_HOST="`echo ${MACHTYPE} | sed -e 's/unknown/cross/g' -e 's/-pc-/-cross-/g'`"
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
	touch \$@

024-creatingcrossdir: 023-creatingtoolsdir
	@mkdir -v \$(MOUNT_PT)/cross-tools && \\
	rm -f /cross-tools && \\
	ln -s \$(MOUNT_PT)/cross-tools /
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
		mv /home/lfs/.bashrc /home/lfs/.bashrc.XXX; \\
	fi;
	@if [ -f /home/lfs/.bash_profile  -a ! -f /home/lfs/.bash_profile.XXX ]; then \\
		mv /home/lfs/.bash_profile /home/lfs/.bash_profile.XXX; \\
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
    wrt_target "${this_script}" "$PREV"
    #
    # If $vrs isn't empty, we've got a package...
    #
    [[ "$vrs" != "" ]] && wrt_unpack "$name-$vrs.tar.*"
    #
    wrt_run_as_su "${this_script}" "${file}"
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
    wrt_target "${this_script}" "$PREV"
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and to set the PKGDIR variable.
    #
    [[ "$vrs" != "" ]] && wrt_unpack "$name-$vrs.tar.*"
    [[ "$vrs" != "" ]] && [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    #
    wrt_run_as_su "${this_script}" "${file}"
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
      *grub | *aboot | *colo | *silo | *arcload | *lilo )     continue     ;;
      *whatnext*) continue     ;;
      *kernel)    # if there is no kernel config file do not build the kernel
                [[ -z $CONFIG ]] && continue
                  # Copy the config file to /sources with a standardized name
                cp $BOOT_CONFIG $BUILDDIR/sources/bootkernel-config
          ;;
    esac
    #
    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    boottools="$boottools $this_script"
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

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    [[ "$vrs" != "" ]] && wrt_unpack "$name-$vrs.tar.*"
    [[ "$vrs" != "" ]] && [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    #
    # Select a script execution method
    case $this_script in
      *changingowner*)  wrt_run_as_root "${this_script}" "${file}"    ;;
      *devices*)        wrt_run_as_root "${this_script}" "${file}"    ;;
      *fstab*)   if [[ -n "$FSTAB" ]]; then
                   wrt_copy_fstab "${this_script}"
                 else
                   wrt_run_as_su  "${this_script}" "${file}"
                 fi
         ;;
      *)         wrt_run_as_su  "${this_script}" "${file}"       ;;
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
chroot_Makefiles() {          #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}chroot${R_arrow}"

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
    chroottools="$chroottools $this_script"

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    if [ "$vrs" != "" ] ; then
      case $this_script in
        *util-linux)    wrt_unpack  "$name-$vrs.tar.*"  ;;
        *)              wrt_unpack2 "$name-$vrs.tar.*"  ;;
      esac
      [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi
    #
    # Select a script execution method
    case $this_script in
      *kernfs)        wrt_run_as_root    "${this_script}" "${file}"  ;;
      *util-linux)    wrt_run_as_su     "${this_script}" "${file}"  ;;
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
  echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) testsuite tools${R_arrow}"

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
    wrt_target "${this_script}" "$PREV"
    #
    case $name in
      tcl)    wrt_unpack2 "$name$vrs-src.tar.*" ;;
      *)      wrt_unpack2 "$name-$vrs.tar.*"    ;;
    esac
    [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
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
  echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) testsuite tools${R_arrow}"

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

    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"
    #
    case $name in
      tcl)    wrt_unpack3 "$name$vrs-src.tar.*" ;;
      *)      wrt_unpack3 "$name-$vrs.tar.*"    ;;
    esac
    [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
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
    # Fix how Module-Init-Tools do the install target
    sed -e 's@make install@make INSTALL=install install@' -i final-system$N/*-module-init-tools
    # Delete *old Readline libraries just after make install
    sed -e 's@make install@&\nrm -v /lib/lib{history,readline}*old@' -i final-system$N/*-readline
  fi

  echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) final system$N${R_arrow}"

  for file in final-system$N/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Test if the stripping phase must be skipped.
    # Skip alsp temp-perl for iterative runs
    case $this_script in
      *stripping*) [[ "$STRIP" = "0" ]] && continue ;;
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
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    if [[ "$vrs" = "" ]] && [[ -n "$N" ]] ; then
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
    wrt_target "${this_script}${N}" "$PREV"

    # If $vrs isn't empty, we've got a package...
    if [ "$vrs" != "" ] ; then
      FILE="$name-$vrs.tar.*"
      wrt_unpack2 "$FILE"
      # If the testsuites must be run, initialize the log file
      case $name in
        binutils | gcc | glibc )
          [[ "$TEST" != "0" ]] && wrt_test_log2 "${this_script}"
          ;;
        * )
          [[ "$TEST" = "2" ]] || [[ "$TEST" = "3" ]] && wrt_test_log2 "${this_script}"
          ;;
      esac
      # If using optimizations, write the instructions
      [[ "$OPTIMIZE" != "0" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
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
    PREV=${this_script}${N}
    # Set system_build envar for iteration targets
    system_build=$basicsystem
  done  # for file in final-system/* ...
}


#-----------------------------#
bm_final_system_Makefiles() { #
#-----------------------------#
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
    # Fix how Module-Init-Tools do the install target
    sed -e 's@make install@make INSTALL=install install@' -i final-system$N/*-module-init-tools
    # Delete *old Readline libraries just after make install
    sed -e 's@make install@&\nrm -v /lib/lib{history,readline}*old@' -i final-system$N/*-readline
  fi

  echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) final system$N${R_arrow}"

  for file in final-system$N/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Test if the stripping phase must be skipped
    # Skip alsp temp-perl for iterative runs
    case $this_script in
      *stripping*) [[ "$STRIP" = "0" ]] && continue ;;
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
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    if [[ "$vrs" = "" ]] && [[ -n "$N" ]] ; then
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
    wrt_target "${this_script}${N}" "$PREV"

    # If $vrs isn't empty, we've got a package...
    if [ "$vrs" != "" ] ; then
      FILE="$name-$vrs.tar.*"
      wrt_unpack3 "$FILE"
      # If the testsuites must be run, initialize the log file
      case $name in
        binutils | gcc | glibc )
          [[ "$TEST" != "0" ]] && wrt_test_log2 "${this_script}"
          ;;
        * )
          [[ "$TEST" = "2" ]] || [[ "$TEST" = "3" ]] && wrt_test_log2 "${this_script}"
          ;;
      esac
      # If using optimizations, write the instructions
      [[ "$OPTIMIZE" != "0" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
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
    PREV=${this_script}${N}
    # Set system_build envar for iteration targets
    system_build=$basicsystem
  done  # for file in final-system/* ...
}


#-----------------------------#
bootscripts_Makefiles() {     #
#-----------------------------#
    echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) bootscripts${R_arrow}"

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
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"
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
    echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) bootscripts${R_arrow}"

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

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'\
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`
    case $name in
      *bootscripts*) name=bootscripts-cross-lfs
       ;;
    esac
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"
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
  echo "${tab_}${GREEN}Processing... ${L_arrow}(chroot) make bootable${R_arrow}"

  for file in {bootable,the-end}/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # A little housekeeping on the scripts
    case $this_script in
      *grub | *aboot | *colo | *silo | *arcload | *lilo | *reboot* )  continue ;;
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
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    [[ "$vrs" != "" ]] && wrt_unpack2 "$name-$vrs.tar.*"
    #
    # Select a script execution method
    case $this_script in
      *fstab*)  if [[ -n "$FSTAB" ]]; then
                  wrt_copy_fstab "${this_script}"
                else
                  wrt_run_as_chroot1  "${this_script}" "${file}"
                fi
          ;;
      *)  wrt_run_as_chroot1  "${this_script}" "${file}"   ;;
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

  # Add SBU-disk_usage report target if required
  if [[ "$REPORT" = "1" ]] ; then wrt_report ; fi

}



#-----------------------------#
bm_bootable_Makefiles() {     #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}(boot) make bootable${R_arrow}"

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
    wrt_target "${this_script}" "$PREV"
    #
    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    #
    [[ "$vrs" != "" ]] && wrt_unpack3 "$name-$vrs.tar.*"
    #
    # Select a script execution method
    case $this_script in
      *fstab*)  if [[ -n "$FSTAB" ]]; then
                  # Minimal boot mode has no access to original file, store in /sources
                  cp $FSTAB $BUILDDIR/sources/fstab
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

  # Add SBU-disk_usage report target if required
  if [[ "$REPORT" = "1" ]] ; then wrt_report ; fi

}


#-----------------------------#
build_Makefile() {            # Construct a Makefile from the book scripts
#-----------------------------#
  echo "Creating Makefile... ${BOLD}START${OFF}"

  cd $JHALFSDIR/${PROGNAME}-commands
  # Start with a clean Makefile.tmp file
  >$MKFILE.tmp

  host_prep_Makefiles
  cross_tools_Makefiles            # $cross_tools
  temptools_Makefiles              # $temptools
  if [[ $METHOD = "chroot" ]]; then
    chroot_Makefiles               # $chroottools
    if [[ ! $TEST = "0" ]]; then
      testsuite_tools_Makefiles    # $testsuitetools
    fi
    final_system_Makefiles         # $basicsystem
    # Add the iterations targets, if needed
    [[ "$COMPARE" != "0" ]] && wrt_compare_targets
    bootscripts_Makefiles          # $bootscripttools
    bootable_Makefiles             # $bootabletools
  else
    boot_Makefiles                 # $boottools
    if [[ ! $TEST = "0" ]]; then
      bm_testsuite_tools_Makefiles # $testsuitetools
    fi
    bm_final_system_Makefiles      # $basicsystem
    # Add the iterations targets, if needed
    [[ "$COMPARE" != "0" ]] && wrt_compare_targets
    bm_bootscripts_Makefiles       # $bootscipttools
    bm_bootable_Makefiles          # $bootabletoosl
  fi
#  the_end_Makefiles


  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
(
    cat << EOF
$HEADER

SRC= /sources
MOUNT_PT= $BUILDDIR
PKG_LST= $PKG_LST

include makefile-functions

EOF
) > $MKFILE

  # Add chroot commands
  if [ "$METHOD" = "chroot" ] ; then
    chroot=`cat chroot/*chroot* | sed -e '/#!\/tools\/bin\/bash/d' \
                            -e '/^export/d' \
                            -e '/^logout/d' \
                            -e 's@ \\\@ @g' | tr -d '\n' |  sed -e 's/  */ /g' \
                                                                -e 's|\\$|&&|g' \
                                                                -e 's|exit||g' \
                                                                -e 's|$| -c|' \
                                                                -e 's|"$$LFS"|$(MOUNT_PT)|'\
                                                                -e 's|set -e||'`
    echo -e "CHROOT1= $chroot\n" >> $MKFILE
  fi

  # Drop in the main target 'all:' and the chapter targets with each sub-target
  # as a dependency.
if [[ "${METHOD}" = "chroot" ]]; then
(
	cat << EOF
all:  chapter2 chapter3 chapter4 chapter5 chapter6 chapter7 chapter8 do-housekeeping
	@\$(call echo_finished,$VERSION)

chapter2:  023-creatingtoolsdir 024-creatingcrossdir 025-addinguser 026-settingenvironment

chapter3:  chapter2 $cross_tools

chapter4:  chapter3 $temptools

chapter5:  chapter4 $chroottools $testsuitetools

chapter6:  chapter5 $basicsystem

chapter7:  chapter6 $bootscripttools

chapter8:  chapter7 $bootabletools

clean-all:  clean
	rm -rf ./{clfs-commands,logs,Makefile,*.xsl,makefile-functions,packages,patches}

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
		mv -f /home/lfs/.bashrc.XXX /home/lfs/.bashrc; \\
	fi;
	@if [ -f /home/lfs/.bash_profile.XXX ]; then \\
		mv /home/lfs/.bash_profile.XXX /home/lfs/.bash_profile; \\
	fi;
	@chown lfs:lfs /home/lfs/.bash* && \\
	touch \$@

do-housekeeping:
	-umount \$(MOUNT_PT)/dev/pts
	-umount \$(MOUNT_PT)/dev/shm
	-umount \$(MOUNT_PT)/dev
	-umount \$(MOUNT_PT)/sys
	-umount \$(MOUNT_PT)/proc
	-if [ ! -f user-lfs-exist ]; then \\
		userdel lfs; \\
		rm -rf /home/lfs; \\
	fi;

EOF
) >> $MKFILE
fi


if [[ "${METHOD}" = "boot" ]]; then
(
	cat << EOF

all:	makeboot

makeboot: 023-creatingtoolsdir 024-creatingcrossdir 025-addinguser 026-settingenvironment \
	$cross_tools\
	$temptools \
	$chroottools \
	$boottools
	@\$(call echo_boot_finished,$VERSION)

makesys:  $testsuitetools $basicsystem $bootscripttools $bootabletools
	@\$(call echo_finished,$VERSION)


clean-all:  clean
	rm -rf ./{clfs-commands,logs,Makefile,*.xsl,makefile-functions,packages,patches}

clean:  clean-makesys clean-makeboot clean-jhalfs

clean-jhalfs:
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

clean-makeboot:
	rm -rf /tools/*
	rm -f $cross_tools && rm -f $temptools && rm -f $chroottools && rm -f $boottools
	rm -f restore-lfs-env sources-dir
	cd logs && rm -f $cross_tools && rm -f $temptools && rm -f $chroottools && rm -f $boottools && cd ..

clean-makesys:
	-umount \$(MOUNT_PT)/sys
	-umount \$(MOUNT_PT)/proc
	-umount \$(MOUNT_PT)/dev/shm
	-umount \$(MOUNT_PT)/dev/pts
	-umount \$(MOUNT_PT)/dev
	rm -rf \$(MOUNT_PT)/{bin,boot,dev,etc,home,lib,lib64,media,mnt,opt,proc,root,sbin,srv,sys,tmp,usr,var}
	rm -f $basicsystem
	rm -f $bootscripttools
	rm -f $bootabletools
	cd logs && rm -f $basicsystem && rm -f $bootscripttools && rm -f $bootabletools && cd ..


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
fi

  # Bring over the items from the Makefile.tmp
  cat $MKFILE.tmp >> $MKFILE
  rm $MKFILE.tmp
  echo "Creating Makefile... ${BOLD}DONE${OFF}"

}

