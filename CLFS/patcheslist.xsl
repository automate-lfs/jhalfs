<?xml version='1.0' encoding='ISO-8859-1'?>

<!--$Id$ -->
<!-- Get list of patches from the CLFS Book -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//ulink"/>
  </xsl:template>

  <xsl:template match="ulink">
      <!-- Patches. Match only the patches and skip possible duplicated
      URLs due that may be splitted for PDF output-->
    <xsl:if test="contains(@url, '.patch')
            and not(ancestor-or-self::*/@condition = 'pdf')">
      <xsl:value-of select="@url"/>
      <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
