<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- $Id$ -->

<!-- XSLT stylesheet to create shell scripts from "linear build" BLFS books. -->

<!-- parameters and global variables -->
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

  <!-- list of packages needing stats -->
  <xsl:param name="list-stat" select="''"/>

  <!-- Remove libtool .la files -->
  <xsl:param name="del-la-files" select="'y'"/>

  <!-- Build as user (y) or as root (n)? -->
  <xsl:param name="sudo" select="'y'"/>

  <!-- Localization in the form ll_CC.charmap@modifier (to be used in
       bash shell startup scripts). ll, CC, and charmap must be present:
       no way to use "C" or "POSIX". -->
  <xsl:param name="language" select="'en_US.UTF-8'"/>

  <!-- Break it in pieces -->
  <xsl:variable name="lang-ll">
    <xsl:copy-of select="substring-before($language,'_')"/>
  </xsl:variable>
  <xsl:variable name="lang-CC">
     <xsl:copy-of
            select="substring-before(substring-after($language,'_'),'.')"/>
  </xsl:variable>
  <xsl:variable name="lang-charmap">
    <xsl:choose>
      <xsl:when test="contains($language,'@')">
         <xsl:copy-of
               select="substring-before(substring-after($language,'.'),'@')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="substring-after($language,'.')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="lang-modifier">
    <xsl:choose>
      <xsl:when test="contains($language,'@')">
         <xsl:copy-of select="concat('@',substring-after($language,'@'))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="''"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

<!-- simple instructions for removing .la files. -->
  <xsl:variable name="la-files-instr">

for libdir in /lib /usr/lib $(find /opt -name lib); do
  find $libdir -name \*.la           \
             ! -path \*ImageMagick\* \
               -delete
done

</xsl:variable>

  <xsl:variable name="list-stat-norm"
                select="concat(' ', normalize-space($list-stat),' ')"/>

<!-- To be able to use the single quote in tests -->
  <xsl:variable name="APOS">'</xsl:variable>

<!-- end parameters and global variables -->

<!-- include the templates for the screen children of role="install" sect2 -->
  <xsl:include href="gen-install.xsl"/>

<!--=================== Begin processing ========================-->

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1[@id != 'bootscripts' and
                                         @id != 'systemd-units']"/>
  </xsl:template>

<!--=================== Master chunks code ======================-->

  <xsl:template match="sect1">

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
      <xsl:text>#!/bin/bash
set -e
unset MAKELEVEL
<!-- the above is needed for some packages -->
</xsl:text>
      <xsl:choose>
        <!-- Package page -->
        <xsl:when test="sect2[@role='package']">
          <!-- We build in a subdirectory, whose name may be needed
               if using package management (see envars.conf), so
               "export" it -->
          <xsl:text>export JH_PKG_DIR=</xsl:text>
          <xsl:value-of select="$filename"/>
          <xsl:text>
SRC_DIR=${JH_SRC_ARCHIVE}${JH_SRC_SUBDIRS:+/${JH_PKG_DIR}}
BUILD_DIR=${JH_BUILD_ROOT}${JH_BUILD_SUBDIRS:+/${JH_PKG_DIR}}
mkdir -p $SRC_DIR
mkdir -p $BUILD_DIR

</xsl:text>

<!-- If stats are requested, include some definitions and intitializations -->
          <xsl:if test="contains($list-stat-norm,concat(' ',@id,' '))">
            <xsl:text>INFOLOG=$(pwd)/info-${JH_PKG_DIR}
TESTLOG=$(pwd)/test-${JH_PKG_DIR}
unset MAKEFLAGS
#MAKEFLAGS=-j4
echo MAKEFLAGS: $MAKEFLAGS > $INFOLOG
: > $TESTLOG
PKG_DEST=${BUILD_DIR}/dest
rm -rf $PKG_DEST

</xsl:text>
          </xsl:if>
        <!-- Download code and build commands -->
          <xsl:apply-templates select="sect2"/>
        <!-- Clean-up -->
          <xsl:text>cd $BUILD_DIR
[[ -n "$JH_KEEP_FILES" ]] || </xsl:text>
        <!-- In some case, some files in the build tree are owned
             by root -->
          <xsl:if test="$sudo='y'">
            <xsl:text>sudo </xsl:text>
          </xsl:if>
          <xsl:text>rm -rf $JH_UNPACKDIR unpacked&#xA;&#xA;</xsl:text>
        </xsl:when>
      <!-- Non-package page -->
        <xsl:otherwise>
          <xsl:apply-templates select=".//screen" mode="not-pack"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>exit</xsl:text>
    </exsl:document>
  </xsl:template>

<!--======================= Sub-sections code =======================-->

  <xsl:template match="sect2">
    <xsl:choose>

      <xsl:when test="@role = 'package'">
        <xsl:text>cd $SRC_DIR
</xsl:text>
        <!-- Download information is in bridgehead tags -->
        <xsl:apply-templates select="bridgehead[@renderas='sect3']"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when><!-- @role="package" -->

      <xsl:when test="@role = 'qt4-prefix' or @role = 'qt5-prefix'">
        <xsl:apply-templates select=".//screen[./userinput]"/>
      </xsl:when>

      <xsl:when test="@role = 'installation'">
        <xsl:text>
cd $BUILD_DIR
find . -maxdepth 1 -mindepth 1 -type d | xargs </xsl:text>
        <xsl:if test="$sudo='y'">
          <xsl:text>sudo </xsl:text>
        </xsl:if>
        <xsl:text>rm -rf

</xsl:text>
<!-- If stats are requested, insert the start size -->
        <xsl:if test="contains($list-stat-norm,concat(' ',../@id,' '))">
          <xsl:text>echo Start Size: $(sudo du -skx --exclude home /) >> $INFOLOG

</xsl:text>
        </xsl:if>

        <xsl:text>case $PACKAGE in
  *.tar.gz|*.tar.bz2|*.tar.xz|*.tgz|*.tar.lzma)
     tar -xvf $SRC_DIR/$PACKAGE &gt; unpacked
     JH_UNPACKDIR=`grep '[^./]\+' unpacked | head -n1 | sed 's@^\./@@;s@/.*@@'`
     ;;
  *.tar.lz)
     bsdtar -xvf $SRC_DIR/$PACKAGE 2&gt; unpacked
     JH_UNPACKDIR=`head -n1 unpacked | cut  -d" " -f2 | sed 's@^\./@@;s@/.*@@'`
     ;;
  *.zip)
     zipinfo -1 $SRC_DIR/$PACKAGE &gt; unpacked
     JH_UNPACKDIR="$(sed 's@/.*@@' unpacked | uniq )"
     if test $(wc -w &lt;&lt;&lt; $JH_UNPACKDIR) -eq 1; then
       unzip $SRC_DIR/$PACKAGE
     else
       JH_UNPACKDIR=${PACKAGE%.zip}
       unzip -d $JH_UNPACKDIR $SRC_DIR/$PACKAGE
     fi
     ;;
  *)
     JH_UNPACKDIR=$JH_PKG_DIR-build
     mkdir $JH_UNPACKDIR
     cp $SRC_DIR/$PACKAGE $JH_UNPACKDIR
     cp $(find . -mindepth 1 -maxdepth 1 -type l) $JH_UNPACKDIR
     ;;
esac
export JH_UNPACKDIR
cd $JH_UNPACKDIR&#xA;
</xsl:text>
<!-- If stats are requested, insert the start time -->
        <xsl:if test="contains($list-stat-norm,concat(' ',../@id,' '))">
          <xsl:text>echo Start Time: ${SECONDS} >> $INFOLOG

</xsl:text>
        </xsl:if>

        <xsl:apply-templates
             mode="installation"
             select=".//screen[not(@role = 'nodump') and ./userinput] |
                     .//para/command[contains(text(),'check') or
                                     contains(text(),'test')]"/>
        <xsl:if test="$sudo = 'y'">
          <xsl:text>sudo /sbin/</xsl:text>
        </xsl:if>
        <xsl:text>ldconfig&#xA;&#xA;</xsl:text>
      </xsl:when><!-- @role="installation" -->

      <xsl:when test="@role = 'configuration'">
        <xsl:apply-templates mode="config"
             select=".//screen[not(@role = 'nodump') and ./userinput]"/>
      </xsl:when><!-- @role="configuration" -->

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
    <xsl:text> ]] ; then
  if [[ -f $JH_SRC_ARCHIVE/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text> ]] ; then&#xA;</xsl:text>
    <xsl:text>    cp $JH_SRC_ARCHIVE/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text> $</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text>
  else&#xA;</xsl:text>
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
    <xsl:text>    wget -T 30 -t 5 ${JH_FTP_SERVER}svn/</xsl:text>
    <xsl:value-of select="$first_letter"/>
    <xsl:text>/$</xsl:text>
    <xsl:value-of select="$varname"/>
    <xsl:text>
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
<!-- link additional packages into $BUILD_DIR, because they are supposed to
     be there-->
    <xsl:if test="string($varname) != 'PACKAGE'">
      <xsl:text>[[ "$SRC_DIR" != "$BUILD_DIR" ]] &amp;&amp; ln -sf $SRC_DIR/$</xsl:text>
      <xsl:value-of select="$varname"/>
      <xsl:text> $BUILD_DIR
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

<!--====================== Non package code =========================-->

  <xsl:template match="screen" mode="not-pack">
    <xsl:choose>
      <xsl:when test="ancestor::sect1[@id='postlfs-config-vimrc']">
        <xsl:text>
cat > ~/.vimrc &lt;&lt;EOF
</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>
EOF
</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="config"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
<!--======================== Commands code ==========================-->
<!-- Code for installation instructions is in gen-install.xsl -->

  <xsl:template match="screen">
    <xsl:choose>
<!-- instructions run as root (configuration mainly) -->
      <xsl:when test="@role = 'root'">
        <xsl:if test="not(preceding-sibling::screen[1][@role='root'])">
          <xsl:if test="$sudo = 'y'">
            <xsl:text>sudo -E sh &lt;&lt; ROOT_EOF&#xA;</xsl:text>
          </xsl:if>
        </xsl:if>
        <xsl:apply-templates mode="root"/>
        <xsl:if test="not(following-sibling::screen[1][@role='root'])">
          <xsl:if test="$sudo = 'y'">
            <xsl:text>&#xA;ROOT_EOF</xsl:text>
          </xsl:if>
        </xsl:if>
      </xsl:when>
<!-- then all the instructions run as user -->
      <xsl:otherwise>
        <xsl:apply-templates select="userinput"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template name="set-bootpkg-dir">
    <xsl:param name="bootpkg" select="'bootscripts'"/>
    <xsl:param name="url" select="''"/>
    <xsl:text>BOOTPKG_DIR=blfs-</xsl:text>
    <xsl:copy-of select="$bootpkg"/>
    <xsl:text>
BOOTSRC_DIR=${JH_SRC_ARCHIVE}${JH_SRC_SUBDIRS:+/${BOOTPKG_DIR}}
BOOTBUILD_DIR=${JH_BUILD_ROOT}${JH_BUILD_SUBDIRS:+/${BOOTPKG_DIR}}
mkdir -p $BOOTSRC_DIR
mkdir -p $BOOTBUILD_DIR

pushd $BOOTSRC_DIR
URL=</xsl:text>
      <xsl:value-of select="$url"/>
    <xsl:text>
BOOTPACKG=$(basename $URL)
if [[ ! -f $BOOTPACKG ]] ; then
  if [[ -f $JH_SRC_ARCHIVE/$BOOTPACKG ]] ; then
    cp $JH_SRC_ARCHIVE/$BOOTPACKG $BOOTPACKG
  else
    wget -T 30 -t 5 $URL
  fi
  rm -f $BOOTBUILD_DIR/unpacked
fi

cd $BOOTBUILD_DIR
if [[ -e unpacked ]] ; then
  BOOTUNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
  if ! [[ -d $BOOTUNPACKDIR ]]; then
    tar -xvf $BOOTSRC_DIR/$BOOTPACKG > unpacked
    BOOTUNPACKDIR=`head -n1 unpacked | sed 's@^./@@;s@/.*@@'`
  fi
else
  tar -xvf $BOOTSRC_DIR/$BOOTPACKG > unpacked
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

  <xsl:template match="command" mode="installation">
    <xsl:variable name="ns" select="normalize-space(string())"/>
    <xsl:variable name="first"
         select="not(
                   boolean(
                     preceding-sibling::command[contains(text(),'check') or
                                                contains(text(),'test')]))"/>
    <xsl:variable name="last"
         select="not(
                   boolean(
                     following-sibling::command[contains(text(),'check') or
                                                contains(text(),'test')]))"/>
    <xsl:choose>
      <xsl:when test="contains($list-stat-norm,
                               concat(' ',ancestor::sect1/@id,' '))">
        <xsl:if test="$first">
          <xsl:text>
echo Time after make: ${SECONDS} >> $INFOLOG
echo Size after make: $(sudo du -skx --exclude home /) >> $INFOLOG
echo Time before test: ${SECONDS} >> $INFOLOG

</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>#</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="contains($ns,'make')">
        <xsl:value-of select="substring-before($ns,'make ')"/>
        <xsl:text>make </xsl:text>
        <xsl:if test="not(contains($ns,'-k'))">
          <xsl:text>-k </xsl:text>
        </xsl:if>
        <xsl:value-of select="substring-after($ns,'make ')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$ns"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="contains($list-stat-norm,
                           concat(' ',ancestor::sect1/@id,' '))">
      <xsl:text> &gt;&gt; $TESTLOG 2&gt;&amp;1</xsl:text>
    </xsl:if>
    <xsl:text> || true&#xA;</xsl:text>
      <xsl:if test="contains($list-stat-norm,
                             concat(' ',ancestor::sect1/@id,' ')) and $last">
        <xsl:text>
echo Time after test: ${SECONDS} >> $INFOLOG
echo Size after test: $(sudo du -skx --exclude home /) >> $INFOLOG
echo Time before install: ${SECONDS} >> $INFOLOG

</xsl:text>
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
    <xsl:choose>
<!-- When adding a user to a group, the book uses "username" in a replaceable
     tag. Replace by the user name only if not running as root -->
      <xsl:when test="contains(string(),'username') and $sudo='y'">
        <xsl:text>$USER</xsl:text>
      </xsl:when>
<!-- The next three entries are for gpm. I guess those settings are OK
     for a laptop or desktop. -->
      <xsl:when test="contains(string(),'yourprotocol')">
        <xsl:text>imps2</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'yourdevice')">
        <xsl:text>/dev/input/mice</xsl:text>
      </xsl:when>
      <xsl:when test="contains(string(),'additional options')"/>
<!-- the book has four fields for language. The language param is
     broken into four pieces above. We use the results here. -->
      <xsl:when test="contains(string(),'&lt;ll&gt;')">
        <xsl:copy-of select="$lang-ll"/>
      </xsl:when>
      <xsl:when test="contains(string(),'&lt;CC&gt;')">
        <xsl:copy-of select="$lang-CC"/>
      </xsl:when>
      <xsl:when test="contains(string(),'&lt;charmap&gt;')">
        <xsl:copy-of select="$lang-charmap"/>
      </xsl:when>
      <xsl:when test="contains(string(),'@modifier')">
        <xsl:copy-of select="$lang-modifier"/>
      </xsl:when>
<!-- At several places, the number of jobs is given as "N" in a replaceable
     tag. We either detect "N" alone or &lt;N&gt; Replace N with 4. -->
      <xsl:when test="contains(string(),'&lt;N&gt;') or string()='N'">
        <xsl:text>4</xsl:text>
      </xsl:when>
<!-- Mercurial config file uses user_name. Replace only if non root.
     Add a bogus mail field. That works for the proposed tests anyway. -->
      <xsl:when test="contains(string(),'user_name') and $sudo='y'">
        <xsl:text>$USER ${USER}@mail.bogus</xsl:text>
      </xsl:when>
<!-- Use the config for Gtk+3 as is -->
      <xsl:when test="ancestor::sect1[@id='gtk3']">
        <xsl:copy-of select="string()"/>
      </xsl:when>
<!-- Give 1Gb to fop. Hopefully, nobody has less RAM nowadays. -->
      <xsl:when test="contains(string(),'RAM_Installed')">
        <xsl:text>1024</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="replaceable" mode="root">
    <xsl:apply-templates select="."/>
  </xsl:template>

  <xsl:template name="output-destdir">
    <xsl:apply-templates
       select="userinput|following-sibling::screen[@role='root']/userinput"
       mode="destdir"/>
    <xsl:text>
echo Time after install: ${SECONDS} >> $INFOLOG
echo Size after install: $(sudo du -skx --exclude home /) >> $INFOLOG
</xsl:text>
  </xsl:template>

  <xsl:template match="userinput" mode="destdir">
    <xsl:choose>
      <xsl:when test="./literal">
        <xsl:call-template name="outputpkgdest">
          <xsl:with-param name="outputstring" select="text()[1]"/>
        </xsl:call-template>
        <xsl:apply-templates select="literal"/>
        <xsl:call-template name="outputpkgdest">
          <xsl:with-param name="outputstring" select="text()[2]"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="outputpkgdest">
          <xsl:with-param name="outputstring" select="string()"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template name="outputpkgdest">
    <xsl:param name="outputstring" select="'foo'"/>
    <xsl:choose>
      <xsl:when test="contains($outputstring,'make ')">
        <xsl:choose>
          <xsl:when test="not(starts-with($outputstring,'make'))">
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param name="outputstring"
                              select="substring-before($outputstring,'make')"/>
            </xsl:call-template>
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param
                 name="outputstring"
                 select="substring-after($outputstring,
                                      substring-before($outputstring,'make'))"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>make DESTDIR=$PKG_DEST</xsl:text>
              <xsl:call-template name="outputpkgdest">
                <xsl:with-param
                    name="outputstring"
                    select="substring-after($outputstring,'make')"/>
              </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains($outputstring,'ninja install')">
        <xsl:choose>
          <xsl:when test="not(starts-with($outputstring,'ninja install'))">
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param name="outputstring"
                              select="substring-before($outputstring,'ninja install')"/>
            </xsl:call-template>
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param
                 name="outputstring"
                 select="substring-after($outputstring,
                                      substring-before($outputstring,'ninja install'))"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>DESTDIR=$PKG_DEST ninja</xsl:text>
              <xsl:call-template name="outputpkgdest">
                <xsl:with-param
                    name="outputstring"
                    select="substring-after($outputstring,'ninja')"/>
              </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise> <!-- no make nor ninja in this string -->
        <xsl:choose>
          <xsl:when test="contains($outputstring,'&gt;/') and
                                 not(contains(substring-before($outputstring,'&gt;/'),' /'))">
            <xsl:value-of select="substring-before($outputstring,'&gt;/')"/>
            <xsl:text>&gt;$PKG_DEST/</xsl:text>
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param name="outputstring" select="substring-after($outputstring,'&gt;/')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="contains($outputstring,' /')">
            <xsl:value-of select="substring-before($outputstring,' /')"/>
            <xsl:text> $PKG_DEST/</xsl:text>
            <xsl:call-template name="outputpkgdest">
              <xsl:with-param name="outputstring" select="substring-after($outputstring,' /')"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$outputstring"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
