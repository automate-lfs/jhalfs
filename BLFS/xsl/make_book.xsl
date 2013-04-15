<?xml version="1.0" encoding="ISO-8859-1"?>

<!-- $Id: make_book.xsl 31 2012-02-19 08:25:04Z labastie $ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:param name="list" select="''"/>
  <xsl:param name="MTA" select="'sendmail'"/>

  <xsl:output
    method="xml"
    encoding="ISO-8859-1"
    doctype-system="http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd"/>

  <xsl:template match="/">
    <book>
      <xsl:copy-of select="/book/bookinfo"/>
      <preface>
        <?dbhtml filename="preface.html"?>
        <title>Preface</title>
        <xsl:copy-of select="id('bootscripts')"/>
      </preface>
      <chapter>
        <?dbhtml filename="chapter.html"?>
        <title>Installing packages in dependency build order</title>
        <xsl:call-template name="apply-list">
          <xsl:with-param name="list" select="normalize-space($list)"/>
        </xsl:call-template>
      </chapter>
      <xsl:copy-of select="id('CC')"/>
      <xsl:copy-of select="id('MIT')"/>
      <index/>
    </book>
  </xsl:template>

<!-- apply-templates for each item in the list.
     Normally, those items are id of nodes.
     Those nodes can be sect1 (normal case),
     sect2 (python modules or DBus bindings)
     bridgehead (perl modules)
     para (dependency of perl modules).
     The templates after this one treat each of those cases.
     However, some items are xorg package names, and not id.
     We need special instructions in that case.
     The difficulty is that some of those names *are* id's,
     because they are referenced in the index.
     Hopefully, none of those id's are sect{1,2}, bridgehead or para...-->
  <xsl:template name="apply-list">
    <xsl:param name="list" select="''"/>
    <xsl:if test="string-length($list) &gt; 0">
      <xsl:choose>
        <xsl:when test="contains($list,' ')">
          <xsl:call-template name="apply-list">
            <xsl:with-param name="list"
                            select="substring-before($list,' ')"/>
          </xsl:call-template>
          <xsl:call-template name="apply-list">
            <xsl:with-param name="list"
                            select="substring-after($list,' ')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="not(id($list)/self::sect1|sect2|para|bridgehead)">
              <xsl:apply-templates
                   select="//sect1[contains(@id,'xorg7') and contains(string(.//userinput),$list)]"
                   mode="xorg">
                <xsl:with-param name="package" select="$list"/>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="id($list)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

<!-- The normal case : just copy to the book. Exceptions are if there
     is a xref, so use a special "mode" template -->
  <xsl:template match="sect1">
    <xsl:apply-templates select="." mode="sect1"/>
  </xsl:template>

  <xsl:template match="processing-instruction()" mode="sect1">
    <xsl:copy-of select="."/>
  </xsl:template>

<!-- Any node which has no xref descendant is copied verbatim. If there
     is an xref descendant, output the node and recurse. -->
  <xsl:template match="*" mode="sect1">
    <xsl:choose>
      <xsl:when test="self::xref">
        <xsl:choose>
          <xsl:when test="contains(concat(' ',normalize-space($list),' '),
                                   concat(' ',@linkend,' '))">
            <xsl:choose>
              <xsl:when test="@linkend='x-window-system' or @linkend='xorg7'">
                <xref linkend="xorg7-server"/>
              </xsl:when>
              <xsl:when test="@linkend='server-mail'">
                <xref linkend="{$MTA}"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="@linkend='bootscripts'"> 
                <xsl:copy-of select="."/>
              </xsl:when> 
              <xsl:otherwise>
                <xsl:value-of select="@linkend"/> (in full book)
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test=".//xref">
        <xsl:element name="{name()}">
          <xsl:for-each select="attribute::*">
            <xsl:attribute name="{name()}">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:for-each>
          <xsl:apply-templates mode="sect1"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- Python modules and DBus bindings -->
  <xsl:template match="sect2">
    <xsl:apply-templates select='.' mode="sect2"/>
  </xsl:template>

  <xsl:template match="*" mode="sect2">
    <xsl:choose>
      <xsl:when test="self::sect2">
        <xsl:element name="sect1">
          <xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
          <xsl:attribute name="xreflabel"><xsl:value-of select="@xreflabel"/></xsl:attribute>
          <xsl:processing-instruction name="dbhtml">filename="<xsl:value-of
                          select="@id"/>.html"</xsl:processing-instruction>
          <xsl:apply-templates mode="sect2"/>
        </xsl:element>
      </xsl:when>
      <xsl:when test="self::sect3">
        <xsl:element name="sect2">
          <xsl:attribute name="role">
            <xsl:value-of select="@role"/>
          </xsl:attribute>
          <xsl:apply-templates mode="sect2"/>
        </xsl:element>
      </xsl:when>
      <xsl:when test="self::bridgehead">
        <xsl:element name="bridgehead">
          <xsl:attribute name="renderas">
            <xsl:if test="@renderas='sect4'">sect3</xsl:if>
            <xsl:if test="@renderas='sect5'">sect4</xsl:if>
          </xsl:attribute>
          <xsl:value-of select='.'/>
        </xsl:element>
      </xsl:when>
      <xsl:when test="self::xref">
        <xsl:choose>
          <xsl:when test="contains(concat(' ',normalize-space($list),' '),
                                   concat(' ',@linkend,' '))">
            <xsl:choose>
              <xsl:when test="@linkend='x-window-system' or @linkend='xorg7'">
                <xref linkend="xorg7-server"/>
              </xsl:when>
              <xsl:when test="@linkend='server-mail'">
                <xref linkend="{$MTA}"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@linkend"/> (in full book)
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test=".//xref">
        <xsl:element name="{name()}">
          <xsl:for-each select="attribute::*">
            <xsl:attribute name="{name()}">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </xsl:for-each>
          <xsl:apply-templates mode="sect2"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- Perl modules : transform them to minimal sect1. Use a template
     for installation instructions -->
  <xsl:template match="bridgehead">
    <xsl:element name="sect1">
      <xsl:attribute name="id"><xsl:value-of select="./@id"/></xsl:attribute>
      <xsl:attribute name="xreflabel"><xsl:value-of select="./@xreflabel"/></xsl:attribute>
      <xsl:processing-instruction name="dbhtml">
     filename="<xsl:value-of select="@id"/>.html"</xsl:processing-instruction>
      <title><xsl:value-of select="./@xreflabel"/></title>
      <sect2 role="package">
        <title>Introduction to <xsl:value-of select="@id"/></title>
        <bridgehead renderas="sect3">Package Information</bridgehead>
        <itemizedlist spacing="compact">
          <listitem>
            <para>Download (HTTP): <xsl:copy-of select="./following-sibling::itemizedlist[1]/listitem/para/ulink"/></para>
          </listitem>
          <listitem>
            <para>Download (FTP): <ulink url=" "/></para>
          </listitem>
        </itemizedlist>
      </sect2>
      <xsl:choose>
        <xsl:when test="following-sibling::itemizedlist[1]//xref[@linkend='perl-standard-install'] | following-sibling::itemizedlist[1]/preceding-sibling::para//xref[@linkend='perl-standard-install']">
          <xsl:apply-templates mode="perl-install"  select="id('perl-standard-install')"/>
        </xsl:when>
        <xsl:otherwise>
          <sect2 role="installation">
            <title>Installation of <xsl:value-of select="@xreflabel"/></title>
            <para>Run the following commands:</para>
            <for-each select="following-sibling::bridgehead/preceding-sibling::screen[not(@role)]">
              <xsl:copy-of select="."/>
            </for-each>
            <para>Now, as the <systemitem class="username">root</systemitem> user:</para>
            <for-each select="following-sibling::bridgehead/preceding-sibling::screen[@role='root']">
              <xsl:copy-of select="."/>
            </for-each>
          </sect2>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

<!-- The case of depdendencies of perl modules. Same treatment
     as for perl modules. Just easier because always perl standard --> 
  <xsl:template match="para">
    <xsl:element name="sect1">
      <xsl:attribute name="id"><xsl:value-of select="./@id"/></xsl:attribute>
      <xsl:attribute name="xreflabel"><xsl:value-of select="./@xreflabel"/></xsl:attribute>
      <xsl:processing-instruction name="dbhtml">filename="<xsl:value-of
     select="@id"/>.html"</xsl:processing-instruction>
      <title><xsl:value-of select="./@xreflabel"/></title>
      <sect2 role="package">
        <title>Introduction to <xsl:value-of select="@id"/></title>
        <bridgehead renderas="sect3">Package Information</bridgehead>
        <itemizedlist spacing="compact">
          <listitem>
            <para>Download (HTTP): <xsl:copy-of select="./ulink"/></para>
          </listitem>
          <listitem>
            <para>Download (FTP): <ulink url=" "/></para>
          </listitem>
        </itemizedlist>
      </sect2>
      <xsl:apply-templates mode="perl-install"  select="id('perl-standard-install')"/>
    </xsl:element>
  </xsl:template>

<!-- copy of the perl standard installation instructions:
     suppress id (otherwise not unique) and note (which we
     do not want to apply -->
  <xsl:template match="sect2" mode="perl-install">
    <sect2 role="installation">
      <xsl:for-each select="./*">
        <xsl:if test="not(self::note)">
          <xsl:copy-of select="."/>
        </xsl:if>
      </xsl:for-each>
    </sect2>
  </xsl:template>

<!-- we have got an xorg package. We are at the installation page
     but now we need to make an autonomous page from the global
     one -->
  <xsl:template match="sect1" mode="xorg">
    <xsl:param name="package"/>
    <xsl:variable name="tarball">
      <xsl:call-template name="tarball">
        <xsl:with-param name="package" select="$package"/>
        <xsl:with-param name="cat-md5"
                        select="string(.//userinput[starts-with(string(),'cat')])"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="md5sum">
      <xsl:call-template name="md5sum">
        <xsl:with-param name="package" select="$package"/>
        <xsl:with-param name="cat-md5"
                        select=".//userinput[starts-with(string(),'cat')]"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="install-instructions">
      <xsl:call-template name="inst-instr">
        <xsl:with-param name="inst-instr"
                        select=".//userinput[starts-with(string(),'for')]"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:element name="sect1">
      <xsl:attribute name="id"><xsl:value-of select="$package"/></xsl:attribute>
      <xsl:processing-instruction name="dbhtml">
         filename="<xsl:value-of select='$package'/>.html"
      </xsl:processing-instruction>
      <title><xsl:value-of select="$package"/></title>
      <sect2 role="package">
        <title>Introduction to <xsl:value-of select="$package"/></title>
        <bridgehead renderas="sect3">Package Information</bridgehead>
        <itemizedlist spacing="compact">
          <listitem>
            <para>Download (HTTP): <xsl:element name="ulink">
              <xsl:attribute name="url">
                <xsl:value-of
                   select=".//para[contains(string(),'(HTTP)')]/ulink/@url"/>
                <xsl:value-of select="$tarball"/>
              </xsl:attribute>
             </xsl:element>
            </para>
          </listitem>
          <listitem>
            <para>Download (FTP): <xsl:element name="ulink">
              <xsl:attribute name="url">
                <xsl:value-of
                   select=".//para[contains(string(),'(FTP)')]/ulink/@url"/>
                <xsl:value-of select="$tarball"/>
              </xsl:attribute>
             </xsl:element>
            </para>
          </listitem>
          <listitem>
            <para>
              Download MD5 sum: <xsl:value-of select="$md5sum"/>
            </para>
          </listitem>
        </itemizedlist>
      </sect2>
      <sect2 role="installation">
        <title>Installation of <xsl:value-of select="$package"/></title>

        <para>
          Install <application><xsl:value-of select="$package"/></application>
          by running the following commands:
        </para>

        <screen><userinput>packagedir=<xsl:value-of
                    select="substring-before($tarball,'.tar.bz2')"/>
          <xsl:text>&#xA;</xsl:text>
          <xsl:value-of select="substring-before($install-instructions,
                                                 'as_root')"/>
        </userinput></screen>

        <para>
          Now as the <systemitem class="username">root</systemitem> user:
        </para>
        <screen role='root'>
          <userinput><xsl:value-of select="substring-after(
                                                 $install-instructions,
                                                 'as_root')"/>
          </userinput>
        </screen>
      </sect2>
    </xsl:element><!-- sect1 -->

  </xsl:template>

<!-- get the tarball name from the text that comes from the .md5 file -->
  <xsl:template name="tarball">
    <xsl:param name="package"/>
    <xsl:param name="cat-md5"/>
<!-- DEBUG
<xsl:message><xsl:text>Entering "tarball" template:
  package is: </xsl:text>
<xsl:value-of select="$package"/><xsl:text>
  cat-md5 is: </xsl:text>
<xsl:value-of select="$cat-md5"/>
</xsl:message>
END DEBUG -->
    <xsl:choose>
      <xsl:when test="contains(substring-before($cat-md5,$package),'&#xA;')">
        <xsl:call-template name="tarball">
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="cat-md5"
                          select="substring-after($cat-md5,'&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="substring-after(
                                 substring-before($cat-md5,'&#xA;'),'  ')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
<!-- same for md5sum -->
  <xsl:template name="md5sum">
    <xsl:param name="package"/>
    <xsl:param name="cat-md5"/>
    <xsl:choose>
      <xsl:when test="contains(substring-before($cat-md5,$package),'&#xA;')">
        <xsl:call-template name="md5sum">
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="cat-md5"
                          select="substring-after($cat-md5,'&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="substring-before($cat-md5,'  ')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="inst-instr">
    <xsl:param name="inst-instr"/>
    <xsl:choose>
      <xsl:when test="contains($inst-instr,'pushd')">
        <xsl:call-template name="inst-instr">
          <xsl:with-param name="inst-instr"
                          select="substring-after(
                                   substring-after($inst-instr,'pushd'),
                                   '&#xA;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="substring-before($inst-instr,'popd')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
