#!/bin/sh

# $Id$

###################################
###	    FUNCTIONS		###
###################################



#----------------------------#
chapter4_Makefiles() {
#----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter4${R_arrow}"

# If /home/lfs is already present in the host, we asume that the
# lfs user and group are also presents in the host, and a backup
# of their bash init files is made.
(
    cat << EOF
020-creatingtoolsdir:
	@\$(call echo_message, Building)
	@mkdir -v \$(MOUNT_PT)/tools && \\
	rm -fv /tools && \\
	ln -sv \$(MOUNT_PT)/tools / && \\
	touch \$@

021-addinguser:  020-creatingtoolsdir
	@\$(call echo_message, Building)
	@if [ ! -d /home/lfs ]; then \\
		groupadd lfs; \\
		useradd -s /bin/bash -g lfs -m -k /dev/null lfs; \\
	else \\
		touch user-lfs-exist; \\
	fi;
	@chown lfs \$(MOUNT_PT)/tools && \\
	chmod a+wt \$(MOUNT_PT)/sources && \\
	touch \$@

022-settingenvironment:  021-addinguser
	@\$(call echo_message, Building)
	@if [ -f /home/lfs/.bashrc -a ! -f /home/lfs/.bashrc.XXX ]; then \\
		mv -v /home/lfs/.bashrc /home/lfs/.bashrc.XXX; \\
	fi;
	@if [ -f /home/lfs/.bash_profile  -a ! -f /home/lfs/.bash_profile.XXX ]; then \\
		mv -v /home/lfs/.bash_profile /home/lfs/.bash_profile.XXX; \\
	fi;
	@echo "set +h" > /home/lfs/.bashrc && \\
	echo "umask 022" >> /home/lfs/.bashrc && \\
	echo "LFS=/mnt/lfs" >> /home/lfs/.bashrc && \\
	echo "LC_ALL=POSIX" >> /home/lfs/.bashrc && \\
	echo "PATH=/tools/bin:/bin:/usr/bin" >> /home/lfs/.bashrc && \\
	echo "export LFS LC_ALL PATH" >> /home/lfs/.bashrc && \\
	echo "source $JHALFSDIR/envars" >> /home/lfs/.bashrc && \\
	chown lfs:lfs /home/lfs/.bashrc && \\
	touch envars && \\
	touch \$@
EOF
) >> $MKFILE.tmp
}

#----------------------------#
chapter5_Makefiles() {
#----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter5${R_arrow}"

  for file in chapter05/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # If no testsuites will be run, then TCL, Expect and DejaGNU aren't needed
    # Fix also locales creation when running chapter05 testsuites (ugly)
    case "${this_script}" in
      *tcl)       [[ "${TEST}" = "0" ]] && continue ;;
      *expect)    [[ "${TEST}" = "0" ]] && continue ;;
      *dejagnu)   [[ "${TEST}" = "0" ]] && continue ;;
      *stripping) [[ "${STRIP}" = "0" ]] && continue ;;
      *glibc)     [[ "${TEST}" = "3" ]] && \
                  sed -i 's@/usr/lib/locale@/tools/lib/locale@' $file ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    chapter5="$chapter5 ${this_script}"

    # Grab the name of the target (minus the -pass1 or -pass2 in the case of gcc
    # and binutils in chapter 5)
    name=`echo ${this_script} | sed -e 's@[0-9]\{3\}-@@' -e 's@-pass[0-9]\{1\}@@'`

    # Set the dependency for the first target.
    if [ -z $PREV ] ; then PREV=022-settingenvironment ; fi

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"

    # Find the version of the command files, if it corresponds with the building of
    # a specific package
    vrs=`grep "^$name-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`

    # If $vrs isn't empty, we've got a package...
    if [ "$vrs" != "" ] ; then
      if [ "$name" = "tcl" ] ; then
        FILE="$name$vrs-src.tar.*"
      else
        FILE="$name-$vrs.tar.*"
      fi

      # Insert instructions for unpacking the package and to set the PKGDIR variable.
      wrt_unpack "$FILE"
      echo -e '\ttrue' >> $MKFILE.tmp
    fi

    # Insert date and disk usage at the top of the log file, the script run
    # and date and disk usage again at the bottom of the log file.
    # The changingowner script must be run as root.
    case "${this_script}" in
      *changingowner)  wrt_run_as_root    "${this_script}" "$file" ;;
      *)               wrt_run_as_su      "${this_script}" "$file" ;;
    esac

    # Remove the build directory(ies) except if the package build fails
    # (so we can review config.cache, config.log, etc.)
    if [ "$vrs" != "" ] ; then
      wrt_remove_build_dirs "$name"
    fi

    # Include a touch of the target name so make can check
    # if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#

    # Keep the script file name for Makefile dependencies.
    PREV=${this_script}
  done  # end for file in chapter05/*
}

#----------------------------#
chapter6_Makefiles() {
#----------------------------#
  # Set envars and scripts for iteration targets
  if [[ -z "$1" ]] ; then
    local N=""
  else
    local N=-build_$1
    local chapter6=""
    mkdir chapter06$N
    cp chapter06/* chapter06$N
    for script in chapter06$N/* ; do
      # Overwrite existing symlinks, files, and dirs
      sed -e 's/ln -sv/&f/g' \
          -e 's/mv -v/&f/g' \
          -e 's/mkdir -v/&p/g' -i ${script}
    done
    # Remove Bzip2 binaries before make install
    sed -e 's@make install@rm -vf /usr/bin/bz*\n&@' -i chapter06$N/*-bzip2
    # Fix how Module-Init-Tools do the install target
    sed -e 's@make install@make INSTALL=install install@' -i chapter06$N/*-module-init-tools
    # Delete *old Readline libraries just after make install
    sed -e 's@make install@&\nrm -v /lib/lib{history,readline}*old@' -i chapter06$N/*-readline
    # Let some Udev pre-installation commands to fail
    sed -e 's@/lib/udev/devices/fd@& || true@' \
        -e 's/mknod -m.*/& || true/' -i chapter06$N/*-udev
  fi

  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter6$N${R_arrow}"

  for file in chapter06$N/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # We'll run the chroot commands differently than the others, so skip them in the
    # dependencies and target creation.
    case "${this_script}" in
      *chroot)      continue ;;
      *stripping*) [[ "${STRIP}" = "0" ]] && continue ;;
    esac

    # Grab the name of the target
    name=`echo ${this_script} | sed -e 's@[0-9]\{3\}-@@'`

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

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    chapter6="$chapter6 ${this_script}${N}"

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}${N}" "$PREV"

    # If $vrs isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    if [ "$vrs" != "" ] ; then
      FILE="$name-$vrs.tar.*"
      wrt_unpack2 "$FILE"
    fi

    # In the mount of kernel filesystems we need to set LFS
    # and not to use chroot.
    case "${this_script}" in
      *kernfs)  wrt_run_as_root    "${this_script}" "$file" ;;
      *)        wrt_run_as_chroot1 "${this_script}" "$file" ;;
    esac

    # Remove the build directory(ies) except if the package build fails.
    if [ "$vrs" != "" ] ; then
      wrt_remove_build_dirs "$name"
    fi

    # Include a touch of the target name so make can check
    # if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#

    # Keep the script file name for Makefile dependencies.
    PREV=${this_script}${N}
    # Set system_build envar for iteration targets
    system_build=$chapter6
  done # end for file in chapter06/*
}

#----------------------------#
chapter789_Makefiles() {
#----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter7/8/9${R_arrow}"

  for file in chapter0{7,8,9}/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Grub must be configured manually.
    # The filesystems can't be unmounted via Makefile and the user
    # should enter the chroot environment to create the root
    # password, edit several files and setup Grub.
    #
    # If no .config file is supplied, the kernel build is skipped
    #
    case ${this_script} in
      *grub)    continue ;;
      *reboot)  continue ;;
      *console) continue  ;; # Use the file generated by lfs-bootscripts
      *kernel)  [[ -z ${CONFIG} ]] && continue
                cp ${CONFIG} $BUILDDIR/sources/kernel-config  ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    chapter789="$chapter789 ${this_script}"

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"

    # Find the bootscripts and kernel package names
    case "${this_script}" in
      *bootscripts)
          vrs=`grep "^lfs-bootscripts-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`
          FILE="lfs-bootscripts-$vrs.tar.*"
          wrt_unpack2 "$FILE"
        ;;
      *kernel)
          vrs=`grep "^linux-version" $JHALFSDIR/packages | sed -e 's/.* //' -e 's/"//g'`
          FILE="linux-$vrs.tar.*"
          wrt_unpack2 "$FILE"
       ;;
    esac

      # Check if we have a real /etc/fstab file
    case "${this_script}" in
      *fstab) if [[ -n $FSTAB ]]; then
                wrt_copy_fstab "${this_script}"
              else
                wrt_run_as_chroot2 "$this_script" "$file"
              fi
        ;;
      *)        wrt_run_as_chroot2 "$this_script" "$file"
        ;;
    esac

    case "${this_script}" in
      *bootscripts)  wrt_remove_build_dirs "dummy" ;;
      *kernel)       wrt_remove_build_dirs "dummy" ;;
    esac

    # Include a touch of the target name so make can check
    # if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE.tmp
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#

    # Keep the script file name for Makefile dependencies.
    PREV=${this_script}
  done  # for file in chapter0{7,8,9}/*
}


#----------------------------#
build_Makefile() {
#----------------------------#
  echo "Creating Makefile... "
  cd $JHALFSDIR/${PROGNAME}-commands

  # Start with a clean Makefile.tmp file
  >$MKFILE.tmp

  chapter4_Makefiles
  chapter5_Makefiles
  chapter6_Makefiles
  # Add the ICA/farce targets, if needed
  [[ "$COMPARE" != "0" ]] && wrt_compare_targets
  chapter789_Makefiles


  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
(
    cat << EOF
$HEADER

SRC= /sources
MOUNT_PT= $BUILDDIR

include makefile-functions

EOF
) > $MKFILE


  # Add chroot commands
  i=1
  for file in chapter06/*chroot* ; do
    chroot=`cat $file | sed -e '/#!\/bin\/sh/d' -e 's@ \\\@ @g' | tr -d '\n' | sed \
      -e 's/  */ /g' -e 's|\\$|&&|g' -e 's|exit||g' -e 's|$| -c|' \
      -e 's|"$$LFS"|$(MOUNT_PT)|' -e 's|set -e||'`
    echo -e "CHROOT$i= $chroot\n" >> $MKFILE
    i=`expr $i + 1`
  done

  # Drop in the main target 'all:' and the chapter targets with each sub-target
  # as a dependency.
(
    cat << EOF
all:  chapter4 chapter5 chapter6 chapter789
	@\$(call echo_finished,$VERSION)

chapter4:  020-creatingtoolsdir 021-addinguser 022-settingenvironment

chapter5:  chapter4 $chapter5 restore-lfs-env

chapter6:  chapter5 $chapter6

chapter789:  chapter6 $chapter789

clean-all:  clean
	rm -rf ./{lfs-commands,logs,Makefile,*.xsl,makefile-functions,packages,patches}

clean:  clean-chapter789 clean-chapter6 clean-chapter5 clean-chapter4

clean-chapter4:
	-if [ ! -f user-lfs-exist ]; then \\
		userdel lfs; \\
		rm -rf /home/lfs; \\
	fi;
	rm -rf \$(MOUNT_PT)/tools
	rm -f /tools
	rm -f envars user-lfs-exist
	rm -f 02* logs/02*.log

clean-chapter5:
	rm -rf \$(MOUNT_PT)/tools/*
	rm -f $chapter5 restore-lfs-env sources-dir
	cd logs && rm -f $chapter5 && cd ..

clean-chapter6:
	-umount \$(MOUNT_PT)/sys
	-umount \$(MOUNT_PT)/proc
	-umount \$(MOUNT_PT)/dev/shm
	-umount \$(MOUNT_PT)/dev/pts
	-umount \$(MOUNT_PT)/dev
	rm -rf \$(MOUNT_PT)/{bin,boot,dev,etc,home,lib,media,mnt,opt,proc,root,sbin,srv,sys,tmp,usr,var}
	rm -f $chapter6
	cd logs && rm -f $chapter6 && cd ..

clean-chapter789:
	rm -f $chapter789
	cd logs && rm -f $chapter789 && cd ..

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
  echo "done"
}


