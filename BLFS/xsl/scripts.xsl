<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- $Id: scripts.xsl 34 2012-02-21 16:05:09Z labastie $ -->

<!-- XSLT stylesheet to create shell scripts from "linear build" BLFS books. -->

<!-- Check whether the book is sysv or systemd -->
  <xsl:variable name="rev">
    <xsl:choose>
      <xsl:when test="//bookinfo/title/phrase[@revision='systemd']">
        systemd
      </xsl:when>
      <xsl:otherwise>
        sysv
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Wrap "root" commands inside a wrapper function, allowing
       "porg style" package management -->
  <xsl:param name="wrap-install" select="'n'"/>

  <!-- Build as user (y) or as root (n)? -->
  <xsl:param name="sudo" select="'y'"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

<!--=================== Master chunks code ======================-->

  <xsl:template match="sect1">

    <xsl:if test="@id != 'bootscripts' and @id != 'systemd-units'">
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
            <!-- We build in a subdirectory, whose name may be needed
                 if using package management (see envars.conf), so
                 "export" it -->
            <xsl:text>export PKG_DIR=</xsl:text>
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
      <xsl:when test="@role = 'qt4-prefix' or @role = 'qt5-prefix'">
        <xsl:apply-templates select=".//screen"/>
      </xsl:when>
      <xsl:when test="@role = 'installation'">
        <xsl:text>
find . -maxdepth 1 -mindepth 1 -type d | xargs </xsl:text>
        <xsl:if test="$sudo='y'">
          <xsl:text>sudo </xsl:text>
        </xsl:if>
        <xsl:text>rm -rf
case $PACKAGE in
  *.tar.gz|*.tar.bz2|*.tar.xz|*.tgz|*.tar.lzma)
     tar -xvf $PACKAGE &gt; unpacked
     UNPACKDIR=`grep '[^./]\+' unpacked | head -n1 | sed 's@^\./@@;s@/.*@@'`
     ;;
  *.tar.lz)
     bsdtar -xvf $PACKAGE 2&gt; unpacked
     UNPACKDIR=`head -n1 unpacked | cut  -d" " -f2 | sed 's@^\./@@;s@/.*@@'`
     ;;
  *.zip)
     zipinfo -1 $PACKAGE &gt; unpacked
     UNPACKDIR="$(sed 's@/.*@@' unpacked | uniq )"
     if test $(wc -w &lt;&lt;&lt; $UNPACKDIR) -eq 1; then
       unzip $PACKAGE
     else
       UNPACKDIR=${PACKAGE%.zip}
       unzip -d $UNPACKDIR $PACKAGE
     fi
     ;;
  *)
     UNPACKDIR=$PKG_DIR-build
     mkdir $UNPACKDIR
     cp $PACKAGE $UNPACKDIR
     ;;
esac
export UNPACKDIR
cd $UNPACKDIR&#xA;
</xsl:text>
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
    <!-- Download from upstream http -->
    <xsl:if test="string-length($httpurl) &gt; 10">
      <xsl:text>    wget -T 30 -t 5 </xsl:text>
      <xsl:value-of select="$httpurl"/>
      <xsl:text> ||&#xA;</xsl:text>
    </xsl:if>
    <!-- Download from upstream ftp -->
    <xsl:if test="string-length($ftpurl) &gt; 10">
      <xsl:text>    wget -T 30 -t 5 </xsl:text>
      <xsl:value-of select="$ftpurl"/>
      <xsl:text> ||&#xA;</xsl:text>
    </xsl:if>
    <!-- The FTP_SERVER mirror as a last resort -->
    <xsl:text>    wget -T 30 -t 5 ${FTP_SERVER}svn/</xsl:text>
    <xsl:value-of select="$first_letter"/>
    <xsl:text>/$</xsl:text>
    <xsl:value-of select="$varname"/>
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
          <xsl:if test="not(preceding-sibling::screen[1][@role='root'])">
            <xsl:if test="$sudo = 'y'">
              <xsl:text>sudo -E sh &lt;&lt; ROOT_EOF&#xA;</xsl:text>
            </xsl:if>
            <xsl:if test="$wrap-install = 'y' and
                          ancestor::sect2[@role='installation']">
              <xsl:text>if [ -r "$PACK_INSTALL" ]; then
  source $PACK_INSTALL
  export -f wrapInstall
  export -f packInstall
fi
wrapInstall '
</xsl:text>
            </xsl:if>
          </xsl:if>
          <xsl:apply-templates mode="root"/>
          <xsl:if test="not(following-sibling::screen[1][@role='root'])">
            <xsl:if test="$wrap-install = 'y' and
                          ancestor::sect2[@role='installation']">
              <xsl:text>'&#xA;packInstall</xsl:text>
            </xsl:if>
            <xsl:if test="$sudo = 'y'">
              <xsl:text>&#xA;ROOT_EOF</xsl:text>
            </xsl:if>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="userinput"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="set-bootpkg-dir">
    <xsl:param name="bootpkg" select="'bootscripts'"/>
    <xsl:param name="url" select="''"/>
    <xsl:text>[[ ! -d $SRC_DIR/blfs-</xsl:text>
    <xsl:copy-of select="$bootpkg"/>
    <xsl:text> ]] &amp;&amp; mkdir $SRC_DIR/blfs-</xsl:text>
    <xsl:copy-of select="$bootpkg"/>
    <xsl:text>
pushd $SRC_DIR/blfs-</xsl:text>
    <xsl:copy-of select="$bootpkg"/>
    <xsl:text>
URL=</xsl:text>
      <xsl:value-of select="$url"/>
    <xsl:text>
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
  BOOTUNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
  if ! [[ -d $BOOTUNPACKDIR ]]; then
    rm unpacked
    tar -xvf $BOOTPACKG > unpacked
    BOOTUNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
  fi
else
  tar -xvf $BOOTPACKG > unpacked
  BOOTUNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
fi
cd $BOOTUNPACKDIR
</xsl:text>
  </xsl:template>

  <xsl:template match="screen" mode="config">
    <xsl:if test="preceding-sibling::para[1]/xref[@linkend='bootscripts']">
      <xsl:call-template name="set-bootpkg-dir">
        <xsl:with-param name="bootpkg" select="'bootscripts'"/>
        <xsl:with-param name="url"
                        select="id('bootscripts')//itemizedlist//ulink/@url"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="preceding-sibling::para[1]/xref[@linkend='systemd-units']">
      <xsl:call-template name="set-bootpkg-dir">
        <xsl:with-param name="bootpkg" select="'systemd-units'"/>
        <xsl:with-param name="url"
                        select="id('systemd-units')//itemizedlist//ulink/@url"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:apply-templates select='.'/>
    <xsl:if test="preceding-sibling::para[1]/xref[@linkend='bootscripts' or
                                                  @linkend='systemd-units']">
      <xsl:text>
popd</xsl:text>
    </xsl:if>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="para/command">
    <xsl:variable name="ns" select="normalize-space(string())"/>
    <xsl:if test="(contains($ns,'test') or
            contains($ns,'check'))">
      <xsl:text>#</xsl:text>
      <xsl:value-of select="substring-before($ns,'make ')"/>
      <xsl:text>make </xsl:text>
      <xsl:if test="not(contains($ns,'-k'))">
        <xsl:text>-k </xsl:text>
      </xsl:if>
      <xsl:value-of select="substring-after($ns,'make ')"/>
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

  <xsl:variable name="APOS">'</xsl:variable>

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
      <xsl:when test="contains($out-string,string($APOS))
                      and $wrap-install = 'y'
                      and ancestor::sect2[@role='installation']">
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-before($out-string,string($APOS))"/>
        </xsl:call-template>
        <xsl:text>'\''</xsl:text>
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,string($APOS))"/>
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
