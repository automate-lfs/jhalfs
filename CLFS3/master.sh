#!/bin/bash
# $Id$

###################################
###          FUNCTIONS          ###
###################################


#----------------------------#
host_prep_Makefiles() {      # Initialization of the system
#----------------------------#
  local   CLFS_HOST

  echo "${tab_}${GREEN}Processing... ${L_arrow}host prep files ( SETUP ) ${R_arrow}"

  # defined here, only for ease of reading
  CLFS_HOST="$(echo $MACHTYPE | sed "s/$(echo $MACHTYPE | cut -d- -f2)/cross/")"
(
cat << EOF

025-addinguser:
	@\$(call echo_message, Building)
	@if [ ! -d \$(LUSER_HOME) ]; then \\
		groupadd \$(LGROUP); \\
		useradd -s /bin/bash -g \$(LGROUP) -m -k /dev/null \$(LUSER); \\
	else \\
		touch luser-exist; \\
	fi;
	@\$(call housekeeping)

026-settingenvironment:  025-addinguser
	@\$(call echo_message, Building)
	@if [ -f \$(LUSER_HOME)/.bashrc -a ! -f \$(LUSER_HOME)/.bashrc.XXX ]; then \\
		mv \$(LUSER_HOME)/.bashrc \$(LUSER_HOME)/.bashrc.XXX; \\
	fi;
	@if [ -f \$(LUSER_HOME)/.bash_profile  -a ! -f \$(LUSER_HOME)/.bash_profile.XXX ]; then \\
		mv \$(LUSER_HOME)/.bash_profile \$(LUSER_HOME)/.bash_profile.XXX; \\
	fi;
	@echo "set +h" > \$(LUSER_HOME)/.bashrc && \\
	echo "umask 022" >> \$(LUSER_HOME)/.bashrc && \\
	echo "CLFS=\$(MOUNT_PT)" >> \$(LUSER_HOME)/.bashrc && \\
	echo "LC_ALL=POSIX" >> \$(LUSER_HOME)/.bashrc && \\
	echo "PATH=\$(MOUNT_PT)/cross-tools/bin:/bin:/usr/bin" >> \$(LUSER_HOME)/.bashrc && \\
	echo "export CLFS LC_ALL PATH" >> \$(LUSER_HOME)/.bashrc && \\
	echo "" >> \$(LUSER_HOME)/.bashrc && \\
	echo "unset CFLAGS" >> \$(LUSER_HOME)/.bashrc && \\
	echo "unset CXXFLAGS" >> \$(LUSER_HOME)/.bashrc && \\
	echo "" >> \$(LUSER_HOME)/.bashrc && \\
	echo "export CLFS_HOST=\"${CLFS_HOST}\"" >> \$(LUSER_HOME)/.bashrc && \\
	echo "export CLFS_TARGET=\"${TARGET}\"" >> \$(LUSER_HOME)/.bashrc && \\
	echo "export CLFS_MIPS_LEVEL=\"${MIPS_LEVEL}\"" >> \$(LUSER_HOME)/.bashrc && \\
	echo "export BUILD=\"${ABI}\"" >> \$(LUSER_HOME)/.bashrc && \\
	echo "source $JHALFSDIR/envars" >> \$(LUSER_HOME)/.bashrc
	@chown \$(LUSER):\$(LGROUP) \$(LUSER_HOME)/.bashrc && \\
	touch envars && \\
	chown \$(LUSER):\$(LGROUP) envars
	@\$(call housekeeping)

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
	@\$(call housekeeping)

028-creating-sysfile: 027-create-directories
	@\$(call echo_message, Building)

	@touch \$(MOUNT_PT)/etc/mtab
	@echo "root::0:0:root:/root:/bin/ash" >> \$(MOUNT_PT)/etc/passwd
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
	@chown -R \$(LUSER) \$(MOUNT_PT) && \\
	chmod -R a+w \$(MOUNT_PT)/\$(SCRIPT_ROOT) && \\
	chmod -R a+w \$(SRCSDIR)
	@\$(call housekeeping)

EOF
) >> $MKFILE.tmp

  host_prep=" 025-addinguser 026-settingenvironment 027-create-directories 028-creating-sysfile"
}

#-----------------------------#
systemprep_Makefiles() {      #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}system prep tools     ( LUSER ) ${R_arrow}"

  for file in systemprep/* ; do
    # Keep the script file name
    this_script=`basename $file`

    # Set the dependency for the first target.
    if [ -z $PREV ] ; then PREV=028-creating-sysfile ; fi

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile)
    cross_tools="$cross_tools $this_script"

    # Grab the name of the target (minus the -headers or -cross in the case of gcc
    # and binutils in chapter 5)
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@'`

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
    if [ "$pkg_tarball" != "" ] ; then
       LUSER_wrt_unpack "$pkg_tarball"
    fi
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


#-----------------------------#
cross_tools_Makefiles() {     #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}cross tools     ( LUSER ) ${R_arrow}"

  for file in cross-tools/* ; do
    # Keep the script file name
    this_script=`basename $file`
    #
    # Skip this script...
    # NOTE.. the book indicated you only needed to install groff or file if the host
    #   had older versions. The packages would be installed in the target directory
    #   and not the host.
    case $this_script in
      *cflags* | *variables* | *abi | *toolchain*)  # work done in host_prep_Makefiles
              continue ;;
      *) ;;
    esac

    #
    # Set the dependency for the first target.
    if [ -z $PREV ] ; then PREV=028-creating-sysfile ; fi

    # First append each name of the script files to a list (this will become
    # the names of the targets in the Makefile)
    cross_tools="$cross_tools $this_script"

    # Grab the name of the target (minus the -headers or -cross in the case of gcc
    # and binutils in chapter 5)
    name=`echo $this_script | sed -e 's@[0-9]\{3\}-@@' \
                                  -e 's@-static@@' \
                                  -e 's@-final@@' \
				  -e 's@-64@@' \
                                  -e 's@-n32@@'`
    case $name in
      uclibc*) name="uClibc" ;;
    esac
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
    if [ "$pkg_tarball" != "" ] ; then
       LUSER_wrt_unpack "$pkg_tarball"
      # Touch timestamp file if installed files logs will be created.
      if [ "${INSTALL_LOG}" = "y" ] ; then
        LUSER_wrt_TouchTimestamp
      fi
       # If using optimizations, write the instructions
       [[ "$OPTIMIZE" != "0" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi
    #
    LUSER_wrt_RunAsUser "${file}"
    #
    # Write installed files log and remove the build directory(ies)
    # except if the package build fails.
    if [ "$pkg_tarball" != "" ] ; then
      LUSER_RemoveBuildDirs "${name}"
      if [ "${INSTALL_LOG}" = "y" ] ; then
        LUSER_wrt_LogNewFiles "$name"
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

  done # for file in ....
}



#-----------------------------#
final_system_Makefiles() {    #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}final system    ( LUSER ) ${R_arrow}"

  for file in final-system/* ; do
    # Keep the script file name
    this_script=`basename $file`

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
    LUSER_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    if [ "$pkg_tarball" != "" ] ; then
      # Touch timestamp file if installed files logs will be created.
      if [ "${INSTALL_LOG}" = "y" ] ; then
        LUSER_wrt_TouchTimestamp
      fi
      LUSER_wrt_unpack "$pkg_tarball"
      # If using optimizations, write the instructions
      [[ "$OPTIMIZE" != "0" ]] &&  wrt_optimize "$name" && wrt_makeflags "$name"
    fi
    #
    LUSER_wrt_RunAsUser "${file}"
    #
    # Write installed files log and remove the build directory(ies)
    # except if the package build fails.
    if [ "$pkg_tarball" != "" ] ; then
      LUSER_RemoveBuildDirs "${name}"
      if [ "${INSTALL_LOG}" = "y" ] ; then
        LUSER_wrt_LogNewFiles "$name"
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
    PREV=${this_script}
  done  # for file in final-system/* ...
}



#-----------------------------#
bootscripts_Makefiles() {     #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}bootscripts     ( LUSER ) ${R_arrow}"

  for file in bootscripts/* ; do
    # Keep the script file name
    this_script=`basename $file`

    case $this_script in
      *console*) continue ;; # Use the files that came with the bootscripts
      *network*) continue ;; # Manually create these files
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
      *bootscripts*) name=clfs-embedded-bootscripts ;;
    esac

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
    if [ "$pkg_tarball" != "" ] ; then
      LUSER_wrt_unpack "$pkg_tarball"
      if [ "${INSTALL_LOG}" = "y" ] ; then
        LUSER_wrt_TouchTimestamp
      fi
    fi
    #
    LUSER_wrt_RunAsUser "${file}"
    #
    if [ "$pkg_tarball" != "" ] ; then
      LUSER_RemoveBuildDirs "${name}"
      if [ "${INSTALL_LOG}" = "y" ] ; then
        LUSER_wrt_LogNewFiles "$name"
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


#-----------------------------#
bootable_Makefiles() {        #
#-----------------------------#
  echo "${tab_}${GREEN}Processing... ${L_arrow}make bootable   ( LUSER ) ${R_arrow}"

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
    # NOTE: new makfile format forces the last script, *chowning, into a separate
    #  phase.
    case ${this_script} in
      *chowning) chowning=${this_script}   ;;
              *) bootable="$bootable $this_script"  ;;
    esac
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
    LUSER_wrt_target "${this_script}" "$PREV"
    #
    # If $pkg_tarball isn't empty, we've got a package...
    if [ "$pkg_tarball" != "" ] ; then
      LUSER_wrt_unpack "$pkg_tarball"
      if [ "${INSTALL_LOG}" = "y" ] ; then
        LUSER_wrt_TouchTimestamp
      fi
    fi
    #
    # Select a script execution method
    case $this_script in
      *fstab*)  if [[ -n "$FSTAB" ]]; then
                  LUSER_wrt_CopyFstab
                else
                  LUSER_wrt_RunAsUser "${file}"
                fi
          ;;
      *chowning)  wrt_RunAsRoot "${file}"
          ;;
              *)  LUSER_wrt_RunAsUser "${file}"
          ;;
    esac
    #
    # Housekeeping...remove any build directory(ies) except if the package build fails.
    if [ "$pkg_tarball" != "" ] ; then
      LUSER_RemoveBuildDirs "${name}"
      if [ "${INSTALL_LOG}" = "y" ] ; then
        LUSER_wrt_LogNewFiles "$name"
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


#-----------------------------#
build_Makefile() {            # Construct a Makefile from the book scripts
#-----------------------------#
  echo "Creating Makefile... ${BOLD}START${OFF}"

  cd $JHALFSDIR/${PROGNAME}-commands
  # Start with a clean Makefile.tmp file
  >$MKFILE.tmp

  host_prep_Makefiles
  [[ "${PLATFORM% -*}" = "WRT" ]] && systemprep_Makefiles # $cross_tools
  cross_tools_Makefiles            # $cross_tools
  final_system_Makefiles           # $basicsystem
  bootscripts_Makefiles            # $bootscripttools
  bootable_Makefiles               # $bootable
  # Add the CUSTOM_TOOLS targets, if needed
  [[ "$CUSTOM_TOOLS" = "y" ]] && wrt_CustomTools_target

  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
  wrt_Makefile_header

  # Drop in the main target 'all:' and the chapter targets with each sub-target
  # as a dependency.
(
cat << EOF

all:	ck_UID mk_SETUP mk_LUSER create-sbu_du-report mk_CUSTOM_TOOLS mk_ROOT
	@sudo make restore-luser-env
	@sudo make do-housekeeping
	@\$(call echo_finished,$VERSION)

ck_UID:
	@if [ \`id -u\` = "0" ]; then \\
	  echo "--------------------------------------------------"; \\
	  echo "You cannot run this makefile from the root account"; \\
	  echo "--------------------------------------------------"; \\
	  exit 1; \\
	fi

mk_SETUP:
	@\$(call echo_SU_request)
	@sudo make BREAKPOINT=\$(BREAKPOINT) SETUP
	@touch \$@

mk_LUSER: mk_SETUP
	@\$(call echo_SULUSER_request)
	@(sudo \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) LUSER" )
	@touch \$@

mk_CUSTOM_TOOLS: create-sbu_du-report
	@if [ "\$(ADD_CUSTOM_TOOLS)" = "y" ]; then \\
	  \$(call sh_echo_PHASE,Building CUSTOM_TOOLS); \\
	  (sudo \$(SU_LUSER) "mkdir -p $BUILDDIR$TRACKING_DIR"); \\
	  (sudo \$(SU_LUSER) "source .bashrc && cd \$(MOUNT_PT)/\$(SCRIPT_ROOT) && make BREAKPOINT=\$(BREAKPOINT) CUSTOM_TOOLS"); \\
	fi;
	@touch \$@

mk_ROOT:
	@\$(call echo_SU_request)
	@echo "$VERSION-embedded - jhalfs build" > clfs-release && \\
	sudo mv clfs-release \$(MOUNT_PT)/etc
	@sudo make BREAKPOINT=\$(BREAKPOINT) ROOT
	@touch \$@


SETUP:        $host_prep
LUSER:	      $cross_tools $basicsystem $bootscripttools $bootable
CUSTOM_TOOLS: $custom_list
ROOT:	      $chowning


create-sbu_du-report:  mk_LUSER
	@\$(call echo_message, Building)
	@if [ "\$(ADD_REPORT)" = "y" ]; then \\
	  ./create-sbu_du-report.sh logs $VERSION; \\
	  \$(call echo_report,$VERSION-SBU_DU-$(date --iso-8601).report); \\
	fi;
	@touch  \$@

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

do-housekeeping:
	@-if [ ! -f luser-exist ]; then \\
		userdel \$(LUSER); \\
		rm -rf \$(LUSER_HOME); \\
	fi;

EOF
) >> $MKFILE

  # Bring over the items from the Makefile.tmp
  cat $MKFILE.tmp >> $MKFILE
  rm $MKFILE.tmp
  echo "Creating Makefile... ${BOLD}DONE${OFF}"

}

