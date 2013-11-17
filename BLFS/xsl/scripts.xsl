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
          <xsl:when test="sect2[@role='package'] and not(@id = 'xorg7-app' or
                          @id = 'xorg7-data' or @id = 'xorg7-driver' or
                          @id = 'xorg7-font' or @id = 'xorg7-lib' or
                          @id = 'xorg7-proto' or @id = 'xorg7-util')">
            <!-- Variables -->
            <!-- These three lines  could be important if SRC_ARCHIVE,
                 FTP_SERVER and SRCDIR were not set in the environment.
                 But they are not tested for length or anything later,
                 so not needed
            <xsl:text>SRC_ARCHIVE=$SRC_ARCHIVE&#xA;</xsl:text>
            <xsl:text>FTP_SERVER=$FTP_SERVER&#xA;</xsl:text>
            <xsl:text>SRC_DIR=$SRC_DIR&#xA;&#xA;</xsl:text>-->
            <xsl:text>&#xA;PKG_DIR=</xsl:text>
            <xsl:value-of select="$filename"/>
            <xsl:text>&#xA;</xsl:text>
            <!-- Download code and build commands -->
            <xsl:apply-templates select="sect2"/>
            <!-- Clean-up -->
            <!-- xorg7-server used to require mesalib tree being present.
                 That is no more true
            <xsl:if test="not(@id='mesalib')"> -->
              <xsl:text>cd $SRC_DIR/$PKG_DIR&#xA;</xsl:text>
            <!-- In some case, some files in the build tree are owned
                 by root -->
              <xsl:if test="$sudo='y'">
                <xsl:text>sudo </xsl:text>
              </xsl:if>
              <xsl:text>rm -rf $UNPACKDIR unpacked&#xA;&#xA;</xsl:text>
            <!-- Same reason as preceding comment
            </xsl:if>
            <xsl:if test="@id='xorg7-server'">
              <xsl:text>cd $SRC_DIR/MesaLib
UNPACKDIR=`grep '[^./]\+' unpacked | head -n1 | sed 's@^./@@;s@/.*@@'`
rm -rf $UNPACKDIR unpacked&#xA;&#xA;</xsl:text>
            </xsl:if> -->
          </xsl:when>
          <!-- Xorg7 pseudo-packages -->
          <xsl:when test="contains(@id,'xorg7') and not(@id = 'xorg7-server')">
            <xsl:text># Useless SRC_DIR=$SRC_DIR

cd $SRC_DIR
mkdir -p xc
cd xc&#xA;</xsl:text>
            <xsl:apply-templates select="sect2" mode="xorg7"/>
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
cd $UNPACKDIR&#xA;</xsl:text>
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

  <xsl:template match="sect2" mode="xorg7">
    <xsl:choose>
 <!--     <xsl:when test="@role = 'package'">
        <xsl:apply-templates select="itemizedlist/listitem/para" mode="xorg7"/>
      </xsl:when>-->
      <xsl:when test="not(@role)">
<!-- This is the packages download instructions> -->
        <xsl:apply-templates select=".//screen" mode="xorg7"/>
      </xsl:when>
      <xsl:when test="@role = 'installation'">
        <xsl:apply-templates select=".//screen" mode="xorg7"/>
        <xsl:if test="$sudo = 'y'">
          <xsl:text>sudo /sbin/</xsl:text>
        </xsl:if>
        <xsl:text>ldconfig&#xA;&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="@role = 'configuration'">
        <xsl:text>if [[ $XORG_PREFIX != /usr ]] ; then&#xA;</xsl:text>
        <xsl:apply-templates select=".//screen"/>
        <xsl:text>fi&#xA;</xsl:text>
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
          <xsl:otherwise>
            <xsl:value-of select="$sub-url"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="bridgehead">
    <xsl:choose>
      <xsl:when test="string()='Package Information'">
        <xsl:variable name="url">
          <xsl:choose>
            <xsl:when
              test="string-length(
                following-sibling::itemizedlist[1]/listitem[1]/para/ulink/@url)
                    &gt; 10">
              <xsl:value-of select=
            "following-sibling::itemizedlist[1]/listitem[1]/para/ulink/@url"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select=
            "following-sibling::itemizedlist[1]/listitem[2]/para/ulink/@url"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="package">
          <xsl:call-template name="package_name">
            <xsl:with-param name="url" select="$url"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable
          name="first_letter"
          select="translate(substring($package,1,1),
                            'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                            'abcdefghijklmnopqrstuvwxyz')"/>
        <xsl:text>PACKAGE=</xsl:text>
        <xsl:value-of select="$package"/>
        <xsl:text>&#xA;if [[ ! -f $PACKAGE ]] ; then&#xA;</xsl:text>
        <!-- SRC_ARCHIVE may have subdirectories or not -->
        <xsl:text>  if [[ -f $SRC_ARCHIVE/$PKG_DIR/$PACKAGE ]] ; then&#xA;</xsl:text>
        <xsl:text>    cp $SRC_ARCHIVE/$PKG_DIR/$PACKAGE $PACKAGE&#xA;</xsl:text>
        <xsl:text>  elif [[ -f $SRC_ARCHIVE/$PACKAGE ]] ; then&#xA;</xsl:text>
        <xsl:text>    cp $SRC_ARCHIVE/$PACKAGE $PACKAGE&#xA;  else&#xA;</xsl:text>
        <!-- The FTP_SERVER mirror -->
        <xsl:text>    wget -T 30 -t 5 ${FTP_SERVER}svn/</xsl:text>
        <xsl:value-of select="$first_letter"/>
        <xsl:text>/$PACKAGE</xsl:text>
        <xsl:apply-templates
             select="following-sibling::itemizedlist[1]/listitem/para"
             mode="package"/>
      </xsl:when>
      <xsl:when test="contains(string(),'Additional')">
        <xsl:apply-templates
             select="following-sibling::itemizedlist[1]/listitem/para"
             mode="additional"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="para" mode="package">
    <xsl:choose>
      <xsl:when test="contains(string(),'HTTP')">
        <!-- Upstream HTTP URL -->
        <xsl:if test="string-length(ulink/@url) &gt; '10'">
          <xsl:text> || \&#xA;    wget -T 30 -t 5 </xsl:text>
          <xsl:choose>
            <xsl:when test="contains(ulink/@url,'?')">
              <xsl:value-of select="substring-before(ulink/@url,'?')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="ulink/@url"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="not(contains(string(parent::listitem/following-sibling::listitem[1]/para),'FTP'))">
            <xsl:text>
    cp $PACKAGE $SRC_ARCHIVE
  fi
fi
</xsl:text>
          </xsl:if>
        </xsl:if>
      </xsl:when>
      <xsl:when test="contains(string(),'FTP')">
        <!-- Upstream FTP URL -->
        <xsl:if test="string-length(ulink/@url) &gt; '10'">
          <xsl:text> || \&#xA;    wget -T 30 -t 5 </xsl:text>
          <xsl:value-of select="ulink/@url"/>
        </xsl:if>
        <xsl:text>
    cp $PACKAGE $SRC_ARCHIVE
  fi
fi
</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'MD5')">
<!-- some md5 sums are written with a LF -->
        <xsl:variable name="md5">
          <xsl:choose>
            <xsl:when test="contains(substring-after(string(),'sum: '),'&#xA;')">
              <xsl:value-of select="substring-before(substring-after(string(),'sum: '),'&#xA;')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring-after(string(),'sum: ')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:text>echo "</xsl:text>
        <xsl:value-of select="$md5"/>
        <xsl:text>&#x20;&#x20;$PACKAGE" | md5sum -c -&#xA;</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="para" mode="additional">
    <xsl:choose>
      <xsl:when test="contains(string(ulink/@url),'.patch')">
        <xsl:variable name="patch">
          <xsl:call-template name="package_name">
            <xsl:with-param name="url" select="ulink/@url"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:text>PATCH=</xsl:text>
        <xsl:value-of select="$patch"/>
        <xsl:text>&#xA;if [[ ! -f $PATCH ]] ; then&#xA;</xsl:text>
         <!-- SRC_ARCHIVE may have subdirectories or not -->
        <xsl:text>  if [[ -f $SRC_ARCHIVE/$PKG_DIR/$PATCH ]] ; then&#xA;</xsl:text>
        <xsl:text>    cp $SRC_ARCHIVE/$PKG_DIR/$PATCH $PATCH&#xA;</xsl:text>
        <xsl:text>  elif [[ -f $SRC_ARCHIVE/$PATCH ]] ; then&#xA;</xsl:text>
        <xsl:text>    cp $SRC_ARCHIVE/$PATCH $PATCH&#xA;  else&#xA;</xsl:text>
        <xsl:text>wget -T 30 -t 5 </xsl:text>
        <xsl:value-of select="ulink/@url"/>
        <xsl:text>&#xA;</xsl:text>
        <xsl:text>
    cp $PATCH $SRC_ARCHIVE
  fi
fi
</xsl:text>
      </xsl:when>
      <xsl:when test="ulink">
        <xsl:if test="string-length(ulink/@url) &gt; '10'">
          <xsl:variable name="package">
            <xsl:call-template name="package_name">
              <xsl:with-param name="url" select="ulink/@url"/>
            </xsl:call-template>
          </xsl:variable> 
          <xsl:variable
            name="first_letter"
            select="translate(substring($package,1,1),
                              'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                              'abcdefghijklmnopqrstuvwxyz')"/>
          <xsl:text>PACKAGE1=</xsl:text>
          <xsl:value-of select="$package"/>
          <xsl:text>&#xA;if [[ ! -f $PACKAGE1 ]] ; then&#xA;</xsl:text>
          <!-- SRC_ARCHIVE may have subdirectories or not -->
          <xsl:text>  if [[ -f $SRC_ARCHIVE/$PKG_DIR/$PACKAGE1 ]] ; then&#xA;</xsl:text>
          <xsl:text>    cp $SRC_ARCHIVE/$PKG_DIR/$PACKAGE1 $PACKAGE1&#xA;</xsl:text>
          <xsl:text>  elif [[ -f $SRC_ARCHIVE/$PACKAGE1 ]] ; then&#xA;</xsl:text>
          <xsl:text>    cp $SRC_ARCHIVE/$PACKAGE1 $PACKAGE1&#xA;  else&#xA;</xsl:text>
          <!-- The FTP_SERVER mirror -->
          <xsl:text>    wget -T 30 -t 5 ${FTP_SERVER}svn/</xsl:text>
          <xsl:value-of select="$first_letter"/>
          <xsl:text>/$PACKAGE1</xsl:text>
          <xsl:text> || \&#xA;    wget -T 30 -t 5 </xsl:text>
          <xsl:value-of select="ulink/@url"/>
          <xsl:text>
    cp $PACKAGE1 $SRC_ARCHIVE
  fi
fi
</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:when test="contains(string(),'MD5')">
<!-- some md5 sums are written with a LF -->
        <xsl:variable name="md5">
          <xsl:choose>
            <xsl:when test="contains(substring-after(string(),'sum: '),'&#xA;')">
              <xsl:value-of select="substring-before(substring-after(string(),'sum: '),'&#xA;')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring-after(string(),'sum: ')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:text>echo "</xsl:text>
        <xsl:value-of select="$md5"/>
        <xsl:text>&#x20;&#x20;$PACKAGE1" | md5sum -c -&#xA;</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="itemizedlist/listitem/para" mode="xorg7">
    <xsl:if test="contains(string(ulink/@url),'.md5') or
                  contains(string(ulink/@url),'.wget')">
      <xsl:text>wget -T 30 -t 5 </xsl:text>
      <xsl:value-of select="ulink/@url"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="itemizedlist/listitem/para" mode="xorg7-patch">
    <xsl:if test="contains(string(ulink/@url),'.patch')">
      <xsl:text>wget -T 30 -t 5 </xsl:text>
      <xsl:value-of select="ulink/@url"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
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

  <xsl:template match="screen" mode="xorg7">
    <xsl:if test="child::* = userinput and not(@role = 'nodump')">
      <xsl:apply-templates select="userinput" mode="xorg7"/>
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

  <xsl:template match="screen" mode="sect-ver">
    <xsl:text>section=</xsl:text>
    <xsl:value-of select="substring-before(substring-after(string(),'mkdir '),' &amp;')"/>
    <xsl:text>&#xA;sect_ver=</xsl:text>
    <xsl:value-of select="substring-before(substring-after(string(),'-c ../'),'.md5')"/>
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

  <xsl:template match="userinput" mode="xorg7">
    <xsl:apply-templates mode="xorg7"/>
  </xsl:template>

  <xsl:template match="text()" mode="xorg7">
    <xsl:call-template name="output-text">
      <xsl:with-param name="out-string" select="string()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="output-text">
    <xsl:param name="out-string" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($out-string,'bash -e')">
        <xsl:call-template name="output-text">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'bash -e')"/>
        </xsl:call-template>
        <xsl:text># bash -e</xsl:text>
        <xsl:call-template name="output-text">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'bash -e')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($out-string,'exit')">
        <xsl:call-template name="output-text">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'exit')"/>
        </xsl:call-template>
        <xsl:text># exit</xsl:text>
        <xsl:call-template name="output-text">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'exit')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($out-string,'mkdir')">
        <xsl:call-template name="output-text">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'mkdir')"/>
        </xsl:call-template>
        <xsl:text>mkdir -p</xsl:text>
        <xsl:call-template name="output-text">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'mkdir')"/>
        </xsl:call-template>
      </xsl:when>
       <xsl:when test="contains($out-string,'rm -r ')">
        <xsl:call-template name="output-text">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,'rm -r ')"/>
        </xsl:call-template>
        <xsl:text>rm -rf </xsl:text>
        <xsl:call-template name="output-text">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,'rm -r ')"/>
        </xsl:call-template>
      </xsl:when>
     <xsl:otherwise>
        <xsl:value-of select="$out-string"/>
      </xsl:otherwise>
    </xsl:choose>
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
