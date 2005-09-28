<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- XSLT stylesheet to create shell scripts from LFS books. -->

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

  <xsl:template match="sect1">
    <xsl:if test="count(descendant::screen/userinput) &gt; 0 and
      count(descendant::screen/userinput) &gt; count(descendant::screen[@role='nodump'])">
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
        <xsl:text>#!/bin/sh&#xA;&#xA;</xsl:text>
        <xsl:apply-templates select=".//screen"/>
      </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="screen">
    <xsl:if test="child::* = userinput">
      <xsl:choose>
        <xsl:when test="@role = 'nodump'"/>
        <xsl:otherwise>
          <xsl:apply-templates select="userinput"/>
          <xsl:if test="position() != last() and
              not(contains(string(),'EOF'))">
            <xsl:text> &amp;&amp;</xsl:text>
          </xsl:if>
          <xsl:text>&#xA;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:text>**EDITME</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>EDITME**</xsl:text>
  </xsl:template>

</xsl:stylesheet>
