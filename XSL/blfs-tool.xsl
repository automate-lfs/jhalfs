<?xml version="1.0"?>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">


    <!-- Create blfs-tool dependencies scripts -->
  <xsl:template name="blfs-tool">
      <!-- Fixed directory and ch_order values -->
    <xsl:variable name="basedir">blfs-tool-deps/30_</xsl:variable>
      <!-- libxml2 -->
    <exsl:document href="{$basedir}01-libxml2" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="libxml2"
PACKAGE="libxml2"
VERSION="2.6.29"
TARBALL="${PACKAGE}-${VERSION}.tar.gz"
DOWNLOAD="ftp://xmlsoft.org/libxml2/${TARBALL}"
MD5SUM="8b99b6e8b08e838438d9e6b639d79ebd"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
./configure --prefix=/usr
make
make install
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
      <!-- libxslt -->
    <exsl:document href="{$basedir}02-libxslt" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="libxslt"
PACKAGE="libxslt"
VERSION="1.1.21"
TARBALL="${PACKAGE}-${VERSION}.tar.gz"
DOWNLOAD="ftp://xmlsoft.org/libxslt/${TARBALL}"
MD5SUM="59fe34e85692f71df2a38c2ee291b3ca"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
./configure --prefix=/usr
make
make install
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
      <!-- tidy -->
    <exsl:document href="{$basedir}03-tidy" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="tidy"
PACKAGE="tidy"
VERSION="cvs_20070326"
TARBALL="${PACKAGE}-${VERSION}.tar.bz2"
DOWNLOAD="http://anduin.linuxfromscratch.org/files/BLFS/sources/${TARBALL}"
MD5SUM="468bfaa5cf917a8ecbe7834c13a61376"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
./configure --prefix=/usr
make
make install
make -C htmldoc install_apidocs
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
      <!-- unzip -->
    <exsl:document href="{$basedir}04-unzip" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="unzip"
PACKAGE="unzip"
VERSION="552"
TARBALL="${PACKAGE}${VERSION}.tar.gz"
DOWNLOAD="http://downloads.sourceforge.net/infozip/${TARBALL}"
MD5SUM="9d23919999d6eac9217d1f41472034a9"

PATCH1="http://www.linuxfromscratch.org/patches/blfs/svn/unzip-5.52-security_fix-1.patch 00ebf64fdda2ad54ddfc619f85f328bb"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
patch -Np1 -i ../unzip-5.52-security_fix-1.patch
make -f unix/Makefile LOCAL_UNZIP=-D_FILE_OFFSET_BITS=64 linux
make prefix=/usr install
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
      <!-- DocBook XML DTD -->
    <exsl:document href="{$basedir}05-docbook-xml" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="docbook-xml"
PACKAGE="docboo-xml"
VERSION="4.5"
TARBALL="${PACKAGE}-${VERSION}.zip"
DOWNLOAD="http://www.docbook.org/xml/4.5/${TARBALL}"
MD5SUM="03083e288e87a7e829e437358da7ef9e"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:text>
cd /sources
mkdir docbook-xml
cd docbook-xml
unzip ../docbook-xml-4.5.zip
install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5
install -v -d -m755 /etc/xml
chown -R root:root .
cp -v -af docbook.cat *.dtd ent/ *.mod \
    /usr/share/xml/docbook/xml-dtd-4.5
if [ ! -e /etc/xml/docbook ]; then
    xmlcatalog --noout --create /etc/xml/docbook
fi
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V4.5//EN" \
    "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" \
    /etc/xml/docbook
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" \
    /etc/xml/docbook
xmlcatalog --noout --add "public" \
    "-//OASIS//DTD XML Exchange Table Model 19990315//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" \
    /etc/xml/docbook
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" \
    /etc/xml/docbook
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" \
    /etc/xml/docbook
xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" \
    /etc/xml/docbook
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" \
    /etc/xml/docbook
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" \
    /etc/xml/docbook
xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" \
    /etc/xml/docbook
xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
if [ ! -e /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//ENTITIES DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//DTD DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
for DTDVERSION in 4.1.2 4.2 4.3 4.4
do
  xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
    /etc/xml/docbook
  xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook
  xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
  xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
done
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:text>
cd /sources
rm -rf docbook-xml
      </xsl:text>
      <xsl:call-template name="footer"/>
    </exsl:document>
      <!-- DocBook XSL (empty and commented-out, it's not required for now) -->
    <!--<exsl:document href="{$basedir}06-docbook-xsl" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="docbook-xsl"
PACKAGE="docbook-xsl"
VERSION=""
TARBALL="${PACKAGE}-${VERSION}.tar.bz2"
DOWNLOAD="http://prdownloads.sourceforge.net/docbook/${TARBALL}"
MD5SUM=""
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>-->
      <!--  -->
    <exsl:document href="{$basedir}07-gpm" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="gpm"
PACKAGE="gpm"
VERSION="1.20.1"
TARBALL="${PACKAGE}-${VERSION}.tar.bz2"
DOWNLOAD="ftp://ftp.linux.ee/pub/gentoo/distfiles/distfiles/${TARBALL}"
MD5SUM="2c63e827d755527950d9d13fe3d87692"

PATCH1="http://www.linuxfromscratch.org/patches/blfs/svn/gpm-1.20.1-segfault-1.patch 8c88f92990ba7613014fcd1db14ca7ac"
PATCH2="http://www.linuxfromscratch.org/patches/blfs/svn/gpm-1.20.1-silent-1.patch bf6cbefe20c6f15b587f19ebc1c8a37a"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
patch -Np1 -i ../gpm-1.20.1-segfault-1.patch
patch -Np1 -i ../gpm-1.20.1-silent-1.patch
./configure --prefix=/usr --sysconfdir=/etc
LDFLAGS="$LDFLAGS -lm" make
make install
cp -v conf/gpm-root.conf /etc
ldconfig
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
      <!--  -->
    <exsl:document href="{$basedir}08-lynx" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="lynx"
PACKAGE="lynx"
VERSION="2.8.6"
TARBALL="${PACKAGE}${VERSION}.tar.bz2"
DOWNLOAD="http://lynx.isc.org/release/${TARBALL}"
MD5SUM="dc80497b7dda6a28fd80404684d27548"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
./configure --prefix=/usr \
            --sysconfdir=/etc/lynx \
            --datadir=/usr/share/doc/lynx-2.8.6 \
            --with-zlib \
            --with-bzlib \
            --with-screen=ncursesw \
            --enable-locale-charset
make
make install-full
chgrp -v -R root /usr/share/doc/lynx-2.8.6/lynx_doc
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
      <!--  -->
    <exsl:document href="{$basedir}09-sudo" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="sudo"
PACKAGE="sudo"
VERSION="1.6.8p12"
TARBALL="${PACKAGE}-${VERSION}.tar.gz"
DOWNLOAD="http://anduin.linuxfromscratch.org/sources/BLFS/svn/s/${TARBALL}"
MD5SUM="b29893c06192df6230dd5f340f3badf5"

PATCH1="http://www.linuxfromscratch.org/patches/blfs/svn/sudo-1.6.8p12-envvar_fix-1.patch 454925aedfe054dff8fe0d03b209f986"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
patch -Np1 -i ../sudo-1.6.8p12-envvar_fix-1.patch
./configure --prefix=/usr --libexecdir=/usr/lib \
    --enable-noargs-shell --with-ignore-dot --with-all-insults \
    --enable-shell-sets-home
make
make install
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
      <!--  -->
    <exsl:document href="{$basedir}10-wget" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="wget"
PACKAGE="wget"
VERSION="1.10.2"
TARBALL="${PACKAGE}-${VERSION}.tar.gz"
DOWNLOAD="ftp://ftp.gnu.org/gnu/wget/${TARBALL}"
MD5SUM="795fefbb7099f93e2d346b026785c4b8"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
./configure --prefix=/usr --sysconfdir=/etc
make
make install
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
      <!--  -->
    <exsl:document href="{$basedir}11-subversion" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE="subversion"
PACKAGE="subversion"
VERSION="1.3.1"
TARBALL="${PACKAGE}-${VERSION}.tar.bz2"
DOWNLOAD="http://subversion.tigris.org/tarballs/${TARBALL}"
MD5SUM="07b95963968ae345541ca99d0e7bf082"
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
./configure --prefix=/usr \
            --without-berkeley-db \
            --with-installbuilddir=/usr/lib/apr-0
make
make install
rm doc/{Makefile,doxygen.conf}
find doc -type d -exec chmod 755 {} \;
find doc -type f -exec chmod 644 {} \;
install -v -m755 -d /usr/share/doc/subversion-1.3.1
cp -v -R doc/* /usr/share/doc/subversion-1.3.1
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
  </xsl:template>

</xsl:stylesheet>
