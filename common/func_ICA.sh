# $Id$

#----------------------------------#
wrt_ica_targets() {                #
#----------------------------------#

  for ((N=1; N <= ITERATIONS ; N++)) ; do # Double parentheses,
                                          # and "ITERATIONS" with no "$".
    ITERATION=iteration-$N
    if [ "$N" = "1" ] ; then
      echo "$ITERATION:  chapter6" >> $MKFILE
      echo -e "\t@\$(call echo_message, Building)" >> $MKFILE
      wrt_ica_work       "$ITERATION"
      wrt_logs_and_clean "$ITERATION"
    else
      wrt_system_build $N
      echo "iteration-last:  $PREV  system_build_$N" >> $MKFILE
      echo -e "\t@\$(call echo_message, Building)" >> $MKFILE
      wrt_ica_work       "$ITERATION" "$PREV"
      if [ "$N" = "$ITERATIONS" ] ; then
        wrt_logs           "$ITERATION"
      else
        wrt_logs_and_clean "$ITERATION"
      fi
    fi
    PREV=$ITERATION
  done
}

#----------------------------------#
wrt_system_build() {               #
#----------------------------------#
  local RUN=$1

  # Placeholder for now
}

#----------------------------------#
wrt_ica_work() {                   #
#----------------------------------#
  local ITERATION=$1
  local      PREV=$2
  local PRUNEPATH="/dev /home /jhalfs /lost+found /media /mnt /opt /proc \
/sources /root /srv /sys /tmp /tools /usr/local /usr/src /var/log/paco"

  if [[ "$PROGNAME" = "clfs" ]] && [[ "$METHOD" = "boot" ]] ; then
    local    ROOT_DIR=/
    local DEST_TOPDIR=/jhalfs
    local   ICALOGDIR=/jhalfs/logs/ICA
    local FARCELOGDIR=/jhalfs/logs/farce
  else
    local    ROOT_DIR=$BUILDDIR
    local DEST_TOPDIR=$BUILDDIR/jhalfs
  fi

  if [[ "$RUN_ICA" = "1" ]] ; then
    local DEST_ICA=$DEST_TOPDIR/ICA && \
(
    cat << EOF
	@extras/do_copy_files "$PRUNEPATH" $ROOT_DIR $DEST_ICA/$ITERATION && \\
	extras/do_ica_prep $DEST_ICA/$ITERATION
EOF
) >> $MKFILE
    if [[ "$ITERATION" != "iteration-1" ]] ; then
      wrt_do_ica_work "$PREV" "$ITERATION" "$DEST_ICA"
    fi
  fi

  if [[ "$RUN_FARCE" = "1" ]] ; then
    local DEST_FARCE=$DEST_TOPDIR/farce && \
(
    cat << EOF
	@extras/do_copy_files "$PRUNEPATH" $ROOT_DIR $DEST_FARCE/$ITERATION && \\
	extras/filelist $DEST_FARCE/$ITERATION $DEST_FARCE/$ITERATION.filelist
EOF
) >> $MKFILE
    if [[ "$ITERATION" != "iteration-1" ]] ; then
      wrt_do_farce_work "$PREV" "$ITERATION" "$DEST_FARCE"
    fi
  fi
}

#----------------------------------#
wrt_do_ica_work() {                #
#----------------------------------#
  echo -e "\t@extras/do_ica_work $1 $2 $ICALOGDIR $3" >> $MKFILE
}

#----------------------------------#
wrt_do_farce_work() {                    #
#----------------------------------#
  local OUTPUT=$FARCELOGDIR/${1}_V_${2}
  local PREDIR=$3/$1
  local PREFILE=$3/$1.filelist
  local ITEDIR=$3/$2
  local ITEFILE=$3/$2.filelist
  echo -e "\t@extras/farce --directory $OUTPUT $PREDIR $PREFILE $ITEDIR $ITEFILE" >> $MKFILE
}

#----------------------------------#
wrt_logs_and_clean() {             #
#----------------------------------#
  local ITERATION=$1

(
    cat << EOF
	@pushd logs && \\
	mkdir $ITERATION && \\
	mv $system_rebuild $ITERATION && \\
	popd
	@rm -f $system_rebuild
	@touch \$@

EOF
) >> $MKFILE
}

#----------------------------------#
wrt_logs() {             #
#----------------------------------#
  local ITERATION=$1

(
    cat << EOF
	@pushd logs && \\
	mkdir $ITERATION && \\
	cp $system_rebuild $ITERATION && \\
	popd
	@touch \$@

EOF
) >> $MKFILE
}
