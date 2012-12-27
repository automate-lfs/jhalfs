<?xml version="1.0" encoding="ISO-8859-1"?>

<!-- $Id: gen_config.xsl 21 2012-02-16 15:06:19Z labastie $ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output method="text"
              encoding='ISO-8859-1'/>

  <xsl:template match="/">
    <xsl:apply-templates select="//list"/>
    <xsl:text>comment ""

menu    "Default package for resolving MTA dependency"

choice
        prompt  "Mail server"
        config  MS_sendmail
                bool    "sendmail"
        config  MS_postfix
                bool    "postfix"
        config  MS_exim
                bool    "exim"
endchoice
config  MAIL_SERVER
        string
        default sendmail        if MS_sendmail
        default postfix         if MS_postfix
        default exim            if MS_exim

endmenu

choice
        prompt  "Dependency level"
        default DEPLVL_2

        config  DEPLVL_1
        bool    "Required dependencies only"

        config  DEPLVL_2
        bool    "Required and recommended dependencies"

        config  DEPLVL_3
        bool    "Required, recommended and optional dependencies"

endchoice
config  optDependency
        int
        default 1       if DEPLVL_1
        default 2       if DEPLVL_2
        default 3       if DEPLVL_3


config  SUDO
        bool "Build as User"
        default y
        help
                Select if sudo will be used (you build as a normal user)
                        otherwise sudo is not needed (you build as root)
</xsl:text>
  </xsl:template>

  <xsl:template match="list">
    <xsl:if
      test=".//*[self::package or self::module]
                    [(version and not(inst-version)) or
                      string(version) != string(inst-version)]">
      <xsl:text>config&#9;MENU_</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>
bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
default&#9;n

menu "</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
depends MENU_</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>

</xsl:text>
      <xsl:apply-templates select="sublist"/>
      <xsl:text>endmenu

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="sublist">
    <xsl:if
      test=".//*[self::package or self::module]
                    [(version and not(inst-version)) or
                      string(version) != string(inst-version)]">
      <xsl:text>&#9;config&#9;MENU_</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>
&#9;bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
&#9;default&#9;n

&#9;menu "</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
&#9;depends MENU_</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>

</xsl:text>
      <xsl:apply-templates select="package"/>
      <xsl:text>&#9;endmenu

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="package">
    <xsl:if
      test="(version and not(inst-version)) or
                      string(version) != string(inst-version)">
      <xsl:text>&#9;&#9;config&#9;CONFIG_</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>
&#9;&#9;bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="version"/>
      <xsl:if test="inst-version">
        <xsl:text> [Installed </xsl:text>
        <xsl:value-of select="inst-version"/>
        <xsl:text>]</xsl:text>
      </xsl:if>
      <xsl:text>"
&#9;&#9;default&#9;n

</xsl:text>
    </xsl:if>
    <xsl:if
      test="not(version) and ./module[not(inst-version) or
                      string(version) != string(inst-version)]">
      <xsl:text>&#9;&#9;config&#9;MENU_</xsl:text>
      <xsl:value-of select="translate(name,' ','_')"/>
      <xsl:text>
&#9;&#9;bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
&#9;&#9;default&#9;n

&#9;&#9;menu "</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
&#9;&#9;depends MENU_</xsl:text>
      <xsl:value-of select="translate(name,' ','_')"/>
      <xsl:text>

</xsl:text>
      <xsl:apply-templates select="module"/>
      <xsl:text>&#9;&#9;endmenu

</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="module">
    <xsl:if
      test="not(inst-version) or
            string(version) != string(inst-version)">
      <xsl:text>&#9;&#9;&#9;config&#9;CONFIG_</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>
&#9;&#9;&#9;bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="version"/>
      <xsl:if test="inst-version">
        <xsl:text> [Installed </xsl:text>
        <xsl:value-of select="inst-version"/>
        <xsl:text>]</xsl:text>
      </xsl:if>
      <xsl:text>"
&#9;&#9;&#9;default&#9;n

</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
