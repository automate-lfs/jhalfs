<?xml version="1.0"?>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">


    <!-- Create a custom tools directory containing scripts
         to be run after the base system has been built -->
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
