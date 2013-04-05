<?xml version="1.0" encoding="ISO-8859-1"?>

<!-- $Id:$ -->
<!-- Extracts minimal versions from LFS book host requirements,
     and generates a script containing statements of the
     form MIN_prog_VERSION=xx.yy.zz.
-->

<xsl:stylesheet
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      version="1.0">

  <xsl:output method="text"/>

  <xsl:template match="/sect1">
    <xsl:apply-templates select=".//listitem//emphasis"/>
  </xsl:template>

  <xsl:template match="emphasis">
    <xsl:text>local MIN_</xsl:text>
    <xsl:choose>
      <xsl:when test="contains(string(),' ')">
        <xsl:value-of select=
           "substring-before(substring-after(normalize-space(string()),
                                             ' '),
                             '-')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring-before(string(),'-')"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>_VER=</xsl:text>
    <xsl:value-of select="substring-after(string(),'-')"/>
    <xsl:text>
</xsl:text>
  </xsl:template>
</xsl:stylesheet>
