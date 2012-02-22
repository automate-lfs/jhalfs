<?xml version="1.0"?>

<!-- $Id: dependencies.xsl 24 2012-02-16 15:26:15Z labastie $ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output method="text"/>

  <xsl:param name="MTA" select="'sendmail'"/>
  <xsl:param name="dependencies" select="2"/>
  <xsl:param name="idofdep" select="'dbus'"/>

  <xsl:key name="depnode"
           match="package|module"
           use="name"/>

  <xsl:template match="/">
    <xsl:apply-templates select="key('depnode',$idofdep)"/>
  </xsl:template>

  <xsl:template match="package">
    <xsl:apply-templates select="./dependency[@status='required']"/>
    <xsl:if test="$dependencies &gt; '1'">
      <xsl:apply-templates select="./dependency[@status='recommended']"/>
      <xsl:if test="$dependencies = '3'">
        <xsl:apply-templates select="./dependency[@status='optional']"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="module">
    <xsl:apply-templates select="./dependency[@status='required']"/>
    <xsl:if test="$dependencies &gt; '1'">
      <xsl:apply-templates select="./dependency[@status='recommended']"/>
      <xsl:if test="$dependencies = '3'">
        <xsl:apply-templates select="./dependency[@status='optional']"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="dependency">
    <xsl:variable name="depname">
      <xsl:choose>
        <xsl:when test="@name='x-window-system'">xorg7-server</xsl:when>
        <xsl:when test="@name='xorg7'">xorg7-server</xsl:when>
        <xsl:when test="@name='server-mail'">
          <xsl:value-of select="$MTA"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="install_it">
      <xsl:choose>
        <xsl:when test="@type='link'">
<!-- No way to track versions: install ! -->
          1
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="compare-versions">
            <xsl:with-param name="version" select="key('depnode',$depname)/version"/>
            <xsl:with-param name="inst-version" select="key('depnode',$depname)/inst-version"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:apply-templates select="dependency"/>
    <xsl:if test="number($install_it)">
      <xsl:value-of select="$depname"/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

<!-- lexicographic Comparison of strings. There is no way to directly
     compare strings in XPath. So find the position of the character
     in the following string. On the other hand, for numeric form style
     xx.yy.zz, we have to compare xx and x'x', which is not always
     lexicographic: think of 2.2 vs 2.10 -->

  <xsl:variable name="char-table" select="' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <xsl:variable name= "dot-table" select="'.....................................................'"/>

  <xsl:template name="compare-versions">
<!-- returns non-zero if version is greater than inst-version -->
    <xsl:param name="version"/>
    <xsl:param name="inst-version"/>
<!-- first make all separators (-_) into dots -->
    <xsl:variable name="mod-ver" select="translate($version,'-_','..')"/>
    <xsl:variable name="mod-inst-ver" select="translate($inst-version,'-_','..')"/>
<!-- Then let us find the position of the first chars in char-table (0 if numeric or dot) -->
    <xsl:variable name="pos-ver" select="string-length(substring-before($char-table,substring($version,1,1)))"/>
    <xsl:variable name="pos-inst-ver" select="string-length(substring-before($char-table,substring($inst-version,1,1)))"/>
    <xsl:choose>
      <xsl:when test="string-length($inst-version)=0">
        <xsl:value-of select="string-length($version)"/>
      </xsl:when>
      <xsl:when test="string-length($version)=0">
        0
      </xsl:when>
      <xsl:when test="$pos-ver != 0">
        <xsl:choose>
          <xsl:when test="$pos-ver = $pos-inst-ver">
            <xsl:call-template name="compare-versions">
              <xsl:with-param name="version" select="substring($version,2)"/>
              <xsl:with-param name="inst-version" select="substring($inst-version,2)"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="number($pos-ver &gt; $pos-inst-ver)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="substring($mod-ver,1,1)='.'">
        <xsl:choose>
          <xsl:when test="substring($mod-inst-ver,1,1)='.'">
            <xsl:call-template name="compare-versions">
              <xsl:with-param name="version" select="substring($version,2)"/>
              <xsl:with-param name="inst-version" select="substring($inst-version,2)"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            0
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$pos-inst-ver &gt; 0 or substring($mod-inst-ver,1,1)='.'">
<!-- do not know what to do: do not install -->
           0
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="tok" select="substring-before(concat(translate($mod-ver,$char-table,$dot-table),'.'),'.')"/>
            <xsl:variable name="inst-tok" select="substring-before(concat(translate($mod-inst-ver,$char-table,$dot-table),'.'),'.')"/>
             <xsl:choose>
               <xsl:when test="number($tok)=number($inst-tok)">
                 <xsl:call-template name="compare-versions">
                   <xsl:with-param name="version" select="substring($version,string-length($tok)+1)"/>
                   <xsl:with-param name="inst-version" select="substring($inst-version,string-length($inst-tok)+1)"/>
                 </xsl:call-template>
               </xsl:when>
               <xsl:otherwise>
                 <xsl:copy-of select="number(number($tok) &gt; number($inst-tok))"/>
               </xsl:otherwise>
             </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
