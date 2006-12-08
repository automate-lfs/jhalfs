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

<!-- XSLT stylesheet to create shell scripts from HLFS books. -->

  <!-- What libc implentation must be used? -->
  <xsl:param name="model" select="glibc"/>

  <!-- Is the host kernel using grsecurity? -->
  <xsl:param name="grsecurity_host" select="n"/>

  <!-- Run test suites?
       0 = none
       1 = only chapter06 Glibc, GCC and Binutils testsuites
       2 = all chapter06 testsuites
       3 = alias to 2
  -->
  <xsl:param name="testsuite" select="1"/>

  <!-- Bomb on test suites failures?
       n = no, I want to build the full system and review the logs
       y = yes, bomb at the first test suite failure to can review the build dir
  -->
  <xsl:param name="bomb-testsuite" select="n"/>

  <!-- Time zone -->
  <xsl:param name="timezone" select="GMT"/>

  <!-- Page size -->
  <xsl:param name="page" select="letter"/>

  <!-- Locale settings -->
  <xsl:param name="lang" select="C"/>
  <xsl:param name="lc_all" select="C"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

  <xsl:template match="sect1">
    <xsl:if test="(../@id='chapter-temporary-tools' or
                  ../@id='chapter-building-system' or
                  ../@id='chapter-bootable') and
                  ((@condition=$model or not(@condition)) and
                  count(descendant::screen/userinput) &gt; 0 and
                  count(descendant::screen/userinput) &gt;
                  count(descendant::screen[@role='nodump']))">
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
        <!-- Creating dirs and files -->
      <exsl:document href="{$dirname}/{$order}-{$filename}" method="text">
        <xsl:text>#!/bin/bash&#xA;set +h&#xA;</xsl:text>
        <xsl:if test="not(@id='ch-tools-stripping') and
                      not(@id='ch-system-strippingagain')">
          <xsl:text>set -e&#xA;</xsl:text>
        </xsl:if>
        <xsl:text>&#xA;</xsl:text>
        <xsl:if test="(sect2[@role='installation'] and
                           not(@id='bootable-kernel'))">
          <xsl:text>cd $PKGDIR&#xA;</xsl:text>
          <xsl:if test="@id='ch-system-uclibc'">
             <xsl:text>pushd ../; tar -xvf gettext-&gettext-version;.*; popd; &#xA;</xsl:text>
          </xsl:if>

          <!-- NEW toolchain format, from inside ./sources dir unpack binutils and gcc -->
	  <xsl:if test="@id='ch-tools-embryo-toolchain' or
                        @id='ch-tools-cocoon-toolchain' or
                        @id='ch-system-butterfly-toolchain'">
             <xsl:text>tar -xvf gcc-core-&gcc-version;.*; &#xA;</xsl:text>
             <xsl:text>tar -xvf binutils-&binutils-version;.*; &#xA;</xsl:text>
          </xsl:if>
	  <xsl:if test="@id='ch-tools-cocoon-toolchain' or
                        @id='ch-system-butterfly-toolchain'">
             <xsl:text>tar -xvf gcc-g++-&gcc-version;.*; &#xA;</xsl:text>
          </xsl:if>
          <!-- ONLY butterfly has a testsuite -->
          <xsl:if test="@id='ch-system-butterfly-toolchain' and $testsuite != '0'">
            <xsl:text>tar -xvf gcc-testsuite-&gcc-version;.*; &#xA;</xsl:text>
          </xsl:if>
          <!-- END new toolchain format -->

          <xsl:if test="@id='bootable-bootscripts'">
             <xsl:text>pushd ../; tar -xvf blfs-bootscripts-&blfs-bootscripts-version;.* ; popd; &#xA;</xsl:text>
          </xsl:if>
        </xsl:if>
        <xsl:apply-templates select=".//para/userinput | .//screen"/>
        <xsl:text>exit</xsl:text>
      </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="screen">
    <xsl:if test="(@condition=$model or not(@condition)) and
                  child::* = userinput and not(@role = 'nodump')">
      <xsl:apply-templates select="userinput" mode="screen"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="para/userinput">
    <xsl:if test="(contains(string(),'test') or
                  contains(string(),'check')) and
                  ($testsuite = '2' or $testsuite = '3')">
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
      <!-- grsecurity kernel in the host? -->
      <xsl:when test="ancestor::sect1[@id='ch-system-kernfs'] and
                contains(string(),'sysctl')
                and $grsecurity_host ='n'"/>
      <!-- Setting $LC_ALL and $LANG for /etc/profile -->
      <xsl:when test="ancestor::sect1[@id='bootable-profile'] and
                contains(string(),'export LANG=')">
        <xsl:value-of select="substring-before(string(),'export LC_ALL=')"/>
        <xsl:text>export LC_ALL=</xsl:text>
        <xsl:value-of select="$lc_all"/>
        <xsl:text>&#xA;export LANG=</xsl:text>
        <xsl:value-of select="$lang"/>
        <xsl:text>&#xA;export INPUTRC</xsl:text>
        <xsl:value-of select="substring-after(string(),'INPUTRC')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- Fixing bootscripts installation -->
      <xsl:when test="ancestor::sect1[@id='bootable-bootscripts'] and
                string() = 'make install'">
        <xsl:text>make install&#xA;</xsl:text>
        <xsl:text>cd ../blfs-bootscripts-&blfs-bootscripts-version;&#xA;</xsl:text>
      </xsl:when>
      <!-- Compile the keymap into the kernel has been dissabled -->
      <xsl:when test="contains(string(),'defkeymap')"/>
      <!-- Copying the kernel config file -->
      <xsl:when test="string() = 'make mrproper'">
        <xsl:text>make mrproper&#xA;</xsl:text>
        <xsl:text>cp -v /sources/kernel-config .config&#xA;</xsl:text>
      </xsl:when>
      <!-- No interactive commands are needed if the .config file is the proper one -->
      <xsl:when test="string() = 'make menuconfig'"/>
      <!-- For uClibc we need to cd to the Gettext package -->
      <xsl:when test="contains(string(),'cd gettext-runtime/')">
        <xsl:text>cd ../gettext-*/gettext-runtime</xsl:text>
        <xsl:value-of select="substring-after(string(),'gettext-runtime')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- The Coreutils and Module-Init-Tools test suites are optional -->
      <xsl:when test="(ancestor::sect1[@id='ch-system-coreutils'] or
                ancestor::sect1[@id='ch-system-module-init-tools']) and
                (contains(string(),'check') or
                contains(string(),'distclean') or
                contains(string(),'dummy'))">
        <xsl:choose>
          <xsl:when test="$testsuite = '0' or $testsuite = '1'"/>
          <xsl:otherwise>
            <xsl:if test="not(contains(string(),'check'))">
              <xsl:apply-templates/>
              <xsl:text>&#xA;</xsl:text>
            </xsl:if>
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
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Fixing butterfly toolchain test suites run -->
      <xsl:when test="string() = 'make -k check'
                      or string() = 'make check'
                      or string() = 'make tests'">
        <xsl:choose>
          <xsl:when test="(ancestor::sect1[@id='ch-system-butterfly-toolchain']
                          and $testsuite != '0') or
                          $testsuite = '2' or $testsuite = '3'">
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
      <!-- Fixing Glbc test suite  -->
      <xsl:when test="contains(string(),'glibc-check-log')">
        <xsl:choose>
          <xsl:when test="$testsuite != '0'">
            <xsl:value-of select="substring-before(string(),'2&gt;&amp;1')"/>
            <xsl:text>&gt;&gt; $TEST_LOG 2&gt;&amp;1 || true&#xA;</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <!-- Don't stop on strip run -->
      <xsl:when test="contains(string(),'strip ') or
                ancestor::sect2[@id='testing-gcc'] and
                not(contains(string(),'EOF'))">
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

  <xsl:template match="literal">
    <xsl:if test="@condition=$model or not(@condition)">
      <xsl:apply-templates/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:choose>
      <xsl:when test="ancestor::sect1[@id='ch-system-glibc'] or
                      ancestor::sect1[@id='ch-system-uclibc']">
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
