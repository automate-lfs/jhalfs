<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [
 <!ENTITY % general-entities SYSTEM "FAKEDIR/general.ent">
  %general-entities;
]>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- XSLT stylesheet to create shell scripts from LFS books. -->

<!-- ####################### PARAMETERS ################################### -->

  <!-- Run test suites?
       0 = none
       1 = only chapter06 Glibc, GCC and Binutils testsuites
       2 = all chapter06 testsuites
       3 = all chapter05 and chapter06 testsuites
  -->
  <xsl:param name="testsuite" select="1"/>

  <!-- Bomb on test suites failures?
       n = no, I want to build the full system and review the logs
       y = yes, bomb at the first test suite failure to can review the build dir
  -->
  <xsl:param name="bomb-testsuite" select="n"/>

  <!-- Install vim-lang package? -->
  <xsl:param name="vim-lang" select="y"/>

  <!-- Time zone -->
  <xsl:param name="timezone" select="GMT"/>

  <!-- Page size -->
  <xsl:param name="page" select="letter"/>

  <!-- Locale setting -->
  <xsl:param name="lang" select="C"/>

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

    <xsl:text>set +h&#xA;</xsl:text>

    <xsl:if test="not(@id='ch-tools-stripping') and
                  not(@id='ch-system-strippingagain')">
      <xsl:text>set -e&#xA;</xsl:text>
    </xsl:if>

    <xsl:text>&#xA;</xsl:text>
  </xsl:template>


    <!-- Extra previous commands needed by the book but not inside screen tags -->
  <xsl:template name="pre_commands">
    <xsl:if test="sect2[@role='installation']">
      <xsl:text>cd $PKGDIR&#xA;</xsl:text>
    </xsl:if>
    <xsl:if test="@id='ch-system-vim' and $vim-lang = 'y'">
      <xsl:text>tar -xvf ../vim-&vim-version;-lang.* --strip-components=1&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>


    <!-- Extra post commands needed by the book but not inside screen tags -->
  <xsl:template name="post_commands">
    <xsl:if test="$testsuite='3' and @id='ch-tools-glibc'">
      <xsl:copy-of select="//userinput[@remap='locale-test']"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>


    <!-- Script footer -->
  <xsl:template name="footer">
    <xsl:if test="not(@id='ch-system-chroot') and
                  not(@id='ch-system-revisedchroot')">
      <xsl:text>echo -e "\n\nTotalseconds: $SECONDS\n"&#xA;</xsl:text>
    </xsl:if>

    <xsl:text>exit&#xA;</xsl:text>
  </xsl:template>

<!-- ######################################################################## -->

<!-- ############################# MATCH TEMPLATES ########################## -->

    <!-- Root element -->
  <xsl:template match="/">
    <xsl:apply-templates select="//chapter"/>
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
      <xsl:variable name="order" select="concat($ch_order,'_',$sect1_order)"/>

        <!-- Creating dirs and files -->
      <exsl:document href="{$dirname}/{$order}-{$filename}" method="text">
        <xsl:call-template name="header"/>
        <xsl:call-template name="pre_commands"/>
        <xsl:apply-templates select=".//screen"/>
        <xsl:call-template name="post_commands"/>
        <xsl:call-template name="footer"/>
      </exsl:document>

    </xsl:if>
  </xsl:template>






  <xsl:template match="screen">
    <xsl:if test="child::* = userinput and not(@role = 'nodump')">
      <xsl:apply-templates select="userinput" mode="screen"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput" mode="screen">
    <xsl:choose>
      <!-- Estandarized package formats -->
      <xsl:when test="contains(string(),'tar.gz')">
        <xsl:value-of select="substring-before(string(),'tar.gz')"/>
        <xsl:text>tar.*</xsl:text>
        <xsl:value-of select="substring-after(string(),'tar.gz')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- Avoiding a race condition in a patch -->
      <xsl:when test="contains(string(),'debian_fixes')">
        <xsl:value-of select="substring-before(string(),'patch')"/>
        <xsl:text>patch -Z</xsl:text>
        <xsl:value-of select="substring-after(string(),'patch')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- Fix Udev reinstallation after a build failure -->
      <xsl:when test="contains(string(),'firmware,udev')">
        <xsl:text>if [[ ! -d /lib/udev/devices ]] ; then&#xA;</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>&#xA;fi&#xA;</xsl:text>
      </xsl:when>
      <!-- Setting $LANG for /etc/profile -->
      <xsl:when test="ancestor::sect1[@id='ch-scripts-profile'] and
                contains(string(),'export LANG=')">
        <xsl:value-of select="substring-before(string(),'export LANG=')"/>
        <xsl:text>export LANG=</xsl:text>
        <xsl:value-of select="$lang"/>
        <xsl:value-of select="substring-after(string(),'modifiers>')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- Copying the kernel config file -->
      <xsl:when test="string() = 'make mrproper'">
        <xsl:text>make mrproper&#xA;</xsl:text>
        <xsl:text>cp -v ../kernel-config .config&#xA;</xsl:text>
      </xsl:when>
      <!-- The Bash, Coreutils, and Module-Init-Tools test suites are optional -->
      <xsl:when test="(ancestor::sect1[@id='ch-system-coreutils'] or
                       ancestor::sect1[@id='ch-system-bash'] or
                       ancestor::sect1[@id='ch-system-module-init-tools'])
                      and @remap = 'test'">
        <xsl:choose>
          <xsl:when test="$testsuite = '0' or $testsuite = '1'"/>
          <xsl:otherwise>
            <xsl:if test="not(contains(string(),'check')) and
                          not(contains(string(),'make tests'))">
              <xsl:apply-templates/>
              <xsl:text>&#xA;</xsl:text>
            </xsl:if>
            <!-- Coreutils and Module-Init-Tools -->
            <xsl:if test="contains(string(),'check')">
              <xsl:choose>
                <xsl:when test="$bomb-testsuite = 'n'">
                  <xsl:value-of select="substring-before(string(),'check')"/>
                  <xsl:text>-k check</xsl:text>
                  <xsl:value-of select="substring-after(string(),'check')"/>
                  <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates/>
                  <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1</xsl:text>
                  <xsl:if test="contains(string(),' -k ')">
                    <xsl:text> || true</xsl:text>
                  </xsl:if>
                  <xsl:text>&#xA;</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
            <!-- Bash -->
            <xsl:if test="contains(string(),'make tests')">
              <xsl:choose>
                <xsl:when test="$bomb-testsuite = 'n'">
                  <xsl:value-of select="substring-before(string(),'tests')"/>
                  <xsl:text>-k tests</xsl:text>
                  <xsl:value-of select="substring-after(string(),'tests')"/>
                  <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates/>
                  <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1</xsl:text>
                  <xsl:if test="contains(string(),' -k ')">
                    <xsl:text> || true</xsl:text>
                  </xsl:if>
                  <xsl:text>&#xA;</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Fixing toolchain test suites run -->
      <xsl:when test="(string() = 'make check' or
                       string() = 'make -k check') and
                      (ancestor::sect1[@id='ch-system-gcc'] or
                       ancestor::sect1[@id='ch-system-glibc'] or
                       ancestor::sect1[@id='ch-system-binutils'] or
                       ancestor::sect1[@id='ch-tools-gcc-pass2'])">
        <xsl:choose>
          <xsl:when test="(($testsuite = '1' or $testsuite = '2') and
                    ancestor::chapter[@id='chapter-building-system']) or
                    $testsuite = '3'">
            <xsl:choose>
              <xsl:when test="$bomb-testsuite = 'n'">
                <xsl:text>make -k check &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates/>
                <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1</xsl:text>
                <xsl:if test="contains(string(),' -k ')">
                  <xsl:text> || true</xsl:text>
                </xsl:if>
                <xsl:text>&#xA;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains(string(),'glibc-check-log')">
        <xsl:choose>
          <xsl:when test="$testsuite != '0'">
            <xsl:value-of select="substring-before(string(),'2&gt;&amp;1')"/>
            <xsl:text>&gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains(string(),'test_summary') or
                contains(string(),'expect -c')">
        <xsl:choose>
          <xsl:when test="(($testsuite = '1' or $testsuite = '2') and
                    ancestor::chapter[@id='chapter-building-system']) or
                    $testsuite = '3'">
            <xsl:apply-templates/>
            <xsl:text> &gt;&gt; $TEST_LOG&#xA;</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <!-- The rest of testsuites -->
      <xsl:when test="@remap = 'test'">
        <xsl:choose>
          <xsl:when test="$testsuite = '0'"/>
          <xsl:when test="$testsuite = '1' and
                          not(ancestor::sect1[@id='ch-system-gcc']) and
                          not(ancestor::sect1[@id='ch-system-glibc']) and
                          not(ancestor::sect1[@id='ch-system-binutils'])"/>
          <xsl:when test="$testsuite = '2' and
                          ancestor::chapter[@id='chapter-temporary-tools']"/>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="$bomb-testsuite = 'n'">
                <xsl:value-of select="substring-before(string(),'make')"/>
                <xsl:text>make -k</xsl:text>
                <xsl:value-of select="substring-after(string(),'make')"/>
                <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates/>
                <xsl:text> &gt;&gt; $TEST_LOG 2&gt;&amp;1</xsl:text>
                <xsl:if test="contains(string(),' -k ')">
                  <xsl:text> || true</xsl:text>
                </xsl:if>
                <xsl:text>&#xA;</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Don't stop on strip run -->
      <xsl:when test="contains(string(),'strip ')">
        <xsl:apply-templates/>
        <xsl:text> || true&#xA;</xsl:text>
      </xsl:when>
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
      <xsl:otherwise>
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
