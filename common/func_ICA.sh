# $Id$

#----------------------------------#
wrt_ica_targets() {                #
#----------------------------------#
  local system_rebuild=$1
  wrt_system_rebuild "$system_rebuild"
  wrt_iterations  "$system_rebuild"
}

#----------------------------------#
wrt_system_rebuild() {                #
#----------------------------------#
  local system_rebuild=$1
(
    cat << EOF
system_rebuild:  $system_rebuild

EOF
) >> $MKFILE
}

#----------------------------------#
wrt_iterations() {                 #
#----------------------------------#
  local system_rebuild=$1

  for ((N=1; N <= ITERATIONS ; N++)) ; do # Double parentheses,
                                          # and "ITERATIONS" with no "$".
   ITERATION=iteration-$N
   if [ "$N" = "1" ] ; then
(
    cat << EOF
$ITERATION:  chapter06
	@do_ica_prep
	@pushd logs && \\
	mkdir $ITERATION && \\
	mv $system_rebuild $ITERATION && \\
	popd
	@rm -f $system_rebuild
	@touch \$@

EOF
) >> $MKFILE
      PREV=$ITERATION
    elif [ "$N" = "$ITERATIONS" ] ; then
(
    cat << EOF
iteration-last: $PREV  ICA_rebuild
	@do_ica_prep
	@pushd logs && \\
	mkdir iteration-last && \\
	cp $system_rebuild iteration-last && \\
	popd
	@do_ica_work
	@touch \$@

EOF
) >> $MKFILE
    else
(
    cat << EOF
$ITERATION: $PREV  ICA_rebuild
	@do_ica_prep
	@pushd logs && \\
	mkdir $ITERATION && \\
	mv $system_rebuild $ITERATION && \\
	popd
	@rm -f $system_rebuild
	@touch \$@

EOF
) >> $MKFILE
      PREV=$ITERATION
    fi
  done
}
