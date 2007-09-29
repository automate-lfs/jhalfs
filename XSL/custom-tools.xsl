<?xml version="1.0"?>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">


    <!-- Create a custom tools directory containing scripts
         to be run after the base system has been built -->
    <!-- See blfs-tool.xsl for exsl:document examples -->
  <xsl:template name="custom-tools">
      <!-- Fixed directory and ch_order values -->
    <xsl:variable name="basedir">custom-tools/20_</xsl:variable>
      <!-- Add an exsl:document block for each script to be created.
           This one is only a dummy example. You must replace "01" by
           the proper build order and "dummy" by the script name -->
    <exsl:document href="{$basedir}01-dummy" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE=dummy
PACKAGE=dummy
VERSION=0.0.0
TARBALL=dummy-0.0.0.tar.bz2
DOWNLOAD=http://www.example.com/sources/dummy-0.0.0.tar.bz2
MD5SUM=b0c2f10c23b1d529725c8f9c693858cf

PATCH="http://www.example.com/sources/dummy-0.0.0.fix1.patch 65c913efccffda4b9dc66e9002e8516e"
PATCH="http://www.example.com/sources/dummy-0.0.0.fix2.patch fb411aae8d1eb8a733bb1def9266f2ba"
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
  </xsl:template>

</xsl:stylesheet>
