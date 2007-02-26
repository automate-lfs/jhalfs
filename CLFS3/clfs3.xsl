<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [
 <!ENTITY % general-entities SYSTEM "FAKEDIR/general.ent">
  %general-entities;
]>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- XSLT stylesheet to create shell scripts from CLFS2 books. -->

  <!-- Install vim-lang package? -->
  <xsl:param name="vim-lang" select="y"/>

  <!-- Time zone -->
  <xsl:param name="timezone" select="GMT"/>

  <!-- Page size -->
  <xsl:param name="page" select="letter"/>

  <!-- Locale settings -->
  <xsl:param name="lang" select="C"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

  <xsl:template match="sect1">
    <xsl:choose>
      <xsl:when test="../@id='chapter-partitioning' or
                      ../@id='chapter-getting-materials' or
                      ../@id='chapter-final-preps'"/>
      <xsl:otherwise>
        <xsl:if test="count(descendant::screen/userinput) &gt; 0 and
                      count(descendant::screen/userinput) &gt;
                      count(descendant::screen[@role='nodump'])">
            <!-- The dirs names -->
          <xsl:variable name="pi-dir" select="../processing-instruction('dbhtml')"/>
          <xsl:variable name="pi-dir-value" select="substring-after($pi-dir,'dir=')"/>
          <xsl:variable name="quote-dir" select="substring($pi-dir-value,1,1)"/>
          <xsl:variable name="dirname" select="substring-before(substring($pi-dir-value,2),$quote-dir)"/>
            <!-- The file names -->
          <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
          <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
          <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
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
          <exsl:document href="{$dirname}/{$order}-{$filename}" method="text">
            <xsl:text>#!/bin/bash&#xA;set +h&#xA;set -e&#xA;&#xA;</xsl:text>
            <!-- Set envars needed by uClibc -->
            <xsl:if test="@id='ch-cross-tools-uclibc'">
              <xsl:copy-of select="//sect1[@id='ch-cross-tools-toolchain']/screen"/>
              <xsl:text>&#xA;&#xA;</xsl:text>
            </xsl:if>
            <xsl:if test="sect2[@role='installation']">
              <xsl:text>cd $PKGDIR&#xA;</xsl:text>
            </xsl:if>
            <xsl:apply-templates select=".//para/userinput | .//screen"/>
            <xsl:text>exit</xsl:text>
          </exsl:document>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="screen">
    <xsl:if test="child::* = userinput and not(@role = 'nodump')">
      <xsl:apply-templates select="userinput" mode="screen"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="para/userinput"/>

  <xsl:template match="userinput" mode="screen">
    <xsl:choose>
      <!-- Estandarized package formats -->
      <xsl:when test="contains(string(),'tar.gz')">
        <xsl:value-of select="substring-before(string(),'tar.gz')"/>
        <xsl:text>tar.*</xsl:text>
        <xsl:value-of select="substring-after(string(),'tar.gz')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- Setting $LANG for /etc/profile -->
      <xsl:when test="ancestor::sect1[@id='ch-scripts-profile'] and
                contains(string(),'export LANG=')">
        <xsl:value-of select="substring-before(string(),'export LANG=')"/>
        <xsl:text>export LANG=</xsl:text>
        <xsl:value-of select="$lang"/>
        <xsl:value-of select="substring-after(string(),'charmap]')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- Compile the keymap into the kernel has been disabled -->
      <xsl:when test="contains(string(),'defkeymap')"/>
      <!-- Copying the kernel config file -->
      <xsl:when test="string() = 'make mrproper'">
        <xsl:text>make mrproper&#xA;</xsl:text>
        <xsl:text>cp -v ../kernel-config .config&#xA;</xsl:text>
      </xsl:when>
      <!-- No interactive commands are needed if the .config file is the proper one -->
      <xsl:when test="contains(string(),'menuconfig')"/>
      <!-- Don't stop on strip run -->
      <xsl:when test="contains(string(),'strip ')">
        <xsl:apply-templates/>
        <xsl:text> || true&#xA;</xsl:text>
      </xsl:when>
      <!-- The rest of commands -->
      <xsl:otherwise>
        <xsl:apply-templates/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:choose>
      <xsl:when test="ancestor::sect1[@id='ch-cross-tools-glibc']">
        <xsl:value-of select="$timezone"/>
      </xsl:when>
      <xsl:when test="ancestor::sect1[@id='ch-cross-tools-groff'] or
                      ancestor::sect1[@id='ch-system-groff']">
        <xsl:value-of select="$page"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
