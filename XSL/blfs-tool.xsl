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
      <!-- One exsl:document block for each blfs-tool dependency
           TO BE WRITTEN -->
    <exsl:document href="{$basedir}01-dummy" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE=dummy
PACKAGE=dummy
VERSION=0.0.0
TARBALL=dummy-0.0.0.tar.bz2
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
./configure --prefix=/usr
make
make check
make install
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
  </xsl:template>

</xsl:stylesheet>
