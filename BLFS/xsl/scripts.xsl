<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- $Id: scripts.xsl 34 2012-02-21 16:05:09Z labastie $ -->

<!-- XSLT stylesheet to create shell scripts from "linear build" BLFS books. -->

  <!-- Build as user (y) or as root (n)? -->
  <xsl:param name="sudo" select="'y'"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

<!--=================== Master chunks code ======================-->

  <xsl:template match="sect1">

    <xsl:if test="@id != 'bootscripts'">
        <!-- The file names -->
      <xsl:variable name="filename" select="@id"/>

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
        <xsl:value-of select="concat($order,'-z-',$filename)"/>
        <xsl:text>&#xA;    FTPDIR is </xsl:text>
        <xsl:value-of select="$filename"/>
        <xsl:text>&#xA;&#xA;</xsl:text>
      </xsl:message>

        <!-- Creating the scripts -->
      <exsl:document href="{$order}-z-{$filename}" method="text">
        <xsl:text>#!/bin/bash&#xA;set -e&#xA;&#xA;</xsl:text>
        <xsl:choose>
          <!-- Package page -->
          <xsl:when test="sect2[@role='package']">
            <!-- We build in a subdirectory -->
            <xsl:text>PKG_DIR=</xsl:text>
            <xsl:value-of select="$filename"/>
            <xsl:text>&#xA;</xsl:text>
            <!-- Download code and build commands -->
            <xsl:apply-templates select="sect2"/>
            <!-- Clean-up -->
            <xsl:text>cd $SRC_DIR/$PKG_DIR&#xA;</xsl:text>
            <!-- In some case, some files in the build tree are owned
                 by root -->
            <xsl:if test="$sudo='y'">
              <xsl:text>sudo </xsl:text>
            </xsl:if>
            <xsl:text>rm -rf $UNPACKDIR unpacked&#xA;&#xA;</xsl:text>
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
    <xsl:choose>
      <xsl:when test="@role = 'package'">
        <xsl:text>mkdir -p $SRC_DIR/$PKG_DIR&#xA;</xsl:text>
        <xsl:text>cd $SRC_DIR/$PKG_DIR&#xA;</xsl:text>
        <!-- Download information is in bridgehead tags -->
        <xsl:apply-templates select="bridgehead[@renderas='sect3']"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'installation'">
        <xsl:text>
if [ "${PACKAGE%.zip}" = "${PACKAGE}" ]; then
 if [[ -e unpacked ]] ; then
  UNPACKDIR=`grep '[^./]\+' unpacked | head -n1 | sed 's@^./@@;s@/.*@@'`
  [[ -n $UNPACKDIR ]] &amp;&amp; [[ -d $UNPACKDIR ]] &amp;&amp; rm -rf $UNPACKDIR
 fi
 tar -xvf $PACKAGE > unpacked
 UNPACKDIR=`grep '[^./]\+' unpacked | head -n1 | sed 's@^./@@;s@/.*@@'`
else
 UNPACKDIR=${PACKAGE%.zip}
 [[ -n $UNPACKDIR ]] &amp;&amp; [[ -d $UNPACKDIR ]] &amp;&amp; rm -rf $UNPACKDIR
 unzip -d $UNPACKDIR ${PACKAGE}
fi
cd $UNPACKDIR&#xA;&#xA;</xsl:text>
        <xsl:apply-templates select=".//screen | .//para/command"/>
        <xsl:if test="$sudo = 'y'">
          <xsl:text>sudo /sbin/</xsl:text>
        </xsl:if>
        <xsl:text>ldconfig&#xA;&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'configuration'">
        <xsl:apply-templates select=".//screen" mode="config"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

<!--==================== Download code =======================-->

  <!-- template for extracting the filename from an url in the form:
       proto://internet.name/dir1/.../dirn/filename?condition.
       Needed, because substring-after(...,'/') returns only the
       substring after the first '/'. -->
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
          <xsl:otherwise>
            <xsl:value-of select="$sub-url"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Generates the code to download a package, an additional package or
       a patch. -->
  <xsl:template name="download-file">
    <xsl:param name="httpurl" select="''"/>
    <xsl:param name="ftpurl" select="''"/>
    <xsl:param name="md5" select="''"/>
    <xsl:param name="varname" select="''"/>
    <xsl:variable name="package">
      <xsl:call-template name="package_name">
        <xsl:with-param name="url">
          <xsl:choose>
            <xsl:when test="string-length($httpurl) &gt; 10">
              <xsl:value-of select="$httpurl"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$ftpurl"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="first_letter"
                  select="translate(substring($package,1,1),
                                    'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                                    'abcdefghijklmnopqrstuvwxyz')"/>
    <xsl:text>&#xA;</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text>=</xsl:text>
    <xsl:value-of select="$package"/>
    <xsl:text>&#xA;if [[ ! -f $</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text> ]] ; then&#xA;</xsl:text>
    <!-- SRC_ARCHIVE may have subdirectories or not -->
    <xsl:text>  if [[ -f $SRC_ARCHIVE/$PKG_DIR/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text> ]] ; then&#xA;</xsl:text>
    <xsl:text>    cp $SRC_ARCHIVE/$PKG_DIR/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text> $</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text>&#xA;</xsl:text>
    <xsl:text>  elif [[ -f $SRC_ARCHIVE/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text> ]] ; then&#xA;</xsl:text>
    <xsl:text>    cp $SRC_ARCHIVE/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text> $</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text>&#xA;  else&#xA;</xsl:text>
    <!-- The FTP_SERVER mirror -->
    <xsl:text>    wget -T 30 -t 5 ${FTP_SERVER}svn/</xsl:text>
    <xsl:value-of select="$first_letter"/>
    <xsl:text>/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:if test="string-length($httpurl) &gt; 10">
      <xsl:text> ||
    wget -T 30 -t 5 </xsl:text>
      <xsl:value-of select="$httpurl"/>
    </xsl:if>
    <xsl:if test="string-length($ftpurl) &gt; 10">
      <xsl:text> ||
    wget -T 30 -t 5 </xsl:text>
      <xsl:value-of select="$ftpurl"/>
    </xsl:if>
    <xsl:text>
    cp $</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text> $SRC_ARCHIVE
  fi
fi
</xsl:text>
    <xsl:if test="string-length($md5) &gt; 10">
      <xsl:text>echo "</xsl:text>
      <xsl:value-of select="$md5"/>
      <xsl:text>&#x20;&#x20;$</xsl:text>
      <xsl:value-of select="$varname"/>
      <xsl:text>" | md5sum -c -
</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Extract the MD5 sum information -->
  <xsl:template match="para" mode="md5">
    <xsl:choose>
      <xsl:when test="contains(substring-after(string(),'sum: '),'&#xA;')">
        <xsl:value-of select="substring-before(substring-after(string(),'sum: '),'&#xA;')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring-after(string(),'sum: ')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- We have several templates itemizedlist, depending on whether we
       expect the package information, or additional package(s) or patch(es)
       information. Select the appropriate mode here. -->
  <xsl:template match="bridgehead">
    <xsl:choose>
      <!-- Special case for Openjdk -->
      <xsl:when test="contains(string(),'Source Package Information')">
        <xsl:apply-templates
             select="following-sibling::itemizedlist[1]//simplelist">
          <xsl:with-param name="varname" select="'PACKAGE'"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="following-sibling::itemizedlist
                             [preceding-sibling::bridgehead[1]=current()
                              and position() &gt;1]//simplelist">
          <xsl:with-param name="varname" select="'PACKAGE1'"/>
        </xsl:apply-templates>
      </xsl:when>
      <!-- Package information -->
      <xsl:when test="contains(string(),'Package Information')">
        <xsl:apply-templates select="following-sibling::itemizedlist
                             [preceding-sibling::bridgehead[1]=current()]"
                             mode="package"/>
      </xsl:when>
      <!-- Additional package information -->
      <!-- special case for llvm -->
      <xsl:when test="contains(string(),'Optional Download')">
        <xsl:apply-templates select="following-sibling::itemizedlist"
                             mode="additional"/>
      </xsl:when>
      <!-- All other additional packages have "Additional" -->
      <xsl:when test="contains(string(),'Additional')">
        <xsl:apply-templates select="following-sibling::itemizedlist"
                             mode="additional"/>
      </xsl:when>
      <!-- Do not do anything if the dev has created another type of
           bridgehead. -->
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

  <!-- Call the download code template with appropriate parameters -->
  <xsl:template match="itemizedlist" mode="package">
    <xsl:call-template name="download-file">
      <xsl:with-param name="httpurl">
        <xsl:value-of select="./listitem[1]/para/ulink/@url"/>
      </xsl:with-param>
      <xsl:with-param name="ftpurl">
        <xsl:value-of select="./listitem/para[contains(string(),'FTP')]/ulink/@url"/>
      </xsl:with-param>
      <xsl:with-param name="md5">
        <xsl:apply-templates select="./listitem/para[contains(string(),'MD5')]"
                             mode="md5"/>
      </xsl:with-param>
      <xsl:with-param name="varname" select="'PACKAGE'"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="itemizedlist" mode="additional">
  <!-- The normal layout is "one listitem"<->"one url", but some devs
       find amusing to have FTP and/or MD5sum listitems, or to
       enclose the download information inside a simplelist tag... -->
    <xsl:for-each select="listitem[.//ulink]">
      <xsl:choose>
        <!-- hopefully, there was a HTTP line before -->
        <xsl:when test="contains(string(./para),'FTP')"/>
        <xsl:when test=".//simplelist">
          <xsl:apply-templates select=".//simplelist">
            <xsl:with-param name="varname" select="'PACKAGE1'"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="download-file">
            <xsl:with-param name="httpurl">
              <xsl:value-of select="./para/ulink/@url"/>
            </xsl:with-param>
            <xsl:with-param name="ftpurl">
              <xsl:value-of
                   select="following-sibling::listitem[1]/
                           para[contains(string(),'FTP')]/ulink/@url"/>
            </xsl:with-param>
            <xsl:with-param name="md5">
              <xsl:apply-templates
                   select="following-sibling::listitem[position()&lt;3]/
                           para[contains(string(),'MD5')]"
                   mode="md5"/>
            </xsl:with-param>
            <xsl:with-param name="varname">
              <xsl:choose>
                <xsl:when test="contains(./para/ulink/@url,'.patch')">
                  <xsl:text>PATCH</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>PACKAGE1</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- the simplelist case. Hopefully, the layout is one member for
       url, one for md5 and others for various information, that we do not
       use -->
  <xsl:template match="simplelist">
    <xsl:param name="varname" select="'PACKAGE1'"/>
    <xsl:call-template name="download-file">
      <xsl:with-param name="httpurl" select=".//ulink/@url"/>
      <xsl:with-param name="md5">
        <xsl:value-of select="substring-after(member[contains(string(),'MD5')],'sum: ')"/>
      </xsl:with-param>
      <xsl:with-param name="varname" select="$varname"/>
    </xsl:call-template>
  </xsl:template>
<!--======================== Commands code ==========================-->

  <xsl:template match="screen">
    <xsl:if test="child::* = userinput and not(@role = 'nodump')">
      <xsl:choose>
        <xsl:when test="@role = 'root'">
          <xsl:if test="$sudo = 'y'">
            <xsl:text>sudo -E sh &lt;&lt; ROOT_EOF&#xA;</xsl:text>
          </xsl:if>
          <xsl:apply-templates mode="root"/>
          <xsl:if test="$sudo = 'y'">
            <xsl:text>&#xA;ROOT_EOF</xsl:text>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="userinput"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="screen" mode="config">
    <xsl:if test="preceding-sibling::para[1]/xref[@linkend='bootscripts']">
      <xsl:text>[[ ! -d $SRC_DIR/blfs-bootscripts ]] &amp;&amp; mkdir $SRC_DIR/blfs-bootscripts
pushd $SRC_DIR/blfs-bootscripts
URL=</xsl:text>
      <xsl:value-of select="id('bootscripts')//itemizedlist//ulink/@url"/><xsl:text>
BOOTPACKG=$(basename $URL)
if [[ ! -f $BOOTPACKG ]] ; then
  if [[ -f $SRC_ARCHIVE/$PKG_DIR/$BOOTPACKG ]] ; then
    cp $SRC_ARCHIVE/$PKG_DIR/$BOOTPACKG $BOOTPACKG
  elif [[ -f $SRC_ARCHIVE/$BOOTPACKG ]] ; then
    cp $SRC_ARCHIVE/$BOOTPACKG $BOOTPACKG
  else
    wget -T 30 -t 5 $URL
    cp $BOOTPACKG $SRC_ARCHIVE
  fi
  rm -f unpacked
fi

if [[ -e unpacked ]] ; then
  UNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
  if ! [[ -d $UNPACKDIR ]]; then
    rm unpacked
    tar -xvf $BOOTPACKG > unpacked
    UNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
  fi
else
  tar -xvf $BOOTPACKG > unpacked
  UNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
fi
cd $UNPACKDIR
</xsl:text>
    </xsl:if>
    <xsl:apply-templates select='.'/>
    <xsl:if test="preceding-sibling::para[1]/xref[@linkend='bootscripts']">
      <xsl:text>
popd</xsl:text>
    </xsl:if>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="para/command">
    <xsl:if test="(contains(string(),'test') or
            contains(string(),'check'))">
      <xsl:text>#</xsl:text>
      <xsl:value-of select="substring-before(string(),'make ')"/>
      <xsl:text>make </xsl:text>
      <xsl:if test="not(contains(string(),'-k'))">
        <xsl:text>-k </xsl:text>
      </xsl:if>
      <xsl:value-of select="substring-after(string(),'make ')"/>
      <xsl:text> || true&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="text()" mode="root">
    <xsl:call-template name="output-root">
      <xsl:with-param name="out-string" select="string()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="output-root">
    <xsl:param name="out-string" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($out-string,'make ')">
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'make ')"/>
        </xsl:call-template>
        <xsl:text>make -j1 </xsl:text>
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'make ')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($out-string,'$') and $sudo = 'y'">
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'$')"/>
        </xsl:call-template>
        <xsl:text>\$</xsl:text>
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'$')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($out-string,'`') and $sudo = 'y'">
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'`')"/>
        </xsl:call-template>
        <xsl:text>\`</xsl:text>
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'`')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($out-string,'\') and $sudo = 'y'">
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'\')"/>
        </xsl:call-template>
        <xsl:text>\\</xsl:text>
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'\')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$out-string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="replaceable">
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
  </xsl:template>

  <xsl:template match="replaceable" mode="root">
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
  </xsl:template>

</xsl:stylesheet>
