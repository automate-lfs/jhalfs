#!/bin/bash

#    $Id$

# Fills the tracking file with versions of LFS packages taken from an
# SVN repository, at either a given date or a given tag (argument $1).
#------
# Argument $1:
# $1 contains a tag or a date, to indicate which version of the LFS book
# to use. It may be empty, meaning to use whatever version is presently in
# lfs-xml.
#
# It is recognized as a tag if it begins with x.y, where 'x' is one or more
# digit(s), the '.' (dot) is mandatory, an 'y' is one or more digits. Anything
# after y is allowed (for example 7.6-systemd or 8.1-rc1).
#
# It is recognized as a date if it is exactly 8 digits. Then it is assumed that
# the format is YYYYMMDD.
#
# Note that there is no check that the tag or the date are valid. Svn errors
# out if the tag is not valid, and if the date is impossible (that is MM>12
# or DD>31), but it happily accepts YYYY=3018 (and updates to HEAD).
#------
# The tracking file is taken from Makefile in the same directory.

MYDIR=$( cd $(dirname $0); pwd )
LFS_XML=${MYDIR}/lfs-xml

if [ -z "$1" ]; then # use lfs-xml as is
    DO_COMMANDS=n
elif [ "$(echo $1 | sed 's/^[[:digit:]]\+\.[[:digit:]]\+//')" != "$1" ]
    then # tag
    DO_COMMANDS=y
    CURR_SVN=$(cd $LFS_XML; LANG=C svn info | sed -n 's/Relative URL: //p')
    CURR_REV=$(cd $LFS_XML; LANG=C svn info | sed -n 's/Revision: //p')
    BEG_COMMAND="(cd $LFS_XML; svn switch ^/tags/$1)"
    END_COMMAND="(cd $LFS_XML; svn switch $CURR_SVN@$CURR_REV)"
elif [ "$(echo $1 | sed 's/^[[:digit:]]\{8\}$//')" != "$1" ]; then # date
    DO_COMMANDS=y
    CURR_REV=$(cd $LFS_XML; LANG=C svn info | sed -n 's/Revision: //p')
    BEG_COMMAND="(cd $LFS_XML; svn update -r\\{$1\\})"
    END_COMMAND="(cd $LFS_XML; svn update -r$CURR_REV)"
else
    echo Bad format in $1: must be a x.y[-aaa] tag or a YYYYMMDD date
    exit 1
fi

if [ -f $MYDIR/Makefile ]; then
    TRACKING_DIR=$(sed -n 's/TRACKING_DIR[ ]*=[ ]*//p' $MYDIR/Makefile)
    TRACKFILE=${TRACKING_DIR}/instpkg.xml
else
    echo The directory where $0 resides does not contain a Makefile
    exit 1
fi

# We need to know the revision to generate the correct lfs-full...
if [ ! -r $MYDIR/revision ]; then
    echo $MYDIR/revision is not available
    exit 1
fi
REVISION=$(cat $MYDIR/revision)
#Debug
#echo BEG_COMMAND = $BEG_COMMAND
#echo Before BEG_COMMAND
#( cd $LFS_XML; LANG=C svn info )
#End debug

if [ "$DO_COMMANDS"=y ]; then
    echo Running: $BEG_COMMAND
    eval $BEG_COMMAND
fi

# Update code
LFS_FULL=/tmp/lfs-full.xml
echo Creating $LFS_FULL with information from $LFS_XML
echo "Processing LFS bootscripts..."
( cd $LFS_XML && bash process-scripts.sh )
echo "Adjusting LFS for revision $REVISION..."
xsltproc --nonet --xinclude                          \
         --stringparam profile.revision $REVISION       \
         --output /tmp/lfs-prof.xml         \
        $LFS_XML/stylesheets/lfs-xsl/profile.xsl \
        $LFS_XML/index.xml
echo "Validating the LFS book..."
xmllint --nonet --noent --postvalid \
        -o $LFS_FULL /tmp/lfs-prof.xml
rm -f $LFS_XML/appendices/*.script
( cd $LFS_XML && ./aux-file-data.sh $LFS_FULL )

echo Updating ${TRACKFILE} with information taken from $LFS_FULL
echo -n "Is it OK? yes/no (no): "
read ANSWER
#Debug
echo You answered $ANSWER
#End debug

if [ x$ANSWER = "xyes" ] ; then
    for pack in $(grep '<productname' $LFS_FULL |
                  sed 's/.*>\([^<]*\)<.*/\1/' |
                  sort | uniq); do
        if [ "$pack" = "libstdc++" ]; then continue; fi
        VERSION=$(grep -A1 ">$pack</product" $LFS_FULL |
                    head -n2 |
                    sed -n '2s/.*>\([^<]*\)<.*/\1/p')
#Debug
echo $pack: $VERSION
#End debug
        xsltproc --stringparam packages $MYDIR/packages.xml \
                 --stringparam package $pack \
                 --stringparam version $VERSION \
                 -o track.tmp \
                 $MYDIR/xsl/bump.xsl ${TRACKFILE}
        sed -i "s@PACKDESC@$MYDIR/packdesc.dtd@" track.tmp
        xmllint --format --postvalid track.tmp > ${TRACKFILE}
        rm track.tmp
    done
    VERSION=$(grep 'echo.*lfs-release' $LFS_FULL |
              sed 's/.*echo[ ]*\([^ ]*\).*/\1/')
#Debug
echo LFS-Release: $VERSION
#End debug
    xsltproc --stringparam packages $MYDIR/packages.xml \
             --stringparam package LFS-Release \
             --stringparam version $VERSION \
             -o track.tmp \
             $MYDIR/xsl/bump.xsl ${TRACKFILE}
    sed -i "s@PACKDESC@$MYDIR/packdesc.dtd@" track.tmp
    xmllint --format --postvalid track.tmp > ${TRACKFILE}
    rm track.tmp
fi
#Debug
#echo After BEG_COMMAND\; before END_COMMAND
#( cd $LFS_XML; LANG=C svn info )
#End debug


if [ "$DO_COMMANDS"=y ]; then
    echo Running: $END_COMMAND
    eval $END_COMMAND
fi

#Debug
#echo After END_COMMAND
#( cd $LFS_XML; LANG=C svn info )
#End debug
