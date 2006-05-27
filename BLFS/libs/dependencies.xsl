<?xml version="1.0"?>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output method="text"/>

  <xsl:param name="dependencies" select="2"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//para[@role='optional']"/>
    <xsl:apply-templates select="//para[@role='recommended']"/>
    <xsl:apply-templates select="//para[@role='required']"/>
  </xsl:template>

  <xsl:template match="//text()"/>

  <xsl:template match="para[@role='required']">
    <xsl:apply-templates select="xref">
      <xsl:sort select="position()" order="descending"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="para[@role='recommended']">
    <xsl:if test="$dependencies != '1'">
      <xsl:apply-templates select="xref">
        <xsl:sort select="position()" order="descending"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <xsl:template match="para[@role='optional']">
    <xsl:if test="$dependencies = '3'">
      <xsl:apply-templates select="xref">
        <xsl:sort select="position()" order="descending"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xref">
    <xsl:value-of select="@linkend"/>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
