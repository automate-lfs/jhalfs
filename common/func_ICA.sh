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

# Acknowledgment:
#  The following code is a modified version of an original work written by
#  Greg Schafer for the "DIY Linux" project and is included here with his
#  permission.
#  ref: http://www.diy-linux.org
#
#
# ---------------------------------------------------------------------------- #
# Here are the ICA functions.
# ---------------------------------------------------------------------------- #
#
# Here we prepare for the Iterative Comparison Analysis (ICA). Essentially, we
# copy most of our chroot phase files to a new location then perform some
# manipulations on the copied files to make diff comparisons easier. The steps
# involved are:-
#   (1) copy the whole tree (minus the PRUNEPATH defined below) to the CMP_DIR
#       location. Use tar as it seems like the most appropriate tool for copying
#       large directory trees around.
#   (2) delete all symlinks.
#   (3) gunzip all `*.gz' files.
#   (4) delete all hardlinked files (of course trying to leaving the "master"
#       intact)
#   (5) convert all `*.a' files (ar archives) into a directory of the same name
#       containing the unpacked object files.
#   (6) fully strip the whole lot (but being careful to strip only the debug
#       symbols from object `*.o' files).

#----------------------------------#
do_ica_prep() {                    #
#----------------------------------#
: <<inline_doc
    desc:

    usage:

    input vars:
    externals:  --
    modifies:   --
    returns:    --
    on error:
    on success:
inline_doc

  local CMP_DIR F L BN
  local ALL_FILES=/tmp/allfiles.$$
  local UNIQUE_FILES=/tmp/uniquefiles.$$
  local PRUNEPATH="$TT_PFX $PATCHES_DIR $SCRATCH_DIR $TARBALLS_DIR \
                  /dev /home /mnt /proc /root /sys /tmp /usr/src /lost+found"

  if [ ! -f "${STAMP_DIR}/icaprep" ]; then
    CMP_DIR="${SCRATCH_DIR}/cmp/iter${ITER}"
    test -d "$CMP_DIR" || mkdir -p $CMP_DIR

    echo -e "\n${BORDER}\n${CYAN}[ICA] - starting ICA preparation for\c"
    echo -e " Iteration ${ITER}.${OFF}\n"

    # Create a file that we can pass to tar as an "exclude list".
    # There might be an easier way to achieve tar exclusions? Strip
    # the leading /.
    for F in $PRUNEPATH; do
      echo ${F#*/} >> $TMP_FILE
    done

    echo -n "Copying files to ${CMP_DIR}... "
    cd /
    tar -X $TMP_FILE -cf - . | tar -C $CMP_DIR -xf - || {
	echo -e "\n\n${RED}ERROR:${OFF} tar copy failed!\n" >&2
	exit 1
	}
    echo "done."
    rm -f $TMP_FILE

    echo -n "Removing symbolic links in ${CMP_DIR}... "
    find $CMP_DIR -type l | xargs rm -f
    echo "done."

    echo -n "Gunzipping \".gz\" files in ${CMP_DIR}... "
    find $CMP_DIR -name '*.gz' | xargs gunzip
    echo "done."

    # This was a bit tricky. You'll probably have to do it by hand
    # to see what's actually going on. The "sort/uniq" part is
    # inspired from the example DirCmp script from the book "Shell
    # Programming Examples" by Bruce Blinn, published by Prentice
    # Hall. We are essentially using the `-ls' option of the find
    # utility to allow manipulations based on inode numbers.
    #
    # FIXME - this is a bit unreliable - rem out for now
    #echo -n "Removing hardlinked file copies in ${CMP_DIR}... "
    #find $CMP_DIR -ls | sort -n > $ALL_FILES
    #find $CMP_DIR -ls | sort -n -u > $UNIQUE_FILES
    #cat $UNIQUE_FILES $ALL_FILES | sort | uniq -u | awk '{ print $11 }' | xargs rm -f
    #rm -f $ALL_FILES $UNIQUE_FILES
    #echo "done."

    # ar archives contain date & time stamp info that causes us
    # grief when trying to find differences. Here we perform some
    # hackery to allow easy diffing. Essentially, replace each
    # archive with a dir of the same name and extract the object
    # files from the archive into this dir. Despite their names,
    # libieee.a & libmcheck.a are not actual ar archives.
    #
    echo -n "Extracting object files from \".a\" files in ${CMP_DIR}... "
    L=$(find $CMP_DIR -name '*.a' ! -name 'libieee.a' ! -name 'libmcheck.a')

    for F in $L; do
      mv $F ${F}.XX
      mkdir $F
      cd $F
      BN=${F##*/}
      ar x ../${BN}.XX || {
        echo -e "\n\n${RED}ERROR:${OFF} ar archive extraction failed!\n" >&2
        exit 1
	}
      rm -f ../${BN}.XX
    done
    echo "done."

    echo -n "Stripping (debug) symbols from \".o\" files in ${CMP_DIR}... "
    find $CMP_DIR -name '*.o' | xargs strip -p -g 2>/dev/null
    echo "done."

    echo -n "Stripping (all) symbols from files OTHER THAN \".o\" files in ${CMP_DIR}... "
    find $CMP_DIR ! -name '*.o' | xargs strip -p 2>/dev/null || :
    echo "done."

    echo -e "\n${CYAN}[ICA] - ICA preparation for Iteration ${ITER}\c"
    echo -e " complete.${OFF}\n${BORDER}"
    do_stamp icaprep
  fi
}


#----------------------------------#
do_ica_work() {                    #  Do the ICA grunt work.
#----------------------------------#
: <<inline_doc
    desc:

    usage:	do_ica_work 1 2
    		do_ica_work 2 3

    input vars: $1 iteration number to use
                $2 iteration number to use
    externals:  --
    modifies:   --
    returns:    --
    on error:
    on success:
inline_doc

  local ICA_DIR="${SCRATCH_DIR}/cmp"
  local RAWDIFF=/tmp/rawdiff.$$
  local REPORT="${SCRATCH_DIR}/logs/REPORT.${1}V${2}"

  cd $ICA_DIR

  echo -n "Diffing iter${1} and iter${2}... "
  diff -ur iter${1} iter${2} > $RAWDIFF || :
  echo "done."

  echo -e "The list of binary files that differ:\n" > $REPORT
  grep "iles.*differ$" $RAWDIFF >> $REPORT
  echo -e "\n" >> $REPORT

  echo -e "The list of files that exist \"only in\" 1 of the directories:\n" >> $REPORT

  if grep "^Only in" $RAWDIFF >/dev/null 2>&1; then
     grep "^Only in" $RAWDIFF >> $REPORT
  else
    echo NONE >> $REPORT
  fi

  grep -v "iles.*differ$" $RAWDIFF | grep -v "^Only in" > ${SCRATCH_DIR}/logs/${1}V${2}.ASCII.DIFF
  rm -f $RAWDIFF

}
