<?xml version='1.0' encoding='ISO-8859-1'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output method="text"/>

  <!-- The FTP server used as fallback -->
  <xsl:param name="server">ftp://ftp.osuosl.org</xsl:param>

  <!-- The libc model used for HLFS -->
  <xsl:param name="model" select="glibc"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//ulink"/>
  </xsl:template>

  <xsl:template match="ulink">
      <!-- If some package don't have the predefined strings in their
      name, the next test must be fixed to match it also. Skip possible
      duplicated URLs due that may be splitted for PDF output -->
    <xsl:if test="(ancestor::varlistentry[@condition=$model]
                  or not(ancestor::varlistentry[@condition])) and
                  (contains(@url, '.tar.') or contains(@url, '.tgz')
                  or contains(@url, '.patch') or contains(@url, '.rules')) and
                  not(ancestor-or-self::*/@condition = 'pdf')">
      <!-- Extract the package name -->
      <xsl:variable name="package">
        <xsl:call-template name="package.name">
          <xsl:with-param name="url" select="@url"/>
        </xsl:call-template>
      </xsl:variable>
      <!-- Extract the directory for that package -->
      <xsl:variable name="cut"
                    select="translate(substring-after($package, '-'),
                    '0123456789', '0000000000')"/>
      <xsl:variable name="package2">
        <xsl:value-of select="substring-before($package, '-')"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$cut"/>
      </xsl:variable>
      <xsl:variable name="dirname" select="substring-before($package2, '-0')"/>
      <!-- Write the upstream URLs, except the redirected ones -->
      <xsl:if test="not(contains(@url,'?'))">
        <xsl:value-of select="@url"/>
      </xsl:if>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$server"/>
      <xsl:text>/pub/lfs/conglomeration/</xsl:text>
      <xsl:choose>
        <!-- Fix some directories. Test against package2 to be sure that we
        are matching the start of a package name, not a string in a patch name -->
        <xsl:when test="contains($package2, 'bash')">
          <xsl:text>bash/</xsl:text>
        </xsl:when>
        <xsl:when test="contains($package2, 'gcc')">
          <xsl:text>gcc/</xsl:text>
        </xsl:when>
        <xsl:when test="contains($package2, 'glibc')">
          <xsl:text>glibc/</xsl:text>
        </xsl:when>
        <xsl:when test="contains($package2, 'tcl')">
          <xsl:text>tcl/</xsl:text>
        </xsl:when>
        <xsl:when test="contains($package2, 'uClibc')">
          <xsl:text>uClibc/</xsl:text>
        </xsl:when>
        <xsl:when test="contains($package2, 'udev')">
          <xsl:text>udev/</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$dirname"/>
          <xsl:text>/</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="$package"/>
      <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="package.name">
    <xsl:param name="url"/>
    <xsl:choose>
      <xsl:when test="contains($url, '/')">
        <xsl:call-template name="package.name">
          <xsl:with-param name="url" select="substring-after($url, '/')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($url, '?')">
            <xsl:value-of select="substring-before($url, '?')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$url"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
