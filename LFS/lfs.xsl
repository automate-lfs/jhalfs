<?xml version="1.0" encoding="ISO-8859-1"?>

<!-- $Id$ -->

<xsl:stylesheet
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:exsl="http://exslt.org/common"
      extension-element-prefixes="exsl"
      version="1.0">

<!-- Parameters -->

  <!-- which revision attribute to include: can only be sysv or systemd,
       but we leave checking to the caller-->
  <xsl:param name="revision" select="'sysv'"/>

  <!-- use package management ?
       n = no, original behavior
       y = yes, add PKG_DEST to scripts in install commands of chapter06-08
  -->
  <xsl:param name="pkgmngt" select="'n'"/>

  <!-- Package management with "porg style" ?
       n = no,  same as pkgmngt description above
       y = yes, wrap install commands of chapter06-08 into a bash function.
                note that pkgmngt must be 'y' in this case
  -->
  <xsl:param name="wrap-install" select='"n"'/>

  <!-- Run test suites?
       0 = none
       1 = only chapter06 critical testsuites
       2 = all chapter06 testsuites
       3 = all chapter05 and chapter06 testsuites
  -->
  <xsl:param name="testsuite" select="1"/>

  <!-- Bomb on test suites failures?
       n = no, I want to build the full system and review the logs
       y = yes, bomb at the first test suite failure to can review the build dir
  -->
  <xsl:param name="bomb-testsuite" select="'n'"/>

  <!-- Install vim-lang package? OBSOLETE should always be 'n'-->
  <xsl:param name="vim-lang" select="'n'"/>

  <!-- Should we strip excutables and libraries? -->
  <xsl:param name='strip' select="'n'"/>

  <!-- Should we remove .la files after chapter 5 and chapter 6? -->
  <xsl:param name='del-la-files' select="'y'"/>

  <!-- Time zone -->
  <xsl:param name="timezone" select="'GMT'"/>

  <!-- Page size -->
  <xsl:param name="page" select="'letter'"/>

  <!-- Locale settings -->
  <xsl:param name="lang" select="'C'"/>

  <!-- Install the whole set of locales -->
  <xsl:param name='full-locale' select='"n"'/>

  <!-- Hostname -->
  <xsl:param name='hostname' select='"HOSTNAME"'/>

  <!-- Network parameters: interface, ip, gateway, prefix, broadcast, domain
       and nameservers -->
  <xsl:param name='interface'   select="'eth0'"/>
  <xsl:param name='ip'          select='"10.0.2.9"'/>
  <xsl:param name='gateway'     select='"10.0.2.2"'/>
  <xsl:param name='prefix'      select='24'/>
  <xsl:param name='broadcast'   select='"10.0.2.255"'/>
  <xsl:param name='domain'      select='"lfs.org"'/>
  <xsl:param name='nameserver1' select='"10.0.2.3"'/>
  <xsl:param name='nameserver2' select='"8.8.8.8"'/>

<!-- End parameters -->

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1[not(@revision) or
                                         @revision=$revision]"/>
  </xsl:template>

  <xsl:template match="sect1">
<!-- Since this xsl:if tag encloses the whole template, it would
     be much better to transpose this condition to the select part
     of the "calling" apply-template. But that would change the numbering,
     so that it would be difficult to compare to previous versions. So for
     version 2.4, let us keep this -->
        <xsl:if test="(../@id='chapter-temporary-tools' or
                  ../@id='chapter-building-system' or
                  ../@id='chapter-bootscripts' or
                  ../@id='chapter-bootable') and
                  (sect2[not(@revision) or @revision=$revision]//..|.)/
                      screen[(not(@role) or @role != 'nodump') and
                             (not(@revision) or @revision=$revision)]/
                          userinput[not(starts-with(string(),'chroot'))]">
<!-- The last condition is a hack to allow previous versions of the
     book where the chroot commands did not have role="nodump".
     It only works if the chroot command is the only one on the page -->
        <!-- The dirs names -->
      <xsl:variable name="pi-dir" select="../processing-instruction('dbhtml')"/>
      <xsl:variable name="pi-dir-value" select="substring-after($pi-dir,'dir=')"/>
      <xsl:variable name="quote-dir" select="substring($pi-dir-value,1,1)"/>
      <xsl:variable name="dirname" select="substring-before(substring($pi-dir-value,2),$quote-dir)"/>
   <!-- The file names -->
    <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
    <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
    <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
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
    <!-- Inclusion of package manager scriptlets -->
    <xsl:if test="@id='ch-tools-stripping' and $pkgmngt='y'">
      <xsl:apply-templates
              select="document('packageManager.xml')//sect1[contains(@id,'ch-tools')]"
              mode="pkgmngt">
        <xsl:with-param name="order" select="$order"/>
        <xsl:with-param name="dirname" select="$dirname"/>
      </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="@id='ch-system-strippingagain' and $pkgmngt='y'">
      <xsl:apply-templates
              select="document('packageManager.xml')//sect1[contains(@id,'ch-system')]"
              mode="pkgmngt">
        <xsl:with-param name="order" select="$order"/>
        <xsl:with-param name="dirname" select="$dirname"/>
      </xsl:apply-templates>
    </xsl:if>
    <!-- Creating dirs and files -->
    <exsl:document href="{$dirname}/{$order}-{$filename}" method="text">
      <xsl:choose>
        <xsl:when test="@id='ch-system-creatingdirs' or
                        @id='ch-system-createfiles' or
                        @id='ch-system-strippingagain'">
          <xsl:text>#!/tools/bin/bash&#xA;set +h&#xA;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>#!/bin/bash&#xA;set +h&#xA;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="not(@id='ch-tools-stripping') and
                    not(@id='ch-system-strippingagain')">
        <xsl:text>set -e&#xA;</xsl:text>
      </xsl:if>
      <xsl:text>&#xA;</xsl:text>
      <xsl:if test="sect2[@role='installation']">
        <xsl:text>cd $PKGDIR&#xA;</xsl:text>
      </xsl:if>
      <xsl:apply-templates select="sect2[not(@revision) or
                                         @revision=$revision] |
                                   screen[(not(@role) or
                                           @role!='nodump') and
                                          (not(@revision) or
                                           @revision=$revision)]/userinput"/>
      <xsl:if test="@id='ch-system-creatingdirs' and $pkgmngt='y'">
        <xsl:apply-templates
           select="document('packageManager.xml')//sect1[
                                       @id='ch-pkgmngt-creatingdirs'
                                                        ]//userinput"
           mode="pkgmngt"/>
      </xsl:if>
      <xsl:if test="@id='ch-system-createfiles' and $pkgmngt='y'">
        <xsl:apply-templates
           select="document('packageManager.xml')//sect1[
                                       @id='ch-pkgmngt-createfiles'
                                                        ]//userinput"
           mode="pkgmngt"/>
      </xsl:if>
      <xsl:text>echo -e "\n\nTotalseconds: $SECONDS\n"&#xA;</xsl:text>
      <xsl:text>exit&#xA;</xsl:text>
    </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="sect2">
    <xsl:apply-templates
      select=".//screen[(not(@role) or
                         @role != 'nodump') and
                        (not(@revision) or
                         @revision=$revision)]/userinput[
                             @remap = 'pre' or
                             @remap = 'configure' or
                             @remap = 'make' or
                             @remap = 'test' and
                             not(current()/../@id='ch-tools-dejagnu') and
                             not(current()/../@id='ch-system-systemd')]"/>
    <xsl:if
         test="ancestor::chapter[@id != 'chapter-temporary-tools'] and
               $pkgmngt = 'y' and
               descendant::screen[not(@role) or
                                  @role != 'nodump']/userinput[
                                                    @remap='install']">
      <xsl:choose>
        <xsl:when test="$wrap-install='y'">
          <xsl:text>wrapInstall '
</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>mkdir -pv $PKG_DEST/{boot,etc,lib,bin,sbin}
mkdir -pv $PKG_DEST/usr/{lib,bin,sbin,include}
mkdir -pv $PKG_DEST/usr/share/{doc,info,man}
mkdir -pv $PKG_DEST/usr/share/man/man{1..8}
ln -sv share/{man,doc,info} $PKG_DEST/usr
case $(uname -m) in
 x86_64) ln -sv lib $PKG_DEST/lib64 &amp;&amp; ln -sv lib $PKG_DEST/usr/lib64 ;;
esac
</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="../@id = 'ch-system-glibc' and
                  @role='installation' and
                  $pkgmngt = 'y' and
                  $wrap-install = 'n'">
      <xsl:text>mkdir -pv $PKG_DEST/usr/include/{rpc,rpcsvc}
</xsl:text>
    </xsl:if>
    <xsl:if test="../@id = 'ch-system-libelf' and
                  @role='installation' and
                  $pkgmngt = 'y' and
                  $wrap-install = 'n'">
      <xsl:text>mkdir -pv $PKG_DEST/usr/lib/pkgconfig
</xsl:text>
    </xsl:if>
    <xsl:apply-templates
         select=".//screen[(not(@role) or
                            @role != 'nodump') and
                           (not(@revision) or
                            @revision=$revision)]/userinput[@remap = 'install']"/>
    <xsl:if test="ancestor::chapter[@id != 'chapter-temporary-tools'] and
                  descendant::screen[not(@role) or
                                     @role != 'nodump']/userinput[
                                                       @remap='install']">
      <xsl:choose>
        <xsl:when test="$pkgmngt='n'"/>
        <xsl:when test="$wrap-install='y'">
          <xsl:if test="../@id = 'ch-system-man-pages'">
<!-- these files are provided by the shadow package -->
            <xsl:text>rm -fv /usr/share/man/{man3/getspnam.3,man5/passwd.5}
</xsl:text>
          </xsl:if>
<!-- Attr man/man2 pages are already installed by man-pages. As of
     March 2013, they are the same pages.
     November 2015: now they are more accurate
     in man-pages, and the man5 section is also in man-pages... -->
          <xsl:if test="../@id = 'ch-system-attr'">
            <xsl:text>rm -fv /usr/share/man/man2/*
rm -fv /usr/share/man/man5/*
</xsl:text>
          </xsl:if>
<!-- nologin is installed by util-linux. remove it from shadow -->
          <xsl:if test="../@id = 'ch-system-shadow'">
            <xsl:text>rm -fv /usr/share/man/man8/nologin.8
rm -fv /sbin/nologin
</xsl:text>
          </xsl:if>
          <xsl:text>'
PREV_SEC=${SECONDS}
packInstall
SECONDS=${PREV_SEC}
</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="../@id = 'ch-system-man-pages'">
<!-- these files are provided by the shadow package -->
            <xsl:text>rm -fv $PKG_DEST/usr/share/man/{man3/getspnam.3,man5/passwd.5}
</xsl:text>
          </xsl:if>
<!-- Attr man/man2 pages are already installed by man-pages. As of
     March 2013, they are the same pages.
     November 2015: now they are more accurate
     in man-pages, and the man5 section is also in man-pages... -->
          <xsl:if test="../@id = 'ch-system-attr'">
            <xsl:text>rm -fv $PKG_DEST/usr/share/man/man2/*
rm -fv $PKG_DEST/usr/share/man/man5/*
</xsl:text>
          </xsl:if>
<!-- nologin is installed by util-linux. remove it from shadow -->
          <xsl:if test="../@id = 'ch-system-shadow'">
            <xsl:text>rm -fv $PKG_DEST/usr/share/man/man8/nologin.8
rm -fv $PKG_DEST/sbin/nologin
</xsl:text>
          </xsl:if>
          <xsl:text>rm -fv $PKG_DEST/{,usr/}lib64
rm -fv $PKG_DEST/usr/{man,doc,info}
for dir in $PKG_DEST/usr/share/man/man{1..8}; do
  [[ -z $(ls $dir) ]] &amp;&amp; rmdir -v $dir
done
for dir in $PKG_DEST/usr/share/{doc,info,man}; do
  [[ -z $(ls $dir) ]] &amp;&amp; rmdir -v $dir
done
for dir in $PKG_DEST/usr/{lib,bin,sbin,include}; do
  [[ -z $(ls $dir) ]] &amp;&amp; rmdir -v $dir
done
for dir in $PKG_DEST/{boot,etc,lib,bin,sbin}; do
  [[ -z $(ls $dir) ]] &amp;&amp; rmdir -v $dir
done
PREV_SEC=${SECONDS}
packInstall
SECONDS=${PREV_SEC}
rm -rf $PKG_DEST
</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="$testsuite='3' and
            ../@id='ch-tools-glibc' and
            @role='installation'">
      <xsl:copy-of select="//userinput[@remap='locale-test']"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
    <xsl:if test="../@id='ch-system-glibc' and @role='installation'">
      <xsl:choose>
        <xsl:when test="$full-locale='y'">
          <xsl:copy-of select="//userinput[@remap='locale-full']"/>
          <xsl:text>&#xA;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="//userinput[@remap='locale-test']"/>
          <xsl:text>&#xA;</xsl:text>
          <xsl:if test="not(contains(string(//userinput[@remap='locale-test']),$lang)) and $lang!='C' and $lang!='POSIX'">
            <xsl:text>if LOCALE=`grep "</xsl:text>
            <xsl:value-of select="$lang"/>
            <xsl:text>/" $PKGDIR/localedata/SUPPORTED`; then
  CHARMAP=`echo $LOCALE | sed 's,[^/]*/\([^ ]*\) [\],\1,'`
  INPUT=`echo $LOCALE | sed 's,[/.].*,,'`
  LOCALE=`echo $LOCALE | sed 's,/.*,,'`
  localedef -i $INPUT -f $CHARMAP $LOCALE
fi
</xsl:text>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:apply-templates
       select=".//screen[
                (not(@role) or
                 @role != 'nodump') and
                (not(@revision) or
                 @revision=$revision)
                        ]/userinput[
                       not(@remap) or
                       @remap='adjust' or
                       @remap='test' and current()/../@id='ch-tools-dejagnu' or
                       @remap='test' and current()/../@id='ch-system-systemd'
                                   ]"/>
  </xsl:template>

  <xsl:template match="sect1" mode="pkgmngt">
    <xsl:param name="dirname" select="chapter05"/>
    <!-- The build order -->
    <xsl:param name="order" select="062"/>
<!-- The file names -->
    <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
    <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
    <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
     <!-- Creating dirs and files -->
    <xsl:if test="count(descendant::screen/userinput) &gt; 0 and
                  count(descendant::screen/userinput) &gt;
                      count(descendant::screen[@role='nodump'])">
      <exsl:document href="{$dirname}/{$order}-{position()}-{$filename}"
                     method="text">
        <xsl:text>#!/bin/bash
set +h
set -e

cd $PKGDIR
</xsl:text>
        <xsl:apply-templates
           select=".//screen[not(@role) or
                            @role != 'nodump']/userinput[@remap != 'adjust']"
           mode="pkgmngt"/>
        <xsl:if test="$dirname = 'chapter06'">
          <xsl:text>PREV_SEC=${SECONDS}
packInstall
SECONDS=${PREV_SEC}
rm -rf "$PKG_DEST"
</xsl:text>
        </xsl:if>
        <xsl:apply-templates
           select=".//screen[not(@role) or
                             @role != 'nodump'
                            ]/userinput[not(@remap) or
                                        @remap='adjust'
                                       ]"
           mode="pkgmngt"/>
        <xsl:text>
echo -e "\n\nTotalseconds: $SECONDS\n"
exit
</xsl:text>
      </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput" mode="pkgmngt">
    <xsl:apply-templates/>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <xsl:template match="userinput">
    <xsl:choose>
      <!-- Copying the kernel config file -->
      <xsl:when test="string() = 'make mrproper'">
        <xsl:text>make mrproper&#xA;</xsl:text>
        <xsl:if test="ancestor::sect1[@id='ch-bootable-kernel']">
          <xsl:text>cp -v ../kernel-config .config&#xA;</xsl:text>
        </xsl:if>
      </xsl:when>
<!-- test instructions -->
      <xsl:when test="@remap = 'test'">
        <xsl:call-template name="comment-test">
          <xsl:with-param name="instructions" select="string()"/>
        </xsl:call-template>
      </xsl:when>
<!-- End of test instructions -->
<!-- If the instructions contain "strip ", it may mean they contain also .la
     file removal (and possibly other clean up). We therefore call a template
     to comment them out appropriately and also to not stop if stripping
     fails. -->
      <xsl:when test="contains(string(),'strip ') or
                      contains(string(),'\*.la')">
        <xsl:call-template name="comment-strip">
          <xsl:with-param name="instructions" select="string()"/>
        </xsl:call-template>
      </xsl:when>
<!-- Package management -->
<!-- Add $PKG_DEST to installation commands -->
      <xsl:when test="@remap='install' and
                      not(ancestor::chapter[
                              @id='chapter-temporary-tools'
                                           ])">
        <xsl:choose>
          <xsl:when test="$pkgmngt='n'">
            <xsl:choose>
              <xsl:when test="contains(string(),'firmware,udev')">
                <xsl:text>if [[ ! -d /lib/udev/devices ]] ; then&#xA;</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>&#xA;fi&#xA;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates/>
                <xsl:text>&#xA;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$wrap-install='y'">
            <xsl:choose>
              <xsl:when test="./literal">
                <xsl:call-template name="output-wrap">
                  <xsl:with-param name="commands" select="text()[1]"/>
                </xsl:call-template>
                <xsl:apply-templates select="literal"/>
                <xsl:call-template name="output-wrap">
                  <xsl:with-param name="commands" select="text()[2]"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="output-wrap">
                  <xsl:with-param name="commands" select="string()"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text>&#xA;</xsl:text>
          </xsl:when>
          <xsl:otherwise><!--pkgmngt = 'y' and wrap-install='n'-->
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
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when> <!-- @remap='install' -->
      <!-- if package management, we should make an independant package for
           tzdata. -->
      <xsl:when test="contains(string(),'tzdata') and $pkgmngt='y'">
        <xsl:text>
OLD_PKG_DEST="$PKG_DEST"
OLD_PKGDIR=$PKGDIR
PKG_DEST=$(dirname $OLD_PKG_DEST)/001-tzdata
PKGDIR=$(dirname $PKGDIR)/tzdata-</xsl:text>
        <xsl:copy-of select="substring-before(
                               substring-after(string(),'tzdata'),
                               '.tar')"/>
        <xsl:text>
</xsl:text>
        <xsl:choose>
          <xsl:when test="$wrap-install='n'">
            <xsl:copy-of select="substring-before(string(),'ZONEINFO=')"/>
            <xsl:text>ZONEINFO=$PKG_DEST</xsl:text>
            <xsl:copy-of select="substring-after(string(),'ZONEINFO=')"/>
            <xsl:text>
PREV_SEC=${SECONDS}
packInstall
SECONDS=${PREV_SEC}
rm -rf $PKG_DEST
</xsl:text>
          </xsl:when>
          <xsl:otherwise><!-- wrap-install='y' -->
            <xsl:copy-of select="substring-before(string(),'ZONEINFO=')"/>
            <xsl:text>
wrapInstall '
ZONEINFO=</xsl:text>
            <xsl:copy-of select="substring-after(string(),'ZONEINFO=')"/>
            <xsl:text>'
PREV_SEC=${SECONDS}
packInstall
SECONDS=${PREV_SEC}
</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>
PKG_DEST=$OLD_PKG_DEST
unset OLD_PKG_DEST
PKGDIR=$OLD_PKGDIR
unset OLD_PKGDIR
</xsl:text>
      </xsl:when><!-- addition for tzdata + package management -->
      <!-- End addition for package management -->
      <!-- The rest of commands -->
      <xsl:otherwise>
        <xsl:apply-templates/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:choose>
      <xsl:when test="ancestor::sect1[@id='ch-system-glibc']">
        <xsl:value-of select="$timezone"/>
      </xsl:when>
      <xsl:when test="ancestor::sect1[@id='ch-system-groff']">
        <xsl:value-of select="$page"/>
      </xsl:when>
      <xsl:when test="contains(string(.),'&lt;ll&gt;_&lt;CC&gt;')">
        <xsl:value-of select="$lang"/>
      </xsl:when>
      <xsl:when test="contains(string(.),'Domain')">
        <xsl:value-of select="$domain"/>
      </xsl:when>
      <xsl:when test="contains(string(.),'primary')">
        <xsl:value-of select="$nameserver1"/>
      </xsl:when>
      <xsl:when test="contains(string(.),'secondary')">
        <xsl:value-of select="$nameserver2"/>
      </xsl:when>
      <xsl:when test="contains(string(.),'192.168.1.1')">
        <xsl:value-of select="$ip"/>
      </xsl:when>
      <xsl:when test="contains(string(.),'192.168.0.2')">
        <xsl:value-of select="$ip"/>
      </xsl:when>
<!-- Only adapted to LFS-20170310 and later -->
      <xsl:when test="contains(string(.),'HOSTNAME')">
        <xsl:value-of select="$hostname"/>
      </xsl:when>
      <xsl:when test="contains(string(.),'FQDN')">
        <xsl:value-of select="$hostname"/>
        <xsl:text>.</xsl:text>
        <xsl:value-of select="$domain"/>
      </xsl:when>
      <xsl:when test="contains(string(.),'alias')"/>
      <xsl:when test="contains(string(.),'&lt;lfs&gt;')">
        <xsl:value-of select="$hostname"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="literal">
    <xsl:choose>
      <xsl:when test="contains(string(),'ONBOOT')">
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring" select="string()"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains(string(),'[Match]')">
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring" select="string()"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="outputnet">
    <xsl:param name="netstring" select="''"/>
    <!-- We suppose that book example has the following values:
         - interface: eth0
         - ip: 192.168.1.2
         - gateway: 192.168.1.1
         - prefix: 24
         - broadcast: 192.168.1.255
         Change below if book changes -->
    <xsl:choose>
      <xsl:when test="contains($netstring,'eth0')">
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'eth0')"/>
        </xsl:call-template>
        <xsl:value-of select="$interface"/>
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'eth0')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($netstring,'192.168.1.1')">
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'192.168.1.1')"/>
        </xsl:call-template>
        <xsl:value-of select="$gateway"/>
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'192.168.1.1')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- must test this before the following, because 192.168.1.255 contains
           192.168.1.2! -->
      <xsl:when test="contains($netstring,'192.168.1.255')">
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'192.168.1.255')"/>
        </xsl:call-template>
        <xsl:value-of select="$broadcast"/>
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'192.168.1.255')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($netstring,'192.168.1.2')">
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'192.168.1.2')"/>
        </xsl:call-template>
        <xsl:value-of select="$ip"/>
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'192.168.1.2')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($netstring,'24')">
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'24')"/>
        </xsl:call-template>
        <xsl:value-of select="$prefix"/>
        <xsl:call-template name="outputnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'24')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$netstring"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="outputsysdnet">
    <xsl:param name="netstring" select="''"/>
    <!-- We suppose that book example has the following values:
         - interface: eth0
         - ip: 192.168.0.2
         - gateway: 192.168.0.1
         - prefix: 24
         - DNS: 192.168.0.1
         - Domain: <Your Domain Name>
         and gateway comes before DNS. Change below if book changes -->
    <xsl:choose>
      <xsl:when test="contains($netstring,'eth0')">
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'eth0')"/>
        </xsl:call-template>
        <xsl:value-of select="$interface"/>
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'eth0')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($netstring,'192.168.0.1') and
                      contains($netstring,'Gateway')">
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'192.168.0.1')"/>
        </xsl:call-template>
        <xsl:value-of select="$gateway"/>
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'192.168.0.1')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($netstring,'192.168.0.1') and
                      not(contains($netstring,'Gateway'))">
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'192.168.0.1')"/>
        </xsl:call-template>
        <xsl:value-of select="$nameserver1"/>
        <xsl:text>
DNS=</xsl:text>
        <xsl:value-of select="$nameserver2"/>
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'192.168.0.1')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($netstring,'192.168.0.2')">
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'192.168.0.2')"/>
        </xsl:call-template>
        <xsl:value-of select="$ip"/>
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'192.168.0.2')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($netstring,'24')">
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'24')"/>
        </xsl:call-template>
        <xsl:value-of select="$prefix"/>
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'24')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($netstring,'&lt;Your Domain Name&gt;')">
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-before($netstring,'&lt;Your Domain Name&gt;')"/>
        </xsl:call-template>
        <xsl:value-of select="$domain"/>
        <xsl:call-template name="outputsysdnet">
          <xsl:with-param name="netstring"
                          select="substring-after($netstring,'&lt;Your Domain Name&gt;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$netstring"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="outputpkgdest">
    <xsl:param name="outputstring" select="foo"/>
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
           <xsl:choose>
<!-- special cases (no DESTDIR) here -->
            <xsl:when test="ancestor::sect1[@id='ch-system-glibc']">
             <xsl:text>make install_root=$PKG_DEST -j1</xsl:text>
             <xsl:value-of
               select="substring-before(substring-after(string(),'make'),
                                        'install')"/>
             <xsl:text>install&#xA;</xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::sect1[@id='ch-system-bzip2']">
             <xsl:text>make PREFIX=$PKG_DEST/usr install&#xA;</xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::sect1[@id='ch-system-sysklogd']">
  <xsl:text>make BINDIR=$PKG_DEST/sbin prefix=$PKG_DEST install&#xA;</xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::sect1[@id='ch-system-iproute2']">
             <xsl:text>make DESTDIR=$PKG_DEST DOCDIR=</xsl:text>
             <xsl:value-of
               select="substring-before(substring-after(string(),'DOCDIR='),
                                        'install')"/>
             <xsl:text>install&#xA;</xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::sect1[@id='ch-system-sysvinit']">
             <xsl:text>make ROOT=$PKG_DEST</xsl:text>
             <xsl:value-of
               select="substring-before(substring-after(string(),'make'),
                                        'install')"/>
             <xsl:text>install&#xA;</xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::sect1[@id='ch-bootable-kernel']">
             <xsl:text>make INSTALL_MOD_PATH=$PKG_DEST</xsl:text>
             <xsl:value-of
               select="substring-before(substring-after(string(),'make'),
                                        'install')"/>
             <xsl:text>install&#xA;</xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::sect1[@id='ch-system-attr']">
              <xsl:text>DIST_ROOT=$PKG_DEST make</xsl:text>
              <xsl:call-template name="outputpkgdest">
                <xsl:with-param name="outputstring"
                                select="substring-after($outputstring,'make')"/>
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
          <xsl:otherwise> <!-- "ninja" is the first word and is followed by
                                "install"-->
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

  <xsl:variable name="APOS">'</xsl:variable>
  <xsl:template name="output-wrap">
    <xsl:param name="commands" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($commands,string($APOS))">
        <xsl:call-template name="output-wrap">
          <xsl:with-param name="commands"
                          select="substring-before($commands,string($APOS))"/>
        </xsl:call-template>
        <xsl:text>'\''</xsl:text>
        <xsl:call-template name="output-wrap">
          <xsl:with-param name="commands"
                          select="substring-after($commands,string($APOS))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$commands"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="comment-strip">
    <xsl:param name="instructions" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($instructions,'&#xA;')">
        <xsl:call-template name="comment-strip">
          <xsl:with-param name="instructions"
                          select="substring-before($instructions,'&#xA;')"/>
        </xsl:call-template>
        <xsl:call-template name="comment-strip">
          <xsl:with-param name="instructions"
                          select="substring-after($instructions,'&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($instructions,'\*.la')">
        <xsl:if test="$del-la-files='n'">
          <xsl:text># </xsl:text>
        </xsl:if>
        <xsl:value-of select="$instructions"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="contains($instructions,'strip ')">
        <xsl:if test="$strip='n'">
          <xsl:text># </xsl:text>
        </xsl:if>
        <xsl:value-of select="$instructions"/>
        <xsl:text> || true&#xA;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$instructions"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="comment-test">
    <xsl:param name="instructions" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($instructions,'&#xA;')">
        <xsl:call-template name="comment-test">
          <xsl:with-param name="instructions"
                          select="substring-before($instructions,'&#xA;')"/>
        </xsl:call-template>
        <xsl:call-template name="comment-test">
          <xsl:with-param name="instructions"
                          select="substring-after($instructions,'&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$testsuite = '0' or
                      $testsuite = '1' and
                          not(ancestor::sect1[@id='ch-system-gcc']) and
                          not(ancestor::sect1[@id='ch-system-glibc']) and
                          not(ancestor::sect1[@id='ch-system-gmp']) and
                          not(ancestor::sect1[@id='ch-system-mpfr']) and
                          not(ancestor::sect1[@id='ch-system-binutils']) or
                      $testsuite = '2' and
                          ancestor::chapter[@id='chapter-temporary-tools']">
          <xsl:text># </xsl:text>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$bomb-testsuite = 'n'">
            <xsl:choose>
              <xsl:when test="contains(string(), 'make -k')">
                <xsl:value-of select="$instructions"/>
                <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
              </xsl:when>
              <xsl:when test="contains($instructions, 'make')">
                <xsl:value-of select="substring-before($instructions, 'make')"/>
                <xsl:text>make -k</xsl:text>
                <xsl:value-of select="substring-after($instructions, 'make')"/>
                <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$instructions"/>
                <xsl:if
                  test="not(contains($instructions, '&gt;&gt;')) and
                        substring($instructions,
                                  string-length($instructions)) != '\'">
                  <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1</xsl:text>
                </xsl:if>
                <xsl:text>&#xA;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <!-- bomb-testsuite != 'n'-->
            <xsl:choose>
              <xsl:when test="contains($instructions, 'make -k')">
                <xsl:value-of select="$instructions"/>
                <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$instructions"/>
                <xsl:if test="not(contains($instructions, '&gt;&gt;')) and
                        substring($instructions,
                                  string-length($instructions)) != '\'">
                  <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1</xsl:text>
                </xsl:if>
                <xsl:text>&#xA;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise> <!-- end not bomb-test=n -->
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
