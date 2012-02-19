# $Id$
# function for packing and installing a tree. We only have access
# to variables PKGDIR and PKG_DEST

packInstall() {

local PCKGVRS=$(basename $PKGDIR)
local TGTPKG=$(basename $PKG_DEST)
local PACKAGE=$(echo ${TGTPKG} | sed 's/^[0-9]\{3\}-//' |
           sed 's/^[0-9]\{1\}-//')
case $PCKGVRS in
  expect*|tcl*) local VERSION=$(echo $PCKGVRS | sed 's/^[^0-9]*//') ;;
  vim*|unzip*) local VERSION=$(echo $PCKGVRS | sed 's/^[^0-9]*\([0-9]\)\([0-9]\)/\1.\2/') ;;
  tidy*) local VERSION=$(echo $PCKGVRS | sed 's/^[^0-9]*\([0-9]*\)/\1cvs/') ;;
  docbook-xml) local VERSION=4.5 ;;
  *) local VERSION=$(echo ${PCKGVRS} | sed 's/^.*-\([0-9]\)/\1/');;
esac
local ARCHIVE_NAME=$(dirname ${PKGDIR})/${PACKAGE}_${VERSION}.deb
case $(uname -m) in
  x86_64) local ARCH=amd64 ;;
  *) local ARCH=i386 ;;
esac

pushd $PKG_DEST
rm -fv ./usr/share/info/dir
mkdir DEBIAN
cat > DEBIAN/control <<EOF
Package: $PACKAGE
Version: $VERSION
Maintainer: Pierre Labastie <lnimbus@club-internet.fr>
Description: $PACKAGE
Architecture: $ARCH
EOF
dpkg-deb -b . $ARCHIVE_NAME
dpkg -i $ARCHIVE_NAME
mv -v $ARCHIVE_NAME /var/lib/packages
popd
}
