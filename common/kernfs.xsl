<?xml version="1.0" encoding="ISO-8859-1"?>


<xsl:stylesheet
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      version="1.0">

  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//userinput[contains(string(),'--bind') or
                                             contains(string(),'/proc') or
                                             contains(string(),'readlink')]"/>
  </xsl:template>

  <xsl:template match="userinput">
    <xsl:apply-templates/>
    <xsl:text>
</xsl:text>
  </xsl:template>

</xsl:stylesheet>
