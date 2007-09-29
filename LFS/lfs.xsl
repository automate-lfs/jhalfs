<?xml version="1.0"?>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- XSLT stylesheet to create shell scripts from LFS books. -->

    <!-- Including common extensions templates -->
  <xsl:include href="../XSL/user.xsl"/>

<!-- ####################### PARAMETERS ################################### -->

  <!-- Run test suites?
       0 = none
       1 = only chapter06 Glibc, GCC and Binutils testsuites
       2 = all chapter06 testsuites
       3 = all chapter05 and chapter06 testsuites
  -->
  <xsl:param name="testsuite">1</xsl:param>

  <!-- Bomb on test suites failures?
       n = no, I want to build the full system and review the logs
       y = yes, bomb at the first test suite failure to can review the build dir
  -->
  <xsl:param name="bomb-testsuite">n</xsl:param>

  <!-- Install vim-lang package? -->
  <xsl:param name="vim-lang">y</xsl:param>

  <!-- Time zone -->
  <xsl:param name="timezone">GMT</xsl:param>

  <!-- Page size -->
  <xsl:param name="page">letter</xsl:param>

  <!-- Locale setting -->
  <xsl:param name="lang">C</xsl:param>

  <!-- Custom tools support -->
  <xsl:param name="custom-tools">n</xsl:param>

  <!-- blfs-tool support -->
  <xsl:param name="blfs-tool">n</xsl:param>


<!-- ####################################################################### -->

<!-- ########### NAMED USER TEMPLATES TO ALLOW CUSTOMIZATIONS ############## -->
<!-- ############ Maybe should be placed on a separate file ################ -->


    <!-- Hock for creating a custom tools directory containing scripts
         to be run after the system has been built
         (to be moved to a separate file) -->
  <xsl:template name="custom-tools">
      <!-- Fixed directory and ch_order values -->
    <xsl:variable name="basedir">custom-tools/20_</xsl:variable>
      <!-- Add an exsl:document block for each script to be created.
           This one is only a dummy example. You must replace "01" by
           the proper build order and "dummy" by the script name -->
    <exsl:document href="{$basedir}01-dummy" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE=dummy
PACKAGE=dummy
VERSION=0.0.0
TARBALL=dummy-0.0.0.tar.bz2
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
./configure --prefix=/usr
make
make check
make install
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
  </xsl:template>


<!-- ####################################################################### -->

<!-- ########################### NAMED TEMPLATES ########################### -->

    <!-- Chapter directory name (the same used for HTML output) -->
  <xsl:template name="dirname">
    <xsl:variable name="pi-dir" select="processing-instruction('dbhtml')"/>
    <xsl:variable name="pi-dir-value" select="substring-after($pi-dir,'dir=')"/>
    <xsl:variable name="quote-dir" select="substring($pi-dir-value,1,1)"/>
    <xsl:variable name="dirname" select="substring-before(substring($pi-dir-value,2),$quote-dir)"/>
    <xsl:value-of select="$dirname"/>
  </xsl:template>


    <!-- Base file name (the same used for HTML output) -->
  <xsl:template name="filename">
    <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
    <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
    <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
    <xsl:value-of select="$filename"/>
  </xsl:template>


    <!-- Script header -->
  <xsl:template name="header">
    <xsl:if test="not(@id='ch-system-chroot') and
                  not(@id='ch-system-revisedchroot')">
        <!-- Set the shabang -->
      <xsl:choose>
        <xsl:when test="@id='ch-system-creatingdirs' or
                        @id='ch-system-createfiles' or
                        @id='ch-system-strippingagain'">
          <xsl:text>#!/tools/bin/bash&#xA;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>#!/bin/bash&#xA;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
        <!-- Set +h -->
      <xsl:text>set +h&#xA;</xsl:text>
        <!-- Set -e -->
      <xsl:if test="not(@id='ch-tools-stripping') and
                    not(@id='ch-system-strippingagain')">
        <xsl:text>set -e&#xA;</xsl:text>
      </xsl:if>
        <!-- Dump a time stamp -->
      <xsl:text>&#xA;echo -e "\n`date`\n"&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>


    <!-- Dump current disk usage -->
  <xsl:template name="disk_usage">
    <xsl:if test="not(@id='ch-system-chroot') and
                  not(@id='ch-system-revisedchroot')">
      <xsl:choose>
        <xsl:when test="ancestor::chapter[@id='chapter-temporary-tools']">
          <xsl:text>echo -e "\nKB: `du -skx --exclude=jhalfs --exclude=lost+found $LFS`\n"&#xA;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>echo -e "\nKB: `du -skx --exclude=jhalfs --exclude=lost+found /`\n"&#xA;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>


    <!-- Enter to the sources dir, clean it, unpack the tarball,
         and reset the seconds counter -->
  <xsl:template name="unpack">
    <xsl:text>cd </xsl:text>
    <xsl:if test="ancestor::chapter[@id='chapter-temporary-tools']">
      <xsl:text>$LFS</xsl:text>
    </xsl:if>
    <xsl:text>/sources
PKGDIR=`tar -tf $TARBALL | head -n1 | sed -e 's@^./@@;s@/.*@@'`
if [ -d $PKGDIR ]; then
  rm -rf $PKGDIR
fi
if [ -d ${PKGDIR%-*}-build ]; then
  rm -rf ${PKGDIR%-*}-build
fi
tar -xf $TARBALL
SECONDS=0
    </xsl:text>
  </xsl:template>


    <!-- Extra previous commands needed by the book but not inside screen tags -->
  <xsl:template name="pre_commands">
    <xsl:if test="sect2[@role='installation']">
      <xsl:text>cd $PKGDIR&#xA;</xsl:text>
    </xsl:if>
    <xsl:if test="@id='ch-system-vim' and $vim-lang = 'y'">
      <xsl:text>tar -xf ../$TARBALL_1 --strip-components=1&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>


    <!-- Extra post commands needed by the book but not inside screen tags -->
  <xsl:template name="post_commands">
    <xsl:if test="$testsuite='3' and @id='ch-tools-glibc'">
      <xsl:variable name="content" select="//userinput[@remap='locale-test']"/>
      <xsl:value-of select="substring-before($content,'/usr/lib/locale')"/>
      <xsl:text>/tools/lib/locale</xsl:text>
      <xsl:value-of select="substring-after($content,'/usr/lib/locale')"/>
    </xsl:if>
  </xsl:template>


    <!-- Remove sources and build dirs, skipping it from seconds meassurament -->
  <xsl:template name="clean_sources">
    <xsl:text>cd </xsl:text>
    <xsl:if test="ancestor::chapter[@id='chapter-temporary-tools']">
      <xsl:text>$LFS</xsl:text>
    </xsl:if>
    <xsl:text>/sources
SECS=$SECONDS
rm -rf $PKGDIR
rm -rf ${PKGDIR%-*}-build
SECONDS=$SECS
    </xsl:text>
  </xsl:template>


    <!-- Script footer -->
  <xsl:template name="footer">
      <!-- Dump the build time and exit -->
    <xsl:if test="not(@id='ch-system-chroot') and
                  not(@id='ch-system-revisedchroot')">
      <xsl:text>
echo -e "\n\nTotalseconds: $SECONDS\n"

exit
      </xsl:text>
    </xsl:if>
  </xsl:template>


    <!-- Extra commads needed at the start of some screen block
         to allow automatization -->
  <xsl:template name="top_screen_build_fixes">
      <!-- Fix Udev reinstallation after a build failure or on iterative builds -->
    <xsl:if test="contains(string(),'firmware,udev')">
      <xsl:text>if [[ ! -d /lib/udev/devices ]] ; then&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>


    <!-- Extra commads needed at the end of some screen block
         to allow automatization -->
  <xsl:template name="bottom_screen_build_fixes">
      <!-- Fix Udev reinstallation after a build failure or on iterative builds -->
    <xsl:if test="contains(string(),'firmware,udev')">
      <xsl:text>&#xA;fi</xsl:text>
    </xsl:if>
      <!-- Copying the kernel config file -->
    <xsl:if test="string() = 'make mrproper'">
      <xsl:text>&#xA;cp -v ../kernel-config .config</xsl:text>
    </xsl:if>
      <!-- Don't stop on strip run -->
    <xsl:if test="contains(string(),'strip --strip')">
      <xsl:text> || true</xsl:text>
    </xsl:if>
  </xsl:template>


    <!-- Extract a package name from a package URL -->
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
        <xsl:value-of select="$sub-url"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


    <!-- Check if a package testsuite must be run -->
  <xsl:template name="run_this_test">
    <xsl:choose>
      <xsl:when test=".//userinput[@remap='test']">
        <xsl:choose>
            <!-- No testsuites run on level 0 -->
          <xsl:when test="$testsuite = '0'">0</xsl:when>
            <!-- On level 1, only final system toolchain testsuites are run -->
          <xsl:when test="$testsuite = '1' and
                          not(@id='ch-system-gcc') and
                          not(@id='ch-system-glibc') and
                          not(@id='ch-system-binutils')">0</xsl:when>
            <!-- On level 2, temp tools testsuites are not run -->
          <xsl:when test="$testsuite = '2' and
                          ../@id='chapter-temporary-tools'">0</xsl:when>
          <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:template>


    <!-- Adds blfs-tool support scripts (to be moved to a separate file) -->
  <xsl:template name="blfs-tool">
      <!-- Fixed directory and ch_order values -->
    <xsl:variable name="basedir">blfs-tool-deps/30_</xsl:variable>
      <!-- One exsl:document block for each blfs-tool dependency
           TO BE WRITTEN -->
    <exsl:document href="{$basedir}01-dummy" method="text">
      <xsl:call-template name="header"/>
      <xsl:text>
PKG_PHASE=dummy
PACKAGE=dummy
VERSION=0.0.0
TARBALL=dummy-0.0.0.tar.bz2
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="unpack"/>
      <xsl:text>
cd $PKGDIR
./configure --prefix=/usr
make
make check
make install
      </xsl:text>
      <xsl:call-template name="disk_usage"/>
      <xsl:call-template name="clean_sources"/>
      <xsl:call-template name="footer"/>
    </exsl:document>
  </xsl:template>


<!-- ######################################################################## -->

<!-- ############################# MATCH TEMPLATES ########################## -->

    <!-- Root element -->
  <xsl:template match="/">
      <!-- Start processing at chapter level -->
    <xsl:apply-templates select="//chapter"/>
      <!-- Process custom tools scripts -->
    <xsl:if test="$custom-tools = 'y'">
      <xsl:call-template name="custom-tools"/>
    </xsl:if>
      <!-- Process blfs-tool scripts -->
    <xsl:if test="$blfs-tool = 'y'">
      <xsl:call-template name="blfs-tool"/>
    </xsl:if>
  </xsl:template>


    <!-- chapter -->
  <xsl:template match="chapter">
    <xsl:if test="@id='chapter-temporary-tools' or @id='chapter-building-system'
                  or @id='chapter-bootscripts' or @id='chapter-bootable'">
        <!-- The dir name -->
      <xsl:variable name="dirname">
        <xsl:call-template name="dirname"/>
      </xsl:variable>
        <!-- The chapter order position -->
      <xsl:variable name="ch_position" select="position()"/>
      <xsl:variable name="ch_order">
        <xsl:choose>
          <xsl:when test="string-length($ch_position) = 1">
            <xsl:text>0</xsl:text>
            <xsl:value-of select="$ch_position"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$ch_position"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
        <!-- Process the childrens -->
      <xsl:apply-templates select="sect1">
        <xsl:with-param name="ch_order" select="$ch_order"/>
        <xsl:with-param name="dirname" select="$dirname"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>


    <!-- sect1 -->
  <xsl:template match="sect1">
      <!-- Inherited chapter order -->
    <xsl:param name="ch_order" select="foo"/>
      <!-- Inherited dir name -->
    <xsl:param name="dirname" select="foo"/>
      <!-- Process only files with actual build commands -->
    <xsl:if test="count(descendant::screen/userinput) &gt; 0 and
                  count(descendant::screen/userinput) &gt;
                  count(descendant::screen[@role='nodump'])">
        <!-- Base file name -->
      <xsl:variable name="filename">
        <xsl:call-template name="filename"/>
      </xsl:variable>
        <!-- Sect1 order position -->
      <xsl:variable name="sect1_position" select="position()"/>
      <xsl:variable name="sect1_order">
        <xsl:choose>
          <xsl:when test="string-length($sect1_position) = 1">
            <xsl:text>0</xsl:text>
            <xsl:value-of select="$sect1_position"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$sect1_position"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
        <!-- Script build order -->
      <xsl:variable name="order" select="concat($dirname,'/',$ch_order,'_',$sect1_order)"/>
        <!-- Must the package test suite, if any, be run? -->
      <xsl:variable name="run_this_test">
        <xsl:call-template name="run_this_test"/>
      </xsl:variable>
        <!-- Hock to insert scripts before the current one -->
      <xsl:call-template name="insert_script_before">
        <xsl:with-param name="reference" select="@id"/>
        <xsl:with-param name="order" select="$order"/>
      </xsl:call-template>
        <!-- Creating dirs and files -->
      <exsl:document href="{$order}-{$filename}" method="text">
        <xsl:call-template name="header"/>
        <xsl:call-template name="user_header"/>
        <xsl:apply-templates select="sect1info[@condition='script']">
          <xsl:with-param name="phase" select="$filename"/>
          <xsl:with-param name="run_this_test" select="$run_this_test"/>
          <xsl:with-param name="testlogfile" select="concat($ch_order,'_',$sect1_order,'-',$filename)"/>
        </xsl:apply-templates>
        <xsl:call-template name="disk_usage"/>
        <xsl:if test="sect2[@role='installation']">
          <xsl:call-template name="unpack"/>
        </xsl:if>
        <xsl:call-template name="user_pre_commands"/>
        <xsl:call-template name="pre_commands"/>
        <xsl:apply-templates select=".//screen">
          <xsl:with-param name="run_this_test" select="$run_this_test"/>
        </xsl:apply-templates>
        <xsl:call-template name="post_commands"/>
        <xsl:call-template name="user_footer"/>
        <xsl:call-template name="disk_usage"/>
        <xsl:if test="sect2[@role='installation']">
          <xsl:call-template name="clean_sources"/>
        </xsl:if>
        <xsl:call-template name="footer"/>
      </exsl:document>
        <!-- Hock to insert scripts after the current one -->
      <xsl:call-template name="insert_script_after">
        <xsl:with-param name="reference" select="@id"/>
        <xsl:with-param name="order" select="$order"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>


    <!-- sect1info -->
  <xsl:template match="sect1info">
      <!-- Used to set and initialize the testuite log file -->
    <xsl:param name="testlogfile" select="foo"/>
    <xsl:param name="run_this_test" select="foo"/>
      <!-- Build phase (base file name) to be used for PM -->
    <xsl:param name="phase" select="foo"/>
    <xsl:text>&#xA;PKG_PHASE=</xsl:text>
    <xsl:value-of select="$phase"/>
      <!-- Package name -->
    <xsl:apply-templates select="productname"/>
      <!-- Package version -->
    <xsl:apply-templates select="productnumber"/>
      <!-- Tarball name -->
    <xsl:apply-templates select="address"/>
    <xsl:if test="$run_this_test = '1'">
      <xsl:text>&#xA;TEST_LOG=</xsl:text>
      <xsl:if test="ancestor::chapter[@id='chapter-temporary-tools']">
        <xsl:text>$LFS</xsl:text>
      </xsl:if>
      <xsl:text>/jhalfs/test-logs/</xsl:text>
      <xsl:value-of select="$testlogfile"/>
      <xsl:text>&#xA;echo -e "\n`date`\n" > $TEST_LOG</xsl:text>
    </xsl:if>
    <xsl:text>&#xA;&#xA;</xsl:text>
  </xsl:template>


    <!-- productname -->
  <xsl:template match="productname">
    <xsl:text>&#xA;PACKAGE=</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>


    <!-- productnumber -->
  <xsl:template match="productnumber">
    <xsl:text>&#xA;VERSION=</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>


    <!-- address -->
  <xsl:template match="address">
    <xsl:text>&#xA;TARBALL=</xsl:text>
    <xsl:call-template name="package_name">
      <xsl:with-param name="url">
        <xsl:apply-templates/>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:apply-templates select="otheraddr" mode="tarball"/>
  </xsl:template>


    <!-- otheraddr -->
  <xsl:template match="otheraddr"/>
  <xsl:template match="otheraddr" mode="tarball">
    <xsl:text>&#xA;TARBALL_</xsl:text>
    <xsl:value-of select="position()"/>
    <xsl:text>=</xsl:text>
    <xsl:call-template name="package_name">
      <xsl:with-param name="url" select="."/>
    </xsl:call-template>
  </xsl:template>


    <!-- screen -->
  <xsl:template match="screen">
    <xsl:param name="run_this_test" select="foo"/>
    <xsl:if test="child::* = userinput and not(@role = 'nodump')">
      <xsl:call-template name="top_screen_build_fixes"/>
      <xsl:apply-templates>
        <xsl:with-param name="run_this_test" select="$run_this_test"/>
      </xsl:apply-templates>
      <xsl:call-template name="bottom_screen_build_fixes"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>


    <!-- userinput @remap='test' -->
  <xsl:template match="userinput[@remap='test']">
    <xsl:param name="run_this_test" select="foo"/>
    <xsl:apply-templates select="." mode="test">
      <xsl:with-param name="run_this_test" select="$run_this_test"/>
    </xsl:apply-templates>
  </xsl:template>


    <!-- replaceable -->
  <xsl:template match="replaceable">
    <xsl:choose>
        <!-- Configuring the Time Zone -->
      <xsl:when test="ancestor::sect2[@id='conf-glibc'] and string()='&lt;xxx&gt;'">
        <xsl:value-of select="$timezone"/>
      </xsl:when>
        <!-- Set paper size for Groff build -->
      <xsl:when test="string()='&lt;paper_size&gt;'">
        <xsl:value-of select="$page"/>
      </xsl:when>
        <!-- LANG setting in /etc/profile -->
      <xsl:when test="contains(string(),'&lt;ll&gt;_&lt;CC&gt;')">
        <xsl:value-of select="$lang"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


<!-- ######################################################################## -->

<!-- ############################# MODE TEMPLATES ########################### -->


    <!-- mode test  -->
  <xsl:template match="userinput" mode="test">
    <xsl:param name="run_this_test" select="foo"/>
    <xsl:if test="$run_this_test = '1'">
      <xsl:choose>
          <!-- Final system Glibc -->
        <xsl:when test="contains(string(),'glibc-check-log')">
          <xsl:value-of select="substring-before(string(),'2&gt;&amp;1')"/>
          <xsl:text>&gt;&gt; $TEST_LOG 2&gt;&amp;1 || true</xsl:text>
        </xsl:when>
          <!-- Module-Init-Tools -->
        <xsl:when test="ancestor::sect1[@id='ch-system-module-init-tools']
                        and contains(string(),'make check')">
          <xsl:value-of select="substring-before(string(),' check')"/>
          <xsl:if test="$bomb-testsuite = 'n'">
            <xsl:text> -k</xsl:text>
          </xsl:if>
          <xsl:text> check &gt;&gt; $TEST_LOG 2&gt;&amp;1</xsl:text>
          <xsl:if test="$bomb-testsuite = 'n'">
            <xsl:text> || true</xsl:text>
          </xsl:if>
          <xsl:value-of select="substring-after(string(),' check')"/>
        </xsl:when>
          <!-- If the book uses -k, the testsuite should never bomb -->
        <xsl:when test="contains(string(),'make -k ')">
          <xsl:apply-templates select="." mode="default"/>
          <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true</xsl:text>
        </xsl:when>
          <!-- Extra commands in Binutils and GCC -->
        <xsl:when test="contains(string(),'test_summary') or
                        contains(string(),'expect -c')">
          <xsl:apply-templates select="." mode="default"/>
          <xsl:text> &gt;&gt; $TEST_LOG</xsl:text>
        </xsl:when>
          <!-- Remaining extra testsuite commads that don't need be hacked -->
        <xsl:when test="not(contains(string(),'make '))">
          <xsl:apply-templates select="." mode="default"/>
        </xsl:when>
          <!-- Normal testsites run -->
        <xsl:otherwise>
          <xsl:choose>
              <!-- No bomb on failures -->
            <xsl:when test="$bomb-testsuite = 'n'">
              <xsl:value-of select="substring-before(string(),'make ')"/>
              <xsl:text>make -k </xsl:text>
              <xsl:value-of select="substring-after(string(),'make ')"/>
              <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true</xsl:text>
            </xsl:when>
              <!-- Bomb at the first failure -->
            <xsl:otherwise>
              <xsl:apply-templates select="." mode="default"/>
              <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
