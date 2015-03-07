# $Id$

#----------------------------------#
wrt_compare_targets() {            #
#----------------------------------#

  for ((N=1; N <= ITERATIONS ; N++)) ; do # Double parentheses,
                                          # and "ITERATIONS" with no "$".
    ITERATION=iteration-$N
    if [ "$N" != "1" ] ; then
      wrt_system_build "$N" "$PREV_IT"
    fi
    this_script=$ITERATION
    CHROOT_wrt_target "$ITERATION" "$PREV"
    wrt_compare_work "$ITERATION" "$PREV_IT"
    wrt_logs "$N"
    wrt_touch
    PREV_IT=$ITERATION
    PREV=$ITERATION
  done
}

#----------------------------------#
wrt_system_build() {               #
#----------------------------------#
  local     RUN=$1
  local PREV_IT=$2

  if [[ "$PROGNAME" = "clfs" ]] ; then
    final_system_Makefiles $RUN
  else
    chapter6_Makefiles $RUN
  fi

  if [[ "$PROGNAME" = "clfs" ]] ; then
    basicsystem="$basicsystem $PREV_IT $system_build"
  else
    chapter6="$chapter6 $PREV_IT $system_build"
  fi

  if [[ "$RUN" = "$ITERATIONS" ]] ; then
    if [[ "$PROGNAME" = "clfs" ]] ; then
      basicsystem="$basicsystem iteration-$RUN"
    else
      chapter6="$chapter6 iteration-$RUN"
    fi
  fi
}

#----------------------------------#
wrt_compare_work() {               #
#----------------------------------#
  local ITERATION=$1
  local   PREV_IT=$2
  local PRUNEPATH="/dev /home /${SCRIPT_ROOT} /lost+found /media /mnt /opt /proc \
/sources /root /srv /sys /tmp /tools /usr/local /usr/src"

  local    ROOT_DIR=/
  local DEST_TOPDIR=/${SCRIPT_ROOT}
  local   ICALOGDIR=/${SCRIPT_ROOT}/logs/ICA
  local FARCELOGDIR=/${SCRIPT_ROOT}/logs/farce

  if [[ "$RUN_ICA" = "y" ]] ; then
    local DEST_ICA=$DEST_TOPDIR/ICA && \
(
    cat << EOF
	@extras/do_copy_files "$PRUNEPATH" $ROOT_DIR $DEST_ICA/$ITERATION >>logs/\$@ 2>&1 && \\
	extras/do_ica_prep $DEST_ICA/$ITERATION >>logs/\$@ 2>&1
EOF
) >> $MKFILE.tmp
    if [[ "$ITERATION" != "iteration-1" ]] ; then
      wrt_do_ica_work "$PREV_IT" "$ITERATION" "$DEST_ICA"
    fi
  fi

  if [[ "$RUN_FARCE" = "y" ]] ; then
    local DEST_FARCE=$DEST_TOPDIR/farce && \
(
    cat << EOF
	@extras/do_copy_files "$PRUNEPATH" $ROOT_DIR $DEST_FARCE/$ITERATION >>logs/\$@ 2>&1 && \\
	extras/filelist $DEST_FARCE/$ITERATION $DEST_FARCE/filelist-$ITERATION >>logs/\$@ 2>&1
EOF
) >> $MKFILE.tmp
    if [[ "$ITERATION" != "iteration-1" ]] ; then
      wrt_do_farce_work "$PREV_IT" "$ITERATION" "$DEST_FARCE"
    fi
  fi
}

#----------------------------------#
wrt_do_ica_work() {                #
#----------------------------------#
  echo -e "\t@extras/do_ica_work $1 $2 $ICALOGDIR $3 >>logs/\$@ 2>&1" >> $MKFILE.tmp
}

#----------------------------------#
wrt_do_farce_work() {              #
#----------------------------------#
  local OUTPUT=$FARCELOGDIR/${1}_V_${2}
  local PREDIR=$3/$1
  local PREFILE=$3/filelist-$1
  local ITEDIR=$3/$2
  local ITEFILE=$3/filelist-$2
  echo -e "\t@extras/farce --directory $OUTPUT $PREDIR $PREFILE $ITEDIR $ITEFILE >>logs/\$@ 2>&1" >> $MKFILE.tmp
}

#----------------------------------#
wrt_logs() {                       #
#----------------------------------#
  local build=build_$1
  local file

(
    cat << EOF
	@cd logs && \\
	mkdir $build && \\
	mv -f `echo ${system_build} | sed 's/ /* /g'`* $build && \\
	if [ ! $build = build_1 ] ; then \\
	  cd $build && \\
	  for file in \`ls .\` ; do \\
	    mv -f \$\$file \`echo \$\$file | sed -e 's,-$build,,'\` ; \\
	  done ; \\
	fi ;
	@cd /\$(SCRIPT_ROOT)
	@if [ -d test-logs ] ; then \\
	  cd test-logs && \\
	  mkdir $build && \\
	  mv -f ${system_build} $build && \\
	  if [ ! $build = build_1 ] ; then \\
	    cd $build && \\
	    for file in \`ls .\` ; do \\
	      mv -f \$\$file \`echo \$\$file | sed -e 's,-$build,,'\` ; \\
	    done ; \\
	  fi ; \\
	  cd /\$(SCRIPT_ROOT) ; \\
	fi ;
EOF
) >> $MKFILE.tmp
}
