<?xml version="1.0" encoding="ISO-8859-1"?>

<!-- $Id$ -->

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
        bool    "Required plus recommended dependencies"

        config  DEPLVL_3
        bool    "Req/rec  plus optional dependencies of requested package(s)"

        config  DEPLVL_4
        bool    "All non external dependencies"

endchoice
config  optDependency
        int
        default 1       if DEPLVL_1
        default 2       if DEPLVL_2
        default 3       if DEPLVL_3
        default 4       if DEPLVL_4

config  LANGUAGE
        string "LANG variable in the form ll_CC.charmap[@modifiers]"
        default "en_US.UTF-8"
        help
            Because of the book layout, the 3 fields, ll, CC and charmap are
            mandatory. The @modfier is honoured if present.

config  SUDO
        bool "Build as User"
        default y
        help
                Select if sudo will be used (you build as a normal user)
                        otherwise sudo is not needed (you build as root)


config  WRAP_INSTALL
        bool "Use `porg style' package management"
        default n
        help
                Select if you want the installation commands to be wrapped
		between "wrapInstall '" and "' ; packInstall" functions,
		where wrapInstall is used to set up a LD_PRELOAD library (for
		example using porg), and packInstall makes the package tarball

config	DEL_LA_FILES
	bool "Remove libtool .la files after package installation"
	default y
	help
		This option should be active on any system mixing libtool
		and meson build systems. ImageMagick .la files are preserved.

config	STATS
	bool "Generate statistics for the requested package(s)"
	default n
	help
		If you want timing and memory footprint statistics to be
                generated for the packages you build (not their dependencies),
		set this option to y.
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
      <xsl:value-of select="translate(name,' ()','___')"/>
      <xsl:text>
&#9;&#9;bool&#9;"</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
&#9;&#9;default&#9;n

&#9;&#9;menu "</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>"
&#9;&#9;depends MENU_</xsl:text>
      <xsl:value-of select="translate(name,' ()','___')"/>
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
&#9;&#9;&#9;default&#9;</xsl:text>
      <xsl:choose>
        <xsl:when test="contains(../name,'xorg')">
          <xsl:text>y

</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>n

</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
