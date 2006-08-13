<?xml version='1.0' encoding='ISO-8859-1'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                version="1.0">

<!-- $Id$ -->

  <!-- NOTE: the base dir (blfs-xml) is set to the proper dir
  via a sed in ./blfs -->
  <xsl:import href="../blfs-xml/stylesheets/blfs-chunked.xsl"/>

  <xsl:param name="mail_server" select="sendmail"/>

  <xsl:param name="xwindow" select="xorg7"/>

     <!-- Template from BLFS_XML/stylesheets/xhtml/lfs-xref.xsl.-->
  <xsl:template match="xref" name="xref">

    <!-- IDs that need be remaped to the proper file -->
    <xsl:variable name="linkend">
      <xsl:choose>
        <xsl:when test="@linkend = 'alsa'">
          <xsl:text>alsa-lib</xsl:text>
        </xsl:when>
        <xsl:when test="@linkend = 'arts'">
          <xsl:text>aRts</xsl:text>
        </xsl:when>
        <xsl:when test="@linkend = 'kde'">
          <xsl:text>kdelibs</xsl:text>
        </xsl:when>
        <xsl:when test="@linkend = 'server-mail'">
          <xsl:value-of select="$mail_server"/>
        </xsl:when>
        <xsl:when test="@linkend = 'x-window-system'">
          <xsl:value-of select="$xwindow"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@linkend"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="targets" select="key('id',$linkend)"/>
    <!-- -->

    <xsl:variable name="target" select="$targets[1]"/>
    <xsl:variable name="refelem" select="local-name($target)"/>
    <xsl:variable name="role" select="@role"/>
    <xsl:call-template name="check.id.unique">
      <xsl:with-param name="linkend" select="$linkend"/>
    </xsl:call-template>
    <xsl:call-template name="anchor"/>
    <xsl:choose>

      <!-- Dead links -->
      <xsl:when test="count($target) = 0">
        <b>
          <xsl:value-of select="@linkend"/>
        </b>
        <tt>
          <xsl:text> (in the full book)</xsl:text>
        </tt>
      </xsl:when>
      <!-- -->

      <xsl:when test="$target/@xreflabel">
        <a>
          <xsl:attribute name="href">
            <xsl:call-template name="href.target">
              <xsl:with-param name="object" select="$target"/>
            </xsl:call-template>
          </xsl:attribute>
          <xsl:call-template name="xref.xreflabel">
            <xsl:with-param name="target" select="$target"/>
          </xsl:call-template>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="href">
          <xsl:call-template name="href.target">
            <xsl:with-param name="object" select="$target"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:apply-templates select="$target" mode="xref-to-prefix"/>
        <a href="{$href}">
          <xsl:if test="$target/title or $target/*/title">
            <xsl:attribute name="title">
              <xsl:apply-templates select="$target" mode="xref-title"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="$target" mode="xref-to">
            <xsl:with-param name="referrer" select="."/>
            <xsl:with-param name="role" select="$role"/>
            <xsl:with-param name="xrefstyle">
              <xsl:value-of select="@xrefstyle"/>
            </xsl:with-param>
          </xsl:apply-templates>
        </a>
        <xsl:apply-templates select="$target" mode="xref-to-suffix"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
