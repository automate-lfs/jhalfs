<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- XSLT stylesheet to create shell scripts from BLFS books. -->

  <!-- Run optional test suites? -->
  <xsl:param name="testsuite" select="0"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

  <xsl:template match="sect1">
    <xsl:if test="count(descendant::screen/userinput) &gt; 0 and
      count(descendant::screen/userinput) &gt; count(descendant::screen[@role='nodump'])">
        <!-- The dirs names -->
      <xsl:variable name="pi-dir" select="../../processing-instruction('dbhtml')"/>
      <xsl:variable name="pi-dir-value" select="substring-after($pi-dir,'dir=')"/>
      <xsl:variable name="quote-dir" select="substring($pi-dir-value,1,1)"/>
      <xsl:variable name="dirname" select="substring-before(substring($pi-dir-value,2),$quote-dir)"/>
        <!-- The file names -->
      <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
      <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
      <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
        <!-- Package variables -->
      <xsl:param name="package" select="sect1info/keywordset/keyword[@role='package']"/>
      <xsl:param name="ftpdir" select="sect1info/keywordset/keyword[@role='ftpdir']"/>
      <xsl:param name="unpackdir" select="sect1info/keywordset/keyword[@role='unpackdir']"/>
        <!-- Creating dirs and files -->
      <exsl:document href="{$dirname}/{$filename}" method="text">
        <xsl:text>#!/bin/sh&#xA;set -e&#xA;&#xA;</xsl:text>
        <xsl:apply-templates select="sect2 | screen">
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="ftpdir" select="$ftpdir"/>
          <xsl:with-param name="unpackdir" select="$unpackdir"/>
        </xsl:apply-templates>
        <xsl:if test="sect2[@role='package']">
          <xsl:text>cd ~/sources/</xsl:text>
          <xsl:value-of select="$ftpdir"/>
          <xsl:text>&#xA;rm -rf </xsl:text>
          <xsl:value-of select="$unpackdir"/>
          <xsl:text>&#xA;&#xA;</xsl:text>
        </xsl:if>
        <xsl:text>exit</xsl:text>
      </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="sect2">
    <xsl:param name="package" select="foo"/>
    <xsl:param name="ftpdir" select="foo"/>
    <xsl:param name="unpackdir" select="foo"/>
    <xsl:choose>
      <xsl:when test="@role = 'package'">
        <xsl:apply-templates select="para"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>mkdir -p ~/sources/</xsl:text>
        <xsl:value-of select="$ftpdir"/>
        <xsl:text>&#xA;cd ~/sources/</xsl:text>
        <xsl:value-of select="$ftpdir"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:apply-templates select="itemizedlist/listitem/para">
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="ftpdir" select="$ftpdir"/>
          <xsl:with-param name="unpackdir" select="$unpackdir"/>
        </xsl:apply-templates>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'installation'">
        <xsl:text>tar -xf </xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text>.*&#xA;cd </xsl:text>
        <xsl:value-of select="$unpackdir"/>
        <xsl:text>&#xA;</xsl:text>
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

  <xsl:template match="para">
    <xsl:choose>
     <xsl:when test="@role = 'required'">
       <xsl:text># REQUIRED: </xsl:text>
       <xsl:apply-templates select="xref"/>
       <xsl:text>&#xA;</xsl:text>
     </xsl:when>
     <xsl:when test="@role = 'recommended'">
       <xsl:text># RECOMMENDED: </xsl:text>
       <xsl:apply-templates select="xref"/>
       <xsl:text>&#xA;</xsl:text>
     </xsl:when>
     <xsl:when test="@role = 'optional'">
       <xsl:text># OPTIONAL: </xsl:text>
       <xsl:apply-templates select="xref"/>
       <xsl:text>&#xA;</xsl:text>
     </xsl:when>
     <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xref">
    <xsl:value-of select="@linkend"/>
    <xsl:text>&#x20;&#x20;</xsl:text>
  </xsl:template>

  <xsl:template match="itemizedlist/listitem/para">
    <xsl:param name="package" select="foo"/>
    <xsl:param name="ftpdir" select="foo"/>
    <xsl:param name="unpackdir" select="foo"/>
    <xsl:choose>
      <xsl:when test="contains(string(),'HTTP')">
        <xsl:text>wget </xsl:text>
        <xsl:value-of select="ulink/@url"/>
        <xsl:text> || \&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'FTP')">
        <xsl:text>wget </xsl:text>
        <xsl:value-of select="ulink/@url"/>
        <xsl:text> || \&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'MD5')">
        <xsl:text>wget ftp://anduin.linuxfromscratch.org/BLFS/conglomeration/</xsl:text>
        <xsl:value-of select="$ftpdir"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text>.bz2&#xA;</xsl:text>
          <!-- Commented out due that we don't know where the package
          will be dowloaded from.
        <xsl:text>echo "</xsl:text>
        <xsl:value-of select="substring-after(string(),'sum: ')"/>
        <xsl:text>&#x20;&#x20;</xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text>" | md5sum -c -&#xA;</xsl:text>-->
      </xsl:when>
      <xsl:when test="contains(string(),'patch')">
        <xsl:text>wget </xsl:text>
        <xsl:value-of select="ulink/@url"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

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
    <xsl:if test="$testsuite != '0' and
            (contains(string(),'test') or
            contains(string(),'check'))">
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
