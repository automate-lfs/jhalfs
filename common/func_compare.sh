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
    wrt_target "$ITERATION" "$PREV"
    wrt_compare_work "$ITERATION" "$PREV_IT"
    wrt_logs "$N"
    PREV_IT=$ITERATION
    PREV=$ITERATION
  done
}

#----------------------------------#
wrt_system_build() {               #
#----------------------------------#
  local     RUN=$1
  local PREV_IT=$2

  if [[ "$PROGNAME" = "clfs" ]] && [[ "$METHOD" = "chroot" ]] ; then
    final_system_Makefiles $RUN
  elif [[ "$PROGNAME" = "clfs" ]] && [[ "$METHOD" = "boot" ]] ; then
    bm_final_system_Makefiles $RUN
  else
    chapter6_Makefiles $RUN
  fi

  echo -e "\nsystem_build_$RUN: $PREV_IT $system_build" >> $MKFILE.tmp
}

#----------------------------------#
wrt_compare_work() {               #
#----------------------------------#
  local ITERATION=$1
  local   PREV_IT=$2
  local PRUNEPATH="/dev /home /${SCRIPT_ROOT} /lost+found /media /mnt /opt /proc \
/sources /root /srv /sys /tmp /tools /usr/local /usr/src /var/log/paco"

  if [[ "$PROGNAME" = "clfs" ]] && [[ "$METHOD" = "boot" ]] ; then
    local    ROOT_DIR=/
    local DEST_TOPDIR=/${SCRIPT_ROOT}
    local   ICALOGDIR=/${SCRIPT_ROOT}/logs/ICA
    local FARCELOGDIR=/${SCRIPT_ROOT}/logs/farce
  else
    local    ROOT_DIR=$BUILDDIR
    local DEST_TOPDIR=$BUILDDIR/${SCRIPT_ROOT}
  fi

  if [[ "$RUN_ICA" = "1" ]] ; then
    local DEST_ICA=$DEST_TOPDIR/ICA && \
(
    cat << EOF
	@extras/do_copy_files "$PRUNEPATH" $ROOT_DIR $DEST_ICA/$ITERATION >>logs/$ITERATION.log 2>&1 && \\
	extras/do_ica_prep $DEST_ICA/$ITERATION >>logs/$ITERATION.log 2>&1
EOF
) >> $MKFILE.tmp
    if [[ "$ITERATION" != "iteration-1" ]] ; then
      wrt_do_ica_work "$PREV_IT" "$ITERATION" "$DEST_ICA"
    fi
  fi

  if [[ "$RUN_FARCE" = "1" ]] ; then
    local DEST_FARCE=$DEST_TOPDIR/farce && \
(
    cat << EOF
	@extras/do_copy_files "$PRUNEPATH" $ROOT_DIR $DEST_FARCE/$ITERATION >>logs/$ITERATION.log 2>&1 && \\
	extras/filelist $DEST_FARCE/$ITERATION $DEST_FARCE/filelist-$ITERATION >>logs/$ITERATION.log 2>&1
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
  echo -e "\t@extras/do_ica_work $1 $2 $ICALOGDIR $3 >>logs/$ITERATION.log 2>&1" >> $MKFILE.tmp
}

#----------------------------------#
wrt_do_farce_work() {              #
#----------------------------------#
  local OUTPUT=$FARCELOGDIR/${1}_V_${2}
  local PREDIR=$3/$1
  local PREFILE=$3/filelist-$1
  local ITEDIR=$3/$2
  local ITEFILE=$3/filelist-$2
  echo -e "\t@extras/farce --directory $OUTPUT $PREDIR $PREFILE $ITEDIR $ITEFILE >>logs/$ITERATION.log 2>&1" >> $MKFILE.tmp
}

#----------------------------------#
wrt_logs() {                       #
#----------------------------------#
  local ITERATION=iteration-$1

(
    cat << EOF
	@pushd logs 1> /dev/null && \\
	mkdir $ITERATION && \\
	mv ${LOGS} $ITERATION && \\
	popd 1> /dev/null
	@touch \$@ && \\
        sleep .25 && \\
	echo " "\$(BOLD)Target \$(BLUE)\$@ \$(BOLD)OK && \\
	echo --------------------------------------------------------------------------------\$(WHITE)
EOF
) >> $MKFILE.tmp
}
