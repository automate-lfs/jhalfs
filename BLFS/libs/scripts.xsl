<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- $Id$ -->

<!-- XSLT stylesheet to create shell scripts from BLFS books. -->

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

<!--=================== Master chunks code ======================-->

  <xsl:template match="sect1">
    <xsl:if test="@id != 'locale-issues' and
                  (count(descendant::screen/userinput) &gt; 0 and
                  count(descendant::screen/userinput) &gt;
                  count(descendant::screen[@role='nodump']))">
        <!-- The file names -->
      <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
      <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
      <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
        <!-- Package variables BROKEN Need be fixed -->
      <xsl:param name="package" select="sect1info/keywordset/keyword[@role='package']"/>
      <xsl:param name="ftpdir" select="sect1info/keywordset/keyword[@role='ftpdir']"/>
        <!-- The build order -->
      <xsl:variable name="position" select="position()"/>
      <xsl:variable name="order">
        <xsl:choose>
          <xsl:when test="string-length($position) = 1">
            <xsl:text>00</xsl:text>
            <xsl:value-of select="$position"/>
          </xsl:when>
          <xsl:when test="string-length($position) = 2">
            <xsl:text>0</xsl:text>
            <xsl:value-of select="$position"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$position"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
        <!-- Creating dirs and files -->
      <exsl:document href="{$order}-{$filename}" method="text">
        <xsl:text>#!/bin/sh&#xA;set -e&#xA;&#xA;</xsl:text>
        <xsl:apply-templates select="sect2 | .//screen">
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="ftpdir" select="$ftpdir"/>
        </xsl:apply-templates>
        <xsl:if test="sect2[@role='package']">
          <xsl:text>cd ~/sources/</xsl:text>
          <xsl:value-of select="$ftpdir"/>
          <xsl:text>&#xA;rm -rf $UNPACKDIR&#xA;&#xA;</xsl:text>
        </xsl:if>
        <xsl:text>exit</xsl:text>
      </exsl:document>
    </xsl:if>
  </xsl:template>

<!--======================= Sub-sections code =======================-->

  <xsl:template match="sect2">
    <xsl:param name="package" select="foo"/>
    <xsl:param name="ftpdir" select="foo"/>
    <xsl:choose>
      <xsl:when test="@role = 'package'">
        <xsl:text>mkdir -p ~/sources/</xsl:text>
        <xsl:value-of select="$ftpdir"/>
        <xsl:text>&#xA;cd ~/sources/</xsl:text>
        <xsl:value-of select="$ftpdir"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:apply-templates select="itemizedlist/listitem/para">
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="ftpdir" select="$ftpdir"/>
        </xsl:apply-templates>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'installation'">
        <xsl:text>tar -xvf </xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text> > /tmp/unpacked&#xA;</xsl:text>
        <xsl:text>UNPACKDIR=`head -n1 /tmp/unpacked | sed 's@^./@@;s@/.*@@'`&#xA;</xsl:text>
        <xsl:text>cd $UNPACKDIR&#xA;</xsl:text>
        <xsl:apply-templates select=".//screen | .//para/command"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'configuration'">
        <xsl:apply-templates select=".//screen"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

<!--==================== Download code =======================-->

  <xsl:template match="itemizedlist/listitem/para">
    <xsl:param name="package" select="foo"/>
    <xsl:param name="ftpdir" select="foo"/>
    <xsl:choose>
      <xsl:when test="contains(string(),'HTTP')">
        <!-- SRC_ARCHIVE may have subdirectories or not -->
        <xsl:text>cp $SRC_ARCHIVE/</xsl:text>
        <xsl:value-of select="$ftpdir"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text> || \&#xA;</xsl:text>
        <xsl:text>cp $SRC_ARCHIVE/</xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text> || \&#xA;</xsl:text>
        <!-- The FTP_SERVER mirror -->
        <xsl:text>wget $FTP_SERVER/BLFS/conglomeration/</xsl:text>
        <xsl:value-of select="$ftpdir"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text> || \&#xA;</xsl:text>
        <!-- Upstream HTTP URL -->
        <xsl:text>wget </xsl:text>
        <xsl:value-of select="ulink/@url"/>
        <xsl:text> || \&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'FTP')">
        <!-- Upstream FTP URL -->
        <xsl:text>wget </xsl:text>
        <xsl:value-of select="ulink/@url"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'MD5')">
        <xsl:text>echo "</xsl:text>
        <xsl:value-of select="substring-after(string(),'sum: ')"/>
        <xsl:text>&#x20;&#x20;</xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text>" | md5sum -c -&#xA;</xsl:text>
      </xsl:when>
      <!-- Patches. Need be veryfied -->
      <xsl:when test="contains(string(),'patch')">
        <xsl:text>wget </xsl:text>
        <xsl:value-of select="ulink/@url"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

<!--======================== Commands code ==========================-->

  <xsl:template match="screen">
    <xsl:if test="child::* = userinput">
      <xsl:choose>
        <xsl:when test="@role = 'nodump'"/>
        <xsl:otherwise>
          <xsl:if test="@role = 'root'">
            <xsl:text>sudo </xsl:text>
          </xsl:if>
          <xsl:apply-templates select="userinput" mode="screen"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="para/command">
    <xsl:if test="(contains(string(),'test') or
            contains(string(),'check'))">
      <xsl:text>#</xsl:text>
      <xsl:value-of select="substring-before(string(),'make')"/>
      <xsl:text>make -k</xsl:text>
      <xsl:value-of select="substring-after(string(),'make')"/>
      <xsl:text> || true&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput" mode="screen">
    <xsl:apply-templates/>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:text>**EDITME</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>EDITME**</xsl:text>
  </xsl:template>

</xsl:stylesheet>
