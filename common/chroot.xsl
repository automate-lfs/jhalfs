<?xml version="1.0" encoding="ISO-8859-1"?>

<!-- $Id$ -->

<xsl:stylesheet
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:exsl="http://exslt.org/common"
      extension-element-prefixes="exsl"
      version="1.0">

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

  <xsl:template match="sect1">
    <xsl:if
         test="descendant::screen/userinput[starts-with(string(),'chroot')]">
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
      <exsl:document href="{$order}-{$filename}" method="text">
        <xsl:text>#!/bin/bash&#xA;</xsl:text>
      <xsl:apply-templates select=".//userinput[starts-with(string(),'chroot')]"/>
      <xsl:text>exit&#xA;</xsl:text>
    </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput">
    <xsl:apply-templates/>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
