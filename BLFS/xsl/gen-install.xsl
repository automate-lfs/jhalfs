<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

<!-- $Id$ -->

  <xsl:template match="screen" mode="installation">
<!-- "nature" variables:
      - 'non-root': executable as user
      - 'config': execute as root, with no special formatting
      - 'install': execute as root, with PKG_DEST or escape instructions
      - 'none': does not exist (for preceding of following uniquely)
-->
    <xsl:variable name="my-nature">
      <xsl:choose>
        <xsl:when test="not(@role)">
          <xsl:text>non-root</xsl:text>
        </xsl:when>
        <xsl:when test="contains(string(),'useradd') or
                        contains(string(),'groupadd') or
                        contains(string(),'usermod') or
                        contains(string(),'icon-cache') or
                        contains(string(),'desktop-database') or
                        contains(string(),'compile-schemas') or
                        contains(string(),'query-loaders') or
                        contains(string(),'pam.d') or
                        contains(string(),'query-immodules')">
          <xsl:text>config</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>install</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable
         name="prec-string"
         select="string(preceding-sibling::screen[not(@role='nodump') and
                                                      ./userinput][1])"/>
<!--
    <xsl:message>
      <xsl:text>
==============================
List of preceding siblings for "</xsl:text>
      <xsl:value-of select="./userinput"/>
      <xsl:text>":
</xsl:text>
      <xsl:for-each select="preceding-sibling::screen[not(@role='nodump') and
                                                      ./userinput] |
                   preceding-sibling::para/command">
        <xsl:copy-of select=".//text()"/>
        <xsl:text>
===
</xsl:text>
      </xsl:for-each>
    </xsl:message>
-->
    <xsl:variable name="prec-nature">
      <xsl:choose>
        <xsl:when
             test="$prec-string='' or
                   (preceding-sibling::screen[not(@role='nodump') and
                                                      ./userinput] |
                    preceding-sibling::para/command[contains(text(),'check') or
                                                    contains(text(),'test')]
                   )[last()][self::command]">
          <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:when
           test="preceding-sibling::screen
                    [not(@role='nodump') and ./userinput][1][not(@role)]">
          <xsl:text>non-root</xsl:text>
        </xsl:when>
        <xsl:when test="contains($prec-string,'useradd') or
                        contains($prec-string,'groupadd') or
                        contains($prec-string,'usermod') or
                        contains($prec-string,'icon-cache') or
                        contains($prec-string,'desktop-database') or
                        contains($prec-string,'compile-schemas') or
                        contains($prec-string,'query-loaders') or
                        contains($prec-string,'pam.d') or
                        contains($prec-string,'query-immodules')">
          <xsl:text>config</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>install</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable
         name="follow-string"
         select="string(following-sibling::screen[not(@role='nodump') and
                                                      ./userinput][1])"/>

    <xsl:variable name="follow-nature">
      <xsl:choose>
        <xsl:when
             test="$follow-string='' or
                   (following-sibling::screen[not(@role='nodump') and
                                                      ./userinput] |
                    following-sibling::para/command[contains(text(),'check') or
                                                    contains(text(),'test')]
                   )[1][self::command]">
          <xsl:text>none</xsl:text>
        </xsl:when>
        <xsl:when
           test="following-sibling::screen
                    [not(@role='nodump') and ./userinput][1][not(@role)]">
          <xsl:text>non-root</xsl:text>
        </xsl:when>
        <xsl:when test="contains($follow-string,'useradd') or
                        contains($follow-string,'groupadd') or
                        contains($follow-string,'usermod') or
                        contains($follow-string,'icon-cache') or
                        contains($follow-string,'desktop-database') or
                        contains($follow-string,'compile-schemas') or
                        contains($follow-string,'query-loaders') or
                        contains($follow-string,'pam.d') or
                        contains($follow-string,'query-immodules')">
          <xsl:text>config</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>install</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$my-nature='non-root'">
        <xsl:if test="$prec-nature='install'">
          <xsl:call-template name="end-install"/>
          <xsl:call-template name="end-root"/>
        </xsl:if>
        <xsl:if test="$prec-nature='config'">
          <xsl:call-template name="end-root"/>
        </xsl:if>
        <xsl:apply-templates/>
        <xsl:text>
</xsl:text>
      </xsl:when>

      <xsl:when test="$my-nature='config'">
        <xsl:if test="$prec-nature='none' or $prec-nature='non-root'">
          <xsl:call-template name="begin-root"/>
        </xsl:if>
        <xsl:if test="$prec-nature='install'">
          <xsl:call-template name="end-install"/>
        </xsl:if>
        <xsl:apply-templates mode="root"/>
        <xsl:text>
</xsl:text>
        <xsl:if test="$follow-nature='none'">
          <xsl:call-template name="end-root"/>
        </xsl:if>
      </xsl:when>

      <xsl:when test="$my-nature='install'">
        <xsl:if test="$prec-nature='none' or $prec-nature='non-root'">
          <xsl:if test="contains($list-stat-norm,
                                 concat(' ',ancestor::sect1/@id,' '))">
            <xsl:call-template name="output-destdir"/>
          </xsl:if>
          <xsl:call-template name="begin-root"/>
          <xsl:call-template name="begin-install"/>
        </xsl:if>
        <xsl:if test="$prec-nature='config'">
          <xsl:if test="contains($list-stat-norm,
                                 concat(' ',ancestor::sect1/@id,' '))">
            <xsl:call-template name="end-root"/>
            <xsl:call-template name="output-destdir"/>
            <xsl:call-template name="begin-root"/>
          </xsl:if>
          <xsl:call-template name="begin-install"/>
        </xsl:if>
        <xsl:apply-templates mode="install"/>
        <xsl:text>
</xsl:text>
        <xsl:if test="$follow-nature='none'">
          <xsl:call-template name="end-install"/>
          <xsl:call-template name="end-root"/>
        </xsl:if>
      </xsl:when>

    </xsl:choose>
  </xsl:template>

  <xsl:template name="begin-root">
    <xsl:if test="$sudo='y'">
      <xsl:text>sudo -E sh &lt;&lt; ROOT_EOF
</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="begin-install">
    <xsl:if test="$wrap-install = 'y'">
      <xsl:text>if [ -r "$JH_PACK_INSTALL" ]; then
  source $JH_PACK_INSTALL
  export -f wrapInstall
  export -f packInstall
fi
wrapInstall '
</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="end-root">
    <xsl:if test="$sudo='y'">
      <xsl:text>ROOT_EOF
</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="end-install">
    <xsl:if test="$del-la-files = 'y'">
      <xsl:call-template name="output-root">
        <xsl:with-param name="out-string" select="$la-files-instr"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$wrap-install = 'y'">
      <xsl:text>'&#xA;packInstall&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="text()" mode="install">
    <xsl:call-template name="output-install">
      <xsl:with-param name="out-string" select="."/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="output-install">
    <xsl:param name="out-string" select="''"/>
    <xsl:choose>
      <xsl:when test="contains($out-string,string($APOS))
                      and $wrap-install = 'y'">
        <xsl:call-template name="output-root">
          <xsl:with-param
               name="out-string"
               select="substring-before($out-string,string($APOS))"/>
        </xsl:call-template>
        <xsl:text>'\''</xsl:text>
        <xsl:call-template name="output-install">
          <xsl:with-param name="out-string"
                          select="substring-after($out-string,string($APOS))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="output-root">
          <xsl:with-param name="out-string" select="$out-string"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
