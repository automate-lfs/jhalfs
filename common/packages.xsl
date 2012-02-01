<?xml version='1.0' encoding='ISO-8859-1'?>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output method="text"/>

  <!-- The libc model used for HLFS -->
  <xsl:param name="model" select="glibc"/>

  <!-- The kernel series used for HLFS -->
  <xsl:param name="kernel" select="2.6"/>

  <!-- Should we include a package manager -->
  <xsl:param name="pkgmngt" select="n"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//para"/>
    <xsl:if test="$pkgmngt='y'">
      <xsl:apply-templates
        select="document('packageManager.xml')//sect1[@id='package']//para"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="para">
    <xsl:if test="contains(string(),'Download:') and
                  (ancestor::varlistentry[@condition=$model]
                  or not(ancestor::varlistentry[@condition])) and
                  (ancestor::varlistentry[@vendor=$kernel]
                  or not(ancestor::varlistentry[@vendor]))">
      <xsl:call-template name="package_name">
        <xsl:with-param name="url" select="ulink/@url"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="package_name">
    <xsl:param name="url" select="foo"/>
    <xsl:variable name="sub-url" select="substring-after($url,'/')"/>
    <xsl:choose>
      <xsl:when test="contains($sub-url,'/')">
        <xsl:call-template name="package_name">
          <xsl:with-param name="url" select="$sub-url"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($sub-url,'.patch')"/>
          <xsl:when test="contains($sub-url,'?')">
            <xsl:value-of select="substring-before($sub-url,'?')"/>
            <xsl:text>&#xA;</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$sub-url"/>
            <xsl:text>&#xA;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
