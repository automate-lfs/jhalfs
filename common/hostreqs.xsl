<?xml version="1.0" encoding="ISO-8859-1"?>

<!-- $Id$ -->
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
<!-- We assume that what is emphasized is in the form:
aa...aa-dccsaaa (a anything except @, - "dash", d digit,
                 c anything except space, s space) 
or
aa...aasdccsaaa
This means we have to replace digits with @, and look for '-@'
or ' @' -->
    <xsl:variable name="normalized-string"
                  select="translate(normalize-space(string()),
                                                    '0123456789',
                                                    '@@@@@@@@@@')"/>
    <xsl:variable name="begin-ver">
      <xsl:choose>
        <xsl:when test="contains($normalized-string,' @')">
          <xsl:value-of select="string-length(substring-before($normalized-string,' @'))+1"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="string-length(substring-before($normalized-string,'-@'))+1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="remaining-part"
                  select="substring($normalized-string,number($begin-ver)+1)"/>

    <xsl:variable name="end-ver">
      <xsl:choose>
        <xsl:when test="contains($remaining-part,' ')">
           <xsl:value-of
             select="string-length(substring-before($remaining-part,' '))"/>
        </xsl:when>
        <xsl:otherwise>
           <xsl:value-of
             select="string-length($remaining-part)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:text>local MIN_</xsl:text>
    <xsl:choose>
      <xsl:when test="contains(string(),'Kernel')">
        <xsl:text>Linux</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'GLIBC')">
        <xsl:text>Glibc</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'XZ')">
        <xsl:text>Xz</xsl:text>
      </xsl:when>
      <xsl:otherwise>
<!-- We assume that there are no dash nor space in other names -->
        <xsl:value-of select="substring(string(),1,number($begin-ver)-1)"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>_VER=</xsl:text>
    <xsl:value-of select="substring(string(),number($begin-ver)+1,$end-ver)"/>
    <xsl:text>
</xsl:text>
  </xsl:template>
</xsl:stylesheet>
