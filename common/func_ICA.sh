# $Id$

#----------------------------------#
wrt_ica_targets() {                #
#----------------------------------#
  local ICA_rebuild=$1
  wrt_ica_rebuild "$ICA_rebuild"
  wrt_iterations  "$ICA_rebuild"
}

#----------------------------------#
wrt_ica_rebuild() {                #
#----------------------------------#
  local ICA_rebuild=$1
(
    cat << EOF
ICA_rebuild:  $ICA_rebuild

EOF
) >> $MKFILE
}

#----------------------------------#
wrt_iterations() {                 #
#----------------------------------#
  local ICA_rebuild=$1

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
	mv $ICA_rebuild $ITERATION && \\
	popd
	@rm -f $ICA_rebuild
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
	cp $ICA_rebuild iteration-last && \\
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
	mv $ICA_rebuild $ITERATION && \\
	popd
	@rm -f $ICA_rebuild
	@touch \$@

EOF
) >> $MKFILE
      PREV=$ITERATION
    fi
  done
}
