<?xml version='1.0' encoding='ISO-8859-1'?>

<!-- Get list of patch files from the BLFS Book -->
<!-- $LastChangedBy$ -->
<!-- $Date$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output method="text"/>

  <!-- No text needed -->
  <xsl:template match="//text()">
    <xsl:text/>
  </xsl:template>

  <!-- Just grab the url from the ulink tags that have .patch in the name -->
  <xsl:template match="//ulink">
    <xsl:if test="contains(@url, '.patch') or contains(@url, '.patch.gz') and contains(@url, 'linuxfromscratch')">
       <xsl:value-of select="@url"/>
       <xsl:text>&#x0a;</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
