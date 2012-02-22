#!/bin/bash

# $Id: gen-special.sh 21 2012-02-16 15:06:19Z labastie $

BLFS_XML=$1
if ! test -f ${BLFS_XML}; then
  echo ${BLFS_XML} does not exist
  exit 1
fi
SPECIAL_FILE=$2
if test -z "${SPECIAL_FILE}"; then SPECIAL_FILE=specialCases.xsl;fi
# Packages whose version does not begin with a number
EXCEPTIONS=$(grep 'ENTITY.*version[ ]*"[^0-9"&.].*[0-9]' $BLFS_XML |
             sed 's@^[^"]*"\([^"]*\)".*@\1@')
# Version for X Window packages without a version in the book
XVERSION=$(grep 'ENTITY xorg7-release' $BLFS_XML |
           sed 's@^[^"]*"\([^"]*\)".*@\1@')
# The case of udev
# Set PATH to be sure to find udevadm
SAVPATH=$PATH
PATH=/bin:/sbin:/usr/bin:/usr/sbin
UDEVVERSION=$(udevadm --version)

cat >$SPECIAL_FILE << EOF
<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

<xsl:template match='*' mode="special">
  <xsl:choose>
    <xsl:when test="@id='udev'">
      <xsl:text>      </xsl:text>
      <package><xsl:text>&#xA;        </xsl:text>
        <xsl:element name="name"><xsl:value-of select="@id"/></xsl:element>
        <xsl:text>&#xA;        </xsl:text>
        <xsl:element name="version">$UDEVVERSION</xsl:element>
        <xsl:if
            test="document(\$installed-packages)//package[name=current()/@id]">
          <xsl:text>&#xA;        </xsl:text>
          <xsl:element name="inst-version">
            <xsl:value-of
              select="document(\$installed-packages
                              )//package[name=current()/@id]/version"/>
          </xsl:element>
        </xsl:if>
<!-- Dependencies -->
        <xsl:apply-templates select=".//para[@role='required' or
                                             @role='recommended' or
                                             @role='optional']"
                             mode="dependency"/>
<!-- End dependencies -->
        <xsl:text>&#xA;      </xsl:text>
      </package><xsl:text>&#xA;</xsl:text>
    </xsl:when>
    <xsl:when test="@id='xorg7'"/>
    <xsl:when test="../@id='x-window-system' and
                    not(contains(translate(@xreflabel,
                                           '123456789',
                                           '000000000'),
                                '-0'))">
      <xsl:text>      </xsl:text>
      <package><xsl:text>&#xA;        </xsl:text>
        <xsl:element name="name"><xsl:value-of select="@id"/></xsl:element>
        <xsl:text>&#xA;        </xsl:text>
        <xsl:element name="version">$XVERSION</xsl:element>
        <xsl:if
            test="document(\$installed-packages)//package[name=current()/@id]">
          <xsl:text>&#xA;        </xsl:text>
          <xsl:element name="inst-version">
            <xsl:value-of
              select="document(\$installed-packages
                              )//package[name=current()/@id]/version"/>
          </xsl:element>
        </xsl:if>
<!-- Dependencies -->
        <xsl:apply-templates select=".//para[@role='required' or
                                             @role='recommended' or
                                             @role='optional']"
                             mode="dependency"/>
<!-- End dependencies -->
        <xsl:text>&#xA;      </xsl:text>
      </package><xsl:text>&#xA;</xsl:text>
    </xsl:when>
EOF

for ver_ent in $EXCEPTIONS; do
  id=$(grep 'xreflabel=".*'$ver_ent $BLFS_XML | sed 's@.*id="\([^"]*\)".*@\1@')
  [[ -z $id ]] && continue
  cat >>$SPECIAL_FILE << EOF
    <xsl:when test="@id='$id'">
      <xsl:text>      </xsl:text>
      <package><xsl:text>&#xA;        </xsl:text>
        <xsl:element name="name">$id</xsl:element>
        <xsl:text>&#xA;        </xsl:text>
        <xsl:element name="version">$ver_ent</xsl:element>
        <xsl:if
            test="document(\$installed-packages)//package[name=current()/@id]">
          <xsl:text>&#xA;        </xsl:text>
          <xsl:element name="inst-version">
            <xsl:value-of
              select="document(\$installed-packages
                              )//package[name=current()/@id]/version"/>
          </xsl:element>
        </xsl:if>
<!-- Dependencies -->
        <xsl:apply-templates select=".//para[@role='required' or
                                             @role='recommended' or
                                             @role='optional']"
                             mode="dependency"/>
<!-- End dependencies -->
        <xsl:text>&#xA;      </xsl:text>
      </package><xsl:text>&#xA;</xsl:text>
    </xsl:when>
EOF
done

cat >>$SPECIAL_FILE << EOF
    <xsl:otherwise>
        <xsl:apply-templates
           select="self::node()[contains(translate(@xreflabel,
                                                  '123456789',
                                                  '000000000'),
                                         '-0')
                               ]"
           mode="normal"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
EOF
