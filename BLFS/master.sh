#!/bin/sh

# $Id$

#----------------------------#
build_Makefile() {
#----------------------------#
  echo -n "Creating Makefile... "
  cd $JHALFSDIR/${PROGNAME}-commands

  # Start with a clean Makefile file
  >$MKFILE


  # Add a header, some variables and include the function file
  # to the top of the real Makefile.
(
    cat << EOF
$HEADER

include makefile-functions

EOF
) > $MKFILE

  # Drop in a dummy target 'all:'.
(
    cat << EOF
all:
	@echo -e "\nThere is no default target predefined"
	@echo -e "You must to tell what package(s) you want to install"
	@echo -e "or edit the \"all\" Makefile target to create your own"
	@echo -e "defualt target.\n"
	@exit
EOF
) >> $MKFILE

  # Bring over the build targets.
  for file in */* ; do
    # Keep the script file name
    case $file in
      gnome/config )
        this_script=config-gnome
        ;;
      gnome/pre-install-config )
        this_script=pre-intall-config-gnome
        ;;
      kde/config )
        this_script=config-kde
        ;;
      kde/pre-install-config )
        this_script=pre-intall-config-kde
        ;;
      * )
        this_script=`basename $file`
        ;;
    esac

    # Dump the package dependencies.
    REQUIRED=`grep "REQUIRED" $file | sed 's/# REQUIRED://' | tr -d '\n'`
    if [ "$DEPEND" != "0" ] ; then
      RECOMMENDED=`grep "RECOMMENDED" $file | sed 's/# RECOMMENDED://' | tr -d '\n'`
    fi
    if [ "$DEPEND" = "2" ] ; then
      OPTIONAL=`grep "OPTIONAL" $file | sed 's/# OPTIONAL://' | tr -d '\n'`
    fi

    #--------------------------------------------------------------------#
    #         >>>>>>>> START BUILDING A Makefile ENTRY <<<<<<<<          #
    #--------------------------------------------------------------------#
    #
    # Drop in the name of the target on a new line plus its dependencies
    # and call the echo_message function.
(
    cat << EOF

$this_script:  $REQUIRED $RECOMMENDED $OPTIONAL
	@\$(call echo_message, Building)
EOF
) >> $MKFILE

    # Insert date and disk usage at the top of the log file, the script run
    # and date and disk usage again at the bottom of the log file.
(
    cat << EOF
	@echo -e "\n\`date\`\n\nKB: \`du -sk --exclude=logs/* /\`\n" >logs/$this_script && \\
	$JHALFSDIR/${PROGNAME}-commands/$file >>logs/$this_script 2>&1 && \\
	echo -e "\n\`date\`\n\nKB: \`du -sk --exclude=logs/* /\`\n" >>logs/$this_script
EOF
) >> $MKFILE

    # Include a touch of the target name so make can check
    # if it's already been made.
    echo -e '\t@touch $@' >> $MKFILE
    #
    #--------------------------------------------------------------------#
    #              >>>>>>>> END OF Makefile ENTRY <<<<<<<<               #
    #--------------------------------------------------------------------#

  done
  echo -ne "done\n"
}



