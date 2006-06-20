#!/bin/sh
set -e  # Enable error trapping

# $Id$

###################################
###          FUNCTIONS          ###
###################################


#----------------------------#
chapter3_Makefiles() {       # Initialization of the system
#----------------------------#
  local TARGET LOADER

  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter3${R_arrow}"

  # Define a few model dependant variables
  if [[ ${MODEL} = "uclibc" ]]; then
    TARGET="tools-linux-uclibc"; LOADER="ld-uClibc.so.0"
  else
    TARGET="tools-linux-gnu";    LOADER="ld-linux.so.2"
  fi

  # NOTE: We use the lfs username and groupname also in HLFS
  # If /home/lfs is already present in the host, we asume that the
  # lfs user and group are also presents in the host, and a backup
  # of their bash init files is made.
(
cat << EOF
020-creatingtoolsdir:
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

021-addinguser:  020-creatingtoolsdir
	@\$(call echo_message, Building)
	@if [ ! -d /home/lfs ]; then \\
		groupadd lfs; \\
		useradd -s /bin/bash -g lfs -m -k /dev/null lfs; \\
	else \\
		touch user-lfs-exist; \\
	fi;
	@chown lfs \$(MOUNT_PT)/tools && \\
	chown lfs \$(MOUNT_PT)/sources && \\
	touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

022-settingenvironment:  021-addinguser
	@\$(call echo_message, Building)
	@if [ -f /home/lfs/.bashrc -a ! -f /home/lfs/.bashrc.XXX ]; then \\
		mv /home/lfs/.bashrc /home/lfs/.bashrc.XXX; \\
	fi;
	@if [ -f /home/lfs/.bash_profile  -a ! -f /home/lfs/.bash_profile.XXX ]; then \\
		mv /home/lfs/.bash_profile /home/lfs/.bash_profile.XXX; \\
	fi;
	@echo "set +h" > /home/lfs/.bashrc && \\
	echo "umask 022" >> /home/lfs/.bashrc && \\
	echo "HLFS=\$(MOUNT_PT)" >> /home/lfs/.bashrc && \\
	echo "LC_ALL=POSIX" >> /home/lfs/.bashrc && \\
	echo "PATH=/tools/bin:/bin:/usr/bin" >> /home/lfs/.bashrc && \\
	echo "export HLFS LC_ALL PATH" >> /home/lfs/.bashrc && \\
	echo "" >> /home/lfs/.bashrc && \\
	echo "target=$(uname -m)-${TARGET}" >> /home/lfs/.bashrc && \\
	echo "ldso=/tools/lib/${LOADER}" >> /home/lfs/.bashrc && \\
	echo "export target ldso" >> /home/lfs/.bashrc && \\
	echo "source $JHALFSDIR/envars" >> /home/lfs/.bashrc && \\
	chown lfs:lfs /home/lfs/.bashrc && \\
	touch envars && \\
	touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)
EOF
) >> $MKFILE.tmp

}

#----------------------------#
chapter5_Makefiles() {       # Bootstrap or temptools phase
#----------------------------#
  local file
  local this_script

  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter5${R_arrow}"

  for file in chapter05/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Skip this script depending on jhalfs.conf flags set.
    case $this_script in
      # If no testsuites will be run, then TCL, Expect and DejaGNU aren't needed
      *tcl* )     [[ "$TEST" = "0" ]] && continue; ;;
      *expect* )  [[ "$TEST" = "0" ]] && continue; ;;
      *dejagnu* ) [[ "$TEST" = "0" ]] && continue; ;;
        # Nothing interestin in this script
      *introduction* ) continue ;;
        # Test if the stripping phase must be skipped
      *stripping* ) [[ "$STRIP" = "0" ]] && continue ;;
      *) ;;
    esac

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    chapter5="$chapter5 $this_script"

    # Grab the name of the target (minus the -headers or -cross in the case of gcc
    # and binutils in chapter 5)
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' -e 's@-cross@@' -e 's@-headers@@'`

    # Adjust 'name'
    case $name in
      linux-libc) name="linux-libc-headers" ;;
      gcc)        name="gcc-core"  ;;
      uclibc)     name="uClibc"  ;;
    esac

    # Set the dependency for the first target.
    if [ -z $PREV ] ; then PREV=022-settingenvironment ; fi

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "$this_script" "$PREV"

    # Find the version of the command files, if it corresponds with the building of
    # a specific package
    pkg_tarball=$(get_package_tarball_name $name)
    # If $pkg_tarball isn't empty, we've got a package...
    if [ "$pkg_tarball" != "" ] ; then
      # Insert instructions for unpacking the package and to set the PKGDIR variable.
      case $this_script in
        *binutils* )  wrt_unpack "$pkg_tarball" 1 ;; # Do not delete an existing package directories
        *)            wrt_unpack "$pkg_tarball" ;;
      esac
      # If the testsuites must be run, initialize the log file
      [[ "$TEST" = "3" ]] && wrt_test_log "${this_script}"
      # If using optimizations, write the instructions
      [[ "$OPTIMIZE" = "2" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi

    case $this_script in
      *binutils* )  # Dump the path to sources directory for later removal
(
cat << EOF
	@ROOT=\`head -n1 \$(MOUNT_PT)\$(SRC)/\$(PKG_LST) | sed 's@^./@@;s@/.*@@'\` && \\
	echo "\$(MOUNT_PT)\$(SRC)/\$\$ROOT" >> sources-dir
EOF
) >> $MKFILE.tmp
        ;;
      *adjusting* )  # For the Adjusting phase we must to cd to the binutils-build directory.
        echo -e '\t@echo "export PKGDIR=$(MOUNT_PT)$(SRC)/binutils-build" > envars' >> $MKFILE.tmp
        ;;
    esac

    # Insert date and disk usage at the top of the log file, the script run
    # and date and disk usage again at the bottom of the log file.
    wrt_run_as_su "${this_script}" "${file}"

    # Remove the build directory(ies) except if the package build fails
    # (so we can review config.cache, config.log, etc.)
    # For Binutils the sources must be retained for some time.
    if [ "$pkg_tarball" != "" ] ; then
      case "${this_script}" in
        *binutils*) : ;;   # do NOTHING
	*gcc*) wrt_remove_build_dirs "gcc"    ;;
        *)     wrt_remove_build_dirs "$name"    ;;
      esac
    fi

    # Remove the Binutils pass 1 sources after a successful Adjusting phase.
    case "${this_script}" in
     *adjusting*)
(
cat << EOF
	@rm -r \`cat sources-dir\` && \\
	rm -r \$(MOUNT_PT)\$(SRC)/binutils-build && \\
	rm sources-dir
EOF
) >> $MKFILE.tmp
      ;;
    esac

    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#

    # Keep the script file name for Makefile dependencies.
    PREV=$this_script
  done  # end for file in chapter05/*
}


#----------------------------#
chapter6_Makefiles() {       # sysroot or chroot build phase
#----------------------------#
  local TARGET LOADER
  local file
  local this_script
  # Set envars and scripts for iteration targets
  LOGS="" # Start with an empty global LOGS envar
  if [[ -z "$1" ]] ; then
    local N=""
  else
    local N=-build_$1
    local chapter6=""
    mkdir chapter06$N
    cp chapter06/* chapter06$N
    for script in chapter06$N/* ; do
      # Overwrite existing symlinks, files, and dirs
      sed -e 's/ln -s /ln -sf /g' \
          -e 's/^mv /&-f/g' -i ${script}
    done
    # Remove Bzip2 binaries before make install
    sed -e 's@make install@rm -vf /usr/bin/bz*\n&@' -i chapter06$N/*-bzip2
    # Fix how Module-Init-Tools do the install target
    sed -e 's@make install@make INSTALL=install install@' -i chapter06$N/*-module-init-tools
    # Delete *old Readline libraries just after make install
    sed -e 's@make install@&\nrm -v /lib/lib{history,readline}*old@' -i chapter06$N/*-readline
    # Don't readd already existing groups
    sed -e '/groupadd/d' -i chapter06$N/*-udev
  fi

  echo "${tab_}${GREEN}Processing... ${L_arrow}Chapter6$N${R_arrow}"
  #
  # Set these definitions early and only once
  #
  if [[ ${MODEL} = "uclibc" ]]; then
    TARGET="pc-linux-uclibc"; LOADER="ld-uClibc.so.0"
  else
    TARGET="pc-linux-gnu";    LOADER="ld-linux.so.2"
  fi

  for file in chapter06$N/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Skip this script depending on jhalfs.conf flags set.
    case $this_script in
        # We'll run the chroot commands differently than the others, so skip them in the
        # dependencies and target creation.
      *chroot* )  continue ;;
        # Test if the stripping phase must be skipped
      *-stripping* )  [[ "$STRIP" = "0" ]] && continue ;;
    esac

    # Grab the name of the target
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`

    #
    # Sed replacement to fix some rm command that could fail.
    # That should be fixed in the book sources.
    #
    case $name in
      glibc)  sed 's/rm /rm -f /' -i chapter06$N/$this_script        ;;
      gcc)    sed 's/rm /rm -f /' -i chapter06$N/$this_script        ;;
    esac

    case $name in
      gcc)     name="gcc-core" ;;
      uclibc)  name="uClibc"   ;;
    esac

    # Find the version of the command files, if it corresponds with the building of
    # a specific package
    pkg_tarball=$(get_package_tarball_name $name)

    if [[ "$pkg_tarball" = "" ]] && [[ -n "$N" ]] ; then
      case "${this_script}" in
        *stripping*) ;;
        *)  continue ;;
      esac
    fi

    # Append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    chapter6="$chapter6 ${this_script}${N}"

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

    # If $pkg_tarball isn't empty, we've got a package...
    # Insert instructions for unpacking the package and changing directories
    if [ "$pkg_tarball" != "" ] ; then
      wrt_unpack2 "$pkg_tarball"
      wrt_target_vars
      # If the testsuites must be run, initialize the log file
      case $name in
        binutils | gcc-core | glibc )
          [[ "$TEST" != "0" ]] && wrt_test_log2 "${this_script}"
          ;;
        * )
          [[ "$TEST" = "2" ]] || [[ "$TEST" = "3" ]] && wrt_test_log2 "${this_script}"
          ;;
      esac
      # If using optimizations, write the instructions
      [[ "$OPTIMIZE" != "0" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi

    case $this_script in
      *readjusting*) # For the Re-Adjusting phase we must to cd to the binutils-build directory.
        echo -e '\t@echo "export PKGDIR=$(SRC)/binutils-build" > envars' >> $MKFILE.tmp
        ;;
    esac

    # In the mount of kernel filesystems we need to set LFS and not to use chroot.
    case "${this_script}" in
      *kernfs*)
        wrt_run_as_root "${this_script}" "${file}"
        ;;
      *)   # The rest of Chapter06
        wrt_run_as_chroot1 "${this_script}" "${file}"
       ;;
    esac
    #
    # Remove the build directory(ies) except if the package build fails.
    if [ "$pkg_tarball" != "" ] ; then
      wrt_remove_build_dirs "$name"
    fi
    #
    # Remove the Binutils pass 2 sources after a successful Re-Adjusting phase.
    case "${this_script}" in
      *readjusting*)
(
cat << EOF
	@rm -r \`cat sources-dir\` && \\
	rm -r \$(MOUNT_PT)\$(SRC)/binutils-build && \\
	rm sources-dir
EOF
) >> $MKFILE.tmp
      ;;
    esac

    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
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
chapter7_Makefiles() {       # Create a bootable system.. kernel, bootscripts..etc
#----------------------------#
  local file
  local this_script

  echo  "${tab_}${GREEN}Processing... ${L_arrow}Chapter7${R_arrow}"
  for file in chapter07/*; do
    # Keep the script file name
    this_script=`basename $file`

    # Grub must be configured manually.
    # The filesystems can't be unmounted via Makefile and the user
    # should enter the chroot environment to create the root
    # password, edit several files and setup Grub.
    case $this_script in
      *usage)   continue  ;; # Contains example commands
      *grub)    continue  ;;
      *reboot)  continue  ;;
      *console) continue  ;; # Use the file generated by lfs-bootscripts

      *kernel)
          # If no .config file is supplied, the kernel build is skipped
        [[ -z $CONFIG ]] && continue
	cp $CONFIG $BUILDDIR/sources/kernel-config
         ;;
    esac

    # First append then name of the script file to a list (this will become
    # the names of the targets in the Makefile
    chapter7="$chapter7 $this_script"

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "$this_script" "$PREV"

    case "${this_script}" in
      *bootscripts*)
        wrt_unpack2 $(get_package_tarball_name "lfs-bootscripts")
        blfs_bootscripts=$(get_package_tarball_name "blfs-bootscripts" | sed -e 's/.tar.*//' )
        echo -e "\t@echo \"\$(MOUNT_PT)\$(SRC)/$blfs_bootscripts\" >> sources-dir" >> $MKFILE.tmp
        ;;
    esac

    case "${this_script}" in
      *fstab*) # Check if we have a real /etc/fstab file
        if [[ -n "$FSTAB" ]] ; then
          wrt_copy_fstab "$this_script"
        else  # Initialize the log and run the script
          wrt_run_as_chroot2 "${this_script}" "${file}"
        fi
        ;;
      *)  # All other scripts
        wrt_run_as_chroot2 "${this_script}" "${file}"
        ;;
    esac

    # Remove the build directory except if the package build fails.
    case "${this_script}" in
      *bootscripts*)
(
cat << EOF
	@ROOT=\`head -n1 \$(MOUNT_PT)\$(SRC)/\$(PKG_LST) | sed 's@^./@@;s@/.*@@'\` && \\
	rm -r \$(MOUNT_PT)\$(SRC)/\$\$ROOT
	@rm -r \`cat sources-dir\` && \\
	rm sources-dir
EOF
) >> $MKFILE.tmp
       ;;
    esac

    # Include a touch of the target name so make can check if it's already been made.
    wrt_touch
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#

    # Keep the script file name for Makefile dependencies.
    PREV=$this_script
  done  # for file in chapter07/*

  # Add SBU-disk_usage report target if required
  if [[ "$REPORT" = "1" ]] ; then wrt_report ; fi
}


#----------------------------#
build_Makefile() {           # Construct a Makefile from the book scripts
#----------------------------#
  echo "Creating Makefile... ${BOLD}START${OFF}"

  cd $JHALFSDIR/${PROGNAME}-commands
  # Start with a clean Makefile.tmp file
  >$MKFILE.tmp

  chapter3_Makefiles
  chapter5_Makefiles
  chapter6_Makefiles
  # Add the iterations targets, if needed
  [[ "$COMPARE" != "0" ]] && wrt_compare_targets
  chapter7_Makefiles

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
  i=1
  for file in chapter06/*chroot* ; do
    chroot=`cat $file | sed -e '/#!\/bin\/sh/d' \
          -e '/^export/d' \
          -e '/^logout/d' \
          -e 's@ \\\@ @g' | tr -d '\n' |  sed -e 's/  */ /g' \
                                              -e 's|\\$|&&|g' \
                                              -e 's|exit||g' \
                                              -e 's|$| -c|' \
                                              -e 's|"$$HLFS"|$(MOUNT_PT)|'\
                                              -e 's|set -e||'`
    echo -e "CHROOT$i= $chroot\n" >> $MKFILE
    i=`expr $i + 1`
  done

  # Drop in the main target 'all:' and the chapter targets with each sub-target
  # as a dependency.
(
  cat << EOF
all:  chapter3 chapter5 chapter6 chapter7 do-housekeeping
	@\$(call echo_finished,$VERSION)

chapter3:  020-creatingtoolsdir 021-addinguser 022-settingenvironment

chapter5:  chapter3 $chapter5 restore-lfs-env

chapter6:  chapter5 $chapter6

chapter7:  chapter6 $chapter7

clean-all:  clean
	rm -rf ./{hlfs-commands,logs,Makefile,*.xsl,makefile-functions,packages,patches}

clean:  clean-chapter7 clean-chapter6 clean-chapter5 clean-chapter3

restart: restart_code all

clean-chapter3:
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

clean-chapter7:
	rm -f $chapter7
	cd logs && rm -f $chapter7 && cd ..

restore-lfs-env:
	@\$(call echo_message, Building)
	@if [ -f /home/lfs/.bashrc.XXX ]; then \\
		mv -f /home/lfs/.bashrc.XXX /home/lfs/.bashrc; \\
	fi;
	@if [ -f /home/lfs/.bash_profile.XXX ]; then \\
		mv /home/lfs/.bash_profile.XXX /home/lfs/.bash_profile; \\
	fi;
	@chown lfs:lfs /home/lfs/.bash* && \\
	touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

do-housekeeping:
	@-umount \$(MOUNT_PT)/dev/pts
	@-umount \$(MOUNT_PT)/dev/shm
	@-umount \$(MOUNT_PT)/dev
	@-umount \$(MOUNT_PT)/sys
	@-umount \$(MOUNT_PT)/proc
	@-if [ ! -f user-lfs-exist ]; then \\
		userdel lfs; \\
		rm -rf /home/lfs; \\
	fi;

restart_code:
	@echo ">>> This feature is experimental, BUGS may exist"	
	
	@if [ ! -L /tools ]; then \\
	  echo -e "\\nERROR::\\n /tools is NOT a symlink.. /tools must point to \$(MOUNT_PT)/tools\\n" && false;\\
	fi;
	
	@if [ ! -e /tools ]; then \\
	  echo -e "\\nERROR::\\nThe target /tools points to does not exist.\\nVerify the target.. \$(MOUNT_PT)/tools\\n" && false;\\
	fi;
	
	@if ! stat -c %N /tools | grep "\$(MOUNT_PT)/tools" >/dev/null ; then \\
	  echo -e "\\nERROR::\\nThe symlink \\"/tools\\" does not point to \\"\$(MOUNT_PT)/tools\\".\\nCorrect the problem and rerun\\n" && false;\\
	fi;	

	@if [ -f ???-kernfs ]; then \\
	  mkdir -pv \$(MOUNT_PT)/{proc,sys};\\
	  if !  mount -l | "\$(MOUNT_PT)/dev" >/dev/null ; then \\
	    mount -vt ramfs ramfs \$(MOUNT_PT)/dev;\\
	  fi;\\
	  if [ ! -e \$(MOUNT_PT)/dev/console ]; then \\
	    mknod -m 600 \$(MOUNT_PT)/dev/console c 5 1;\\
	  fi;\\
	  if [ ! -e \$(MOUNT_PT)/dev/null ]; then \\
	    mknod -m 666 \$(MOUNT_PT)/dev/null c 1 3;\\
	  fi;\\
	  if ! mount -l | grep "\$(MOUNT_PT)/dev/pts" >/dev/null ; then \\
	    mount -vt devpts -o gid=4,mode=620 devpts \$(MOUNT_PT)/dev/pts;\\
	  fi;\\
	  if ! mount -l | grep "\$(MOUNT_PT)/dev/shm" >/dev/null ; then \\
	    mount -vt tmpfs shm \$(MOUNT_PT)/dev/shm;\\
	  fi;\\
	  if ! mount -l | grep "\$(MOUNT_PT)/proc" >/dev/null ; then \\
	    mount -vt proc proc \$(MOUNT_PT)/proc;\\
	  fi;\\
	  if ! mount -l | grep "\$(MOUNT_PT)/sys" >/dev/null ; then \\
	    mount -vt sysfs sysfs \$(MOUNT_PT)/sys;\\
	  fi;\\
	fi;


EOF
) >> $MKFILE

  # Bring over the items from the Makefile.tmp
  cat $MKFILE.tmp >> $MKFILE
  rm $MKFILE.tmp
  echo "Creating Makefile... ${BOLD}DONE${OFF}"

}
