#!/bin/sh
# $Id$

###################################
###          FUNCTIONS          ###
###################################


#----------------------------#
host_prep_Makefiles() {      # Initialization of the system
#----------------------------#
  local   CLFS_HOST

  echo "${tab_}${GREEN}Processing... ${L_arrow}host prep files${R_arrow}"

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
	@chmod a+wt \$(MOUNT_PT)/sources
	@touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

025-addinguser:  023-creatingtoolsdir
	@\$(call echo_message, Building)
	@if [ ! -d /home/\$(LUSER) ]; then \\
		groupadd \$(LGROUP); \\
		useradd -s /bin/bash -g \$(LGROUP) -m -k /dev/null \$(LUSER); \\
	else \\
		touch user-clfs-exist; \\
	fi;
	@chown \$(LUSER) \$(MOUNT_PT) && \\
	chown \$(LUSER) \$(MOUNT_PT)/tools && \\
	chown \$(LUSER) \$(MOUNT_PT)/sources
	@touch \$@ && \\
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
	echo "PATH=\$(MOUNT_PT)/cross-tools/bin:/bin:/usr/bin" >> /home/\$(LUSER)/.bashrc && \\
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
	touch envars
	@touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

027-create-directories: 026-settingenvironment
	@\$(call echo_message, Building)

	@mkdir -p \$(MOUNT_PT)/{bin,boot,dev,{etc/,}opt,home,lib,mnt}
	@mkdir -p \$(MOUNT_PT)/{proc,media/{floppy,cdrom},sbin,srv,sys}
	@mkdir -p \$(MOUNT_PT)/var/{lock,log,mail,run,spool}
	@mkdir -p \$(MOUNT_PT)/var/{opt,cache,lib/{misc,locate},local}
	@install -d -m 0750 \$(MOUNT_PT)/root
	@install -d -m 1777 \$(MOUNT_PT){/var,}/tmp
	@mkdir -p \$(MOUNT_PT)/usr/{,local/}{bin,include,lib,sbin,src}
	@mkdir -p \$(MOUNT_PT)/usr/{,local/}share/{doc,info,locale,man}
	@mkdir -p \$(MOUNT_PT)/usr/{,local/}share/{misc,terminfo,zoneinfo}
	@mkdir -p \$(MOUNT_PT)/usr/{,local/}share/man/man{1,2,3,4,5,6,7,8}
	@for dir in \$(MOUNT_PT)/usr{,/local}; do \\
	  ln -s share/{man,doc,info} \$\$dir ; \\
	done

	@touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

028-creating-sysfile: 027-create-directories
	@\$(call echo_message, Building)

	@touch \$(MOUNT_PT)/etc/mtab
	@echo "root::0:0:root:/root:/bin/bash" >> \$(MOUNT_PT)/etc/passwd
	@echo "root:x:0:" >> \$(MOUNT_PT)/etc/group
	@echo "bin:x:1:"  >> \$(MOUNT_PT)/etc/group
	@echo "sys:x:2:"  >> \$(MOUNT_PT)/etc/group
	@echo "kmem:x:3"  >> \$(MOUNT_PT)/etc/group
	@echo "tty:x:4:"  >> \$(MOUNT_PT)/etc/group
	@echo "tape:x:5:"   >> \$(MOUNT_PT)/etc/group
	@echo "daemon:x:6:" >> \$(MOUNT_PT)/etc/group
	@echo "floppy:x:7:" >> \$(MOUNT_PT)/etc/group
	@echo "disk:x:8:"   >> \$(MOUNT_PT)/etc/group
	@echo "lp:x:9:"     >> \$(MOUNT_PT)/etc/group
	@echo "dialout:x:10:" >> \$(MOUNT_PT)/etc/group
	@echo "audio:x:11:"   >> \$(MOUNT_PT)/etc/group
	@echo "video:x:12:"   >> \$(MOUNT_PT)/etc/group
	@echo "utmp:x:13:"    >> \$(MOUNT_PT)/etc/group
	@echo "usb:x:14:"     >> \$(MOUNT_PT)/etc/group
	@echo "cdrom:x:15:"   >> \$(MOUNT_PT)/etc/group

	@touch \$(MOUNT_PT)/var/run/utmp \$(MOUNT_PT)/var/log/{btmp,lastlog,wtmp}
	@chmod 664 \$(MOUNT_PT)/var/run/utmp \$(MOUNT_PT)/var/log/lastlog
	@chown -R \$(LUSER) \$(MOUNT_PT)

	@touch \$@ && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)

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
    if [ -z $PREV ] ; then PREV=028-creating-sysfile ; fi

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
    case $name in
      glibc-headers) name="glibc" ;;
    esac
    pkg_tarball=$(get_package_tarball_name $name)
    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    if [ "$pkg_tarball" != "" ] ; then
       wrt_unpack "$pkg_tarball"
       # If using optimizations, write the instructions
       [[ "$OPTIMIZE" != "0" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi
    #
    wrt_RunAsUser "${this_script}" "${file}"
    #
    [[ "$pkg_tarball" != "" ]] && wrt_remove_build_dirs "${name}"
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



#-----------------------------#
final_system_Makefiles() {    #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}final system${R_arrow}"

  for file in final-system/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Test if the stripping phase must be skipped.
    # Skip alsp temp-perl for iterative runs
    case $this_script in
      *stripping*) [[ "$STRIP" = "0" ]] && continue ;;
    esac

    # Grab the name of the target, strip id number, XXX-script
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' \
                                  -e 's@temp-@@' \
                                  -e 's@-64bit@@' \
                                  -e 's@-64@@' \
                                  -e 's@64@@' \
                                  -e 's@n32@@'`

    # Find the version of the command files, if it corresponds with the building of
    # a specific package.
    pkg_tarball=$(get_package_tarball_name $name)

    # Append each name of the script files to a list (this will become
    # the names of the targets in the Makefile
    basicsystem="$basicsystem ${this_script}"

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line, and the previous target
    # as a dependency. Also call the echo_message function.
    wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    if [ "$pkg_tarball" != "" ] ; then
      wrt_unpack "$pkg_tarball"
      # If using optimizations, write the instructions
      [[ "$OPTIMIZE" != "0" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi
    #
    wrt_RunAsUser "${this_script}" "${file}"
    #
    [[ "$pkg_tarball" != "" ]] && wrt_remove_build_dirs "${name}"
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
    wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    [[ "$pkg_tarball" != "" ]] && wrt_unpack "$pkg_tarball"
    #
    wrt_RunAsUser "${this_script}" "${file}"
    #
    [[ "$pkg_tarball" != "" ]] && wrt_remove_build_dirs "${name}"
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


#-----------------------------#
bootable_Makefiles() {        #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}make bootable${R_arrow}"

  for file in bootable/* ; do
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
    bootable="$bootable $this_script"
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
    wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    [[ "$pkg_tarball" != "" ]] && wrt_unpack "$pkg_tarball"
    #
    # Select a script execution method
    case $this_script in
      *fstab*)  if [[ -n "$FSTAB" ]]; then
                  wrt_copy_fstab "${this_script}"
                else
                  wrt_RunAsUser "${this_script}" "${file}"
                fi
          ;;
      *chowning)  wrt_RunAsRoot "${this_script}" "${file}"
          ;;
              *)  wrt_RunAsUser "${this_script}" "${file}"
	  ;;
    esac
    #
    # Housekeeping...remove any build directory(ies) except if the package build fails.
    [[ "$pkg_tarball" != "" ]] && wrt_remove_build_dirs "${name}"
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
  final_system_Makefiles           # $basicsystem
  bootscripts_Makefiles            # $bootscripttools
  bootable_Makefiles               # $bootable

  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
(
    cat << EOF
$HEADER

SRC= /sources
MOUNT_PT= $BUILDDIR
PKG_LST= $PKG_LST
LUSER= $LUSER
LGROUP= $LGROUP

include makefile-functions

EOF
) > $MKFILE

  # Drop in the main target 'all:' and the chapter targets with each sub-target
  # as a dependency.
(
	cat << EOF
all:  chapter2 chapter3 chapter4 chapter5 chapter6 do-housekeeping
	@\$(call echo_finished,$VERSION)

chapter2:  023-creatingtoolsdir 025-addinguser 026-settingenvironment 027-create-directories 028-creating-sysfile

chapter3:  chapter2 $cross_tools

chapter4:  chapter3 $basicsystem

chapter5:  chapter4 $bootscripttools

chapter6:  chapter5 $bootable

clean-all:  clean
	rm -rf ./{clfs2-commands,logs,Makefile,*.xsl,makefile-functions,packages,patches}

clean:

restart:
	@echo "This feature does not exist for the CLFS makefile. (yet)"

restore-clfs-env:
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
	@-if [ ! -f user-clfs-exist ]; then \\
		userdel \$(LUSER); \\
		rm -rf /home/\$(LUSER); \\
	fi;

EOF
) >> $MKFILE

  # Bring over the items from the Makefile.tmp
  cat $MKFILE.tmp >> $MKFILE
  rm $MKFILE.tmp
  echo "Creating Makefile... ${BOLD}DONE${OFF}"

}

