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
       test="descendant::screen/userinput[contains(string(),'&#xA;chroot') or
                                          starts-with(string(),'chroot')]">
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
      <xsl:apply-templates
           select=".//userinput[contains(string(),'&#xA;chroot') or
                                starts-with(string(),'chroot')]"/>
      <xsl:text>exit&#xA;</xsl:text>
    </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput">
    <xsl:call-template name="extract-chroot">
      <xsl:with-param name="instructions" select="string()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="extract-chroot">
    <xsl:param name="instructions" select="''"/>
    <xsl:choose>
      <xsl:when test="not(starts-with($instructions,'&#xA;chroot')) and
                      contains($instructions, '&#xA;chroot')">
        <xsl:call-template name="extract-chroot">
          <xsl:with-param name="instructions"
              select="substring(substring-after($instructions,
                                      substring-before($instructions,
                                                       '&#xA;chroot')),2)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($instructions,'\&#xA;')">
        <xsl:copy-of select="substring-before($instructions,'\&#xA;')"/>
        <xsl:text>\
</xsl:text>
        <xsl:call-template name="extract-chroot">
          <xsl:with-param name="instructions"
                          select="substring-after($instructions,'\&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($instructions,'&#xA;')">
        <xsl:copy-of select="substring-before($instructions,'&#xA;')"/>
        <xsl:text>
</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$instructions"/>
        <xsl:text>
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
