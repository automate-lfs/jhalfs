<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- $Id$ -->

<!-- XSLT stylesheet to create shell scripts from "linear build" BLFS books. -->

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

<!--=================== Master chunks code ======================-->

  <xsl:template match="sect1">
    <xsl:if test="@id != 'locale-issues' and
                  (count(descendant::screen/userinput) &gt; 0 and
                  count(descendant::screen/userinput) &gt;
                  count(descendant::screen[@role='nodump']))">

        <!-- The file names -->
      <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
      <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
      <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>

        <!-- Package name (use "Download FTP" by default. If empty, use "Download HTTP" -->
      <xsl:param name="package">
        <xsl:choose>
          <xsl:when
            test="string-length(sect2[@role='package']/itemizedlist/listitem[2]/para/ulink/@url)
            &gt; '10'">
            <xsl:call-template name="package_name">
              <xsl:with-param name="url"
                select="sect2[@role='package']/itemizedlist/listitem[2]/para/ulink/@url"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="package_name">
              <xsl:with-param name="url"
                select="sect2[@role='package']/itemizedlist/listitem[1]/para/ulink/@url"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:param>

        <!-- FTP dir name -->
      <xsl:param name="ftpdir">
        <xsl:call-template name="ftp_dir">
          <xsl:with-param name="package" select="$package"/>
        </xsl:call-template>
      </xsl:param>

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

      <!-- Depuration code -->
      <xsl:message>
        <xsl:text>SCRIPT is </xsl:text>
        <xsl:value-of select="concat($order,'-',$filename)"/>
        <xsl:text>&#xA;   PACKAGE is </xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text>&#xA;    FTPDIR is </xsl:text>
        <xsl:value-of select="$ftpdir"/>
        <xsl:text>&#xA;&#xA;</xsl:text>
      </xsl:message>

        <!-- Creating the scripts -->
      <exsl:document href="{$order}-{$filename}" method="text">
        <xsl:text>#!/bin/sh&#xA;set -e&#xA;&#xA;</xsl:text>
        <xsl:choose>
          <!-- Package page -->
          <xsl:when test="sect2[@role='package']">
            <!-- Variables -->
            <xsl:text>SRC_ARCHIVE=$SRC_ARCHIVE&#xA;</xsl:text>
            <xsl:text>FTP_SERVER=$FTP_SERVER&#xA;&#xA;PACKAGE=</xsl:text>
            <xsl:value-of select="$package"/>
            <xsl:text>&#xA;PKG_DIR=</xsl:text>
            <xsl:value-of select="$ftpdir"/>
            <xsl:text>&#xA;&#xA;</xsl:text>
            <!-- Download code and build commands -->
            <xsl:apply-templates select="sect2">
              <xsl:with-param name="package" select="$package"/>
              <xsl:with-param name="ftpdir" select="$ftpdir"/>
            </xsl:apply-templates>
            <!-- Clean-up -->
            <xsl:text>cd ~/sources/$PKG_DIR&#xA;</xsl:text>
            <xsl:text>rm -rf $UNPACKDIR&#xA;&#xA;</xsl:text>
          </xsl:when>
          <!-- Non-package page -->
          <xsl:otherwise>
            <xsl:apply-templates select=".//screen"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>exit</xsl:text>
      </exsl:document>

    </xsl:if>
  </xsl:template>

<!--======================= Sub-sections code =======================-->

  <xsl:template match="sect2">
    <xsl:param name="package" select="foo"/>
    <xsl:param name="ftpdir" select="foo"/>
    <xsl:choose>
      <xsl:when test="@role = 'package'">
        <xsl:text>mkdir -p ~/sources/$PKG_DIR&#xA;</xsl:text>
        <xsl:text>cd ~/sources/$PKG_DIR&#xA;</xsl:text>
        <xsl:apply-templates select="itemizedlist/listitem/para">
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="ftpdir" select="$ftpdir"/>
        </xsl:apply-templates>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'installation'">
        <xsl:text>tar -xvf $PACKAGE > unpacked&#xA;</xsl:text>
        <xsl:text>UNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`&#xA;</xsl:text>
        <xsl:text>cd $UNPACKDIR&#xA;</xsl:text>
        <xsl:apply-templates select=".//screen | .//para/command"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'configuration'">
        <xsl:apply-templates select=".//screen"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

<!--==================== Download code =======================-->

  <xsl:template name="package_name">
    <xsl:param name="url" select="foo"/>
    <xsl:param name="sub-url" select="substring-after($url,'/')"/>
    <xsl:choose>
      <xsl:when test="contains($sub-url,'/')">
        <xsl:call-template name="package_name">
          <xsl:with-param name="url" select="$sub-url"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($sub-url,'?')">
            <xsl:value-of select="substring-before($sub-url,'?')"/>
          </xsl:when>
          <xsl:when test="contains($sub-url,'.patch')"/>
          <xsl:otherwise>
            <xsl:value-of select="$sub-url"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="ftp_dir">
    <xsl:param name="package" select="foo"/>
    <!-- A lot of hardcoded dir names. Not full revised yet. -->
    <xsl:choose>
        <!-- cdparanoia -->
      <xsl:when test="contains($package, '-III')">
        <xsl:text>cdparanoia</xsl:text>
      </xsl:when>
        <!-- DobBook 3.1 -->
      <xsl:when test="contains($package, 'docbk31')">
        <xsl:text>docbk</xsl:text>
      </xsl:when>
        <!-- gc -->
      <xsl:when test="contains($package, 'gc6')">
        <xsl:text>gc</xsl:text>
      </xsl:when>
        <!-- ISO-codes -->
      <xsl:when test="contains($package, 'iso-codes')">
        <xsl:text>iso-codes</xsl:text>
      </xsl:when>
        <!-- JPEG -->
      <xsl:when test="contains($package, 'jpegsrc')">
        <xsl:text>jpeg</xsl:text>
      </xsl:when>
        <!-- lynx -->
      <xsl:when test="contains($package, 'lynx')">
        <xsl:text>lynx</xsl:text>
      </xsl:when>
        <!-- ntp -->
      <xsl:when test="contains($package, 'ntp')">
        <xsl:text>ntp</xsl:text>
      </xsl:when>
        <!-- OpenLDAP -->
      <xsl:when test="contains($package, 'openldap')">
        <xsl:text>openldap</xsl:text>
      </xsl:when>
        <!-- Open Office -->
      <xsl:when test="contains($package, 'OOo')">
        <xsl:text>OOo</xsl:text>
      </xsl:when>
        <!-- pine -->
      <xsl:when test="contains($package, 'pine')">
        <xsl:text>pine</xsl:text>
      </xsl:when>
        <!-- portmap -->
      <xsl:when test="contains($package, 'portmap')">
        <xsl:text>portmap</xsl:text>
      </xsl:when>
        <!-- psutils -->
      <xsl:when test="contains($package, 'psutils')">
        <xsl:text>psutils</xsl:text>
      </xsl:when>
        <!-- qpopper -->
      <xsl:when test="contains($package, 'qpopper')">
        <xsl:text>qpopper</xsl:text>
      </xsl:when>
        <!-- QT -->
      <xsl:when test="contains($package, 'qt-x')">
        <xsl:text>qt-x11-free</xsl:text>
      </xsl:when>
        <!-- sendmail -->
      <xsl:when test="contains($package, 'sendmail')">
        <xsl:text>sendmail</xsl:text>
      </xsl:when>
        <!-- Slib -->
      <xsl:when test="contains($package, 'slib')">
        <xsl:text>slib</xsl:text>
      </xsl:when>
        <!-- TCL -->
      <xsl:when test="contains($package, 'tcl')">
        <xsl:text>tcl</xsl:text>
      </xsl:when>
        <!-- tcpwrappers -->
      <xsl:when test="contains($package, 'tcp_wrappers')">
        <xsl:text>tcp_wrappers</xsl:text>
      </xsl:when>
        <!-- TeTeX -->
      <xsl:when test="contains($package, 'tetex')">
        <xsl:text>tetex</xsl:text>
      </xsl:when>
        <!-- Tidy -->
      <xsl:when test="contains($package, 'tidy')">
        <xsl:text>tidy</xsl:text>
      </xsl:when>
        <!-- Tk -->
      <xsl:when test="contains($package, 'tk8')">
        <xsl:text>tk</xsl:text>
      </xsl:when>
        <!-- unzip -->
      <xsl:when test="contains($package, 'unzip')">
        <xsl:text>unzip</xsl:text>
      </xsl:when>
        <!-- wireless_tools -->
      <xsl:when test="contains($package, 'wireless_tools')">
        <xsl:text>wireless_tools</xsl:text>
      </xsl:when>
        <!-- whois -->
      <xsl:when test="contains($package, 'whois')">
        <xsl:text>whois</xsl:text>
      </xsl:when>
        <!-- XOrg -->
      <xsl:when test="contains($package, 'X11R6')">
        <xsl:text>Xorg</xsl:text>
      </xsl:when>
        <!-- zip -->
      <xsl:when test="contains($package, 'zip2')">
        <xsl:text>zip</xsl:text>
      </xsl:when>
        <!-- General rule -->
      <xsl:otherwise>
        <xsl:variable name="cut"
          select="translate(substring-after($package, '-'), '0123456789', '0000000000')"/>
        <xsl:variable name="package2">
          <xsl:value-of select="substring-before($package, '-')"/>
          <xsl:text>-</xsl:text>
          <xsl:value-of select="$cut"/>
        </xsl:variable>
        <xsl:value-of select="substring-before($package2, '-0')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="itemizedlist/listitem/para">
    <xsl:param name="package" select="foo"/>
    <xsl:param name="ftpdir" select="foo"/>
    <xsl:choose>
      <!-- This depend on all package pages having both "Download HTTP" and "Download FTP" lines -->
      <xsl:when test="contains(string(),'HTTP')">
        <xsl:text>if [[ ! -f $PACKAGE ]] ; then&#xA;</xsl:text>
        <!-- SRC_ARCHIVE may have subdirectories or not -->
        <xsl:text>  if [[ -f $SRC_ARCHIVE/$PKG_DIR/$PACKAGE ]] ; then&#xA;</xsl:text>
        <xsl:text>    cp $SRC_ARCHIVE/$PKG_DIR/$PACKAGE $PACKAGE&#xA;</xsl:text>
        <xsl:text>  elif [[ -f $SRC_ARCHIVE/$PACKAGE ]] ; then&#xA;</xsl:text>
        <xsl:text>    cp $SRC_ARCHIVE/$PACKAGE $PACKAGE&#xA;  else&#xA;</xsl:text>
        <!-- The FTP_SERVER mirror -->
        <xsl:text>    wget $FTP_SERVER/BLFS/conglomeration/$PKG_DIR/$PACKAGE</xsl:text>
        <!-- Upstream HTTP URL -->
        <xsl:if test="string-length(ulink/@url) &gt; '10' and
                      not(contains(string(ulink/@url),'sourceforge'))">
          <xsl:text> || \&#xA;    wget </xsl:text>
          <xsl:value-of select="ulink/@url"/>
        </xsl:if>
      </xsl:when>
      <xsl:when test="contains(string(),'FTP')">
        <!-- Upstream FTP URL -->
        <xsl:if test="string-length(ulink/@url) &gt; '10'">
          <xsl:text> || \&#xA;    wget </xsl:text>
          <xsl:value-of select="ulink/@url"/>
        </xsl:if>
        <xsl:text>&#xA;  fi&#xA;fi&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'MD5')">
        <xsl:text>echo "</xsl:text>
        <xsl:value-of select="substring-after(string(),'sum: ')"/>
        <xsl:text>&#x20;&#x20;$PACKAGE" | md5sum -c -&#xA;</xsl:text>
      </xsl:when>
      <!-- Patches -->
      <xsl:when test="contains(string(ulink/@url),'.patch')">
        <xsl:text>wget </xsl:text>
        <xsl:value-of select="ulink/@url"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

<!--======================== Commands code ==========================-->

  <xsl:template match="screen">
    <xsl:if test="child::* = userinput">
      <xsl:choose>
        <xsl:when test="@role = 'nodump'"/>
        <xsl:otherwise>
          <xsl:if test="@role = 'root'">
            <xsl:text>sudo </xsl:text>
          </xsl:if>
          <xsl:apply-templates select="userinput" mode="screen"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="para/command">
    <xsl:if test="(contains(string(),'test') or
            contains(string(),'check'))">
      <xsl:text>#</xsl:text>
      <xsl:value-of select="substring-before(string(),'make')"/>
      <xsl:text>make -k</xsl:text>
      <xsl:value-of select="substring-after(string(),'make')"/>
      <xsl:text> || true&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput" mode="screen">
    <xsl:apply-templates/>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:text>**EDITME</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>EDITME**</xsl:text>
  </xsl:template>

</xsl:stylesheet>
