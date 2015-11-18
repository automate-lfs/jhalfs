#!/bin/bash

# $Id: gen-special.sh 21 2012-02-16 15:06:19Z labastie $

#-------------------------------------------------------------------------
# generates an xsl stylesheet containing a template for special
# cases in the book:
#  - If the version does not begin with a number, it is impossible to know
#    where the package name ends and where the version begins. We therefore
#    use the ENTITY at the beginning of the validated full-xml.
#  - If a package is part of a group of xorg packages (proto, fonts, etc)
#    there is no easy way to extract it from the xml. We use the ENTITY at
#    the top of each file x7*.xml
#  - Some non-versioned packages are needed as dependencies of others: we
#    attribute version 1.0.0 to them. It is just used to know if the package
#    is installed, by checking inst-version.
#  - If a package is versioned but the version is not mentioned in the book
#    (currently only udev), we retrieve the version by other means
#-------------------------------------------------------------------------
# Arguments:
# $1 contains the name of the validated xml book
# $2 contains the name of the ouput xsl file
# $3 contains the name of the book sources directory
#-------------------------------------------------------------------------

BLFS_XML=$1
if ! test -f ${BLFS_XML}; then
  echo File \`${BLFS_XML}\' does not exist
  exit 1
fi
SPECIAL_FILE=$2
if test -z "${SPECIAL_FILE}"; then SPECIAL_FILE=specialCases.xsl;fi
BLFS_DIR=$3
if test -z "${BLFS_DIR}"; then BLFS_DIR=$(cd $(dirname ${BLFS_XML})/.. ; pwd);fi

# Packages whose version does not begin with a number
EXCEPTIONS=$(grep 'ENTITY.*version[ ]*"[^0-9"&.].*[0-9]' $BLFS_XML |
             sed 's@^[^"]*"\([^"]*\)".*@\1@')

# Non-versioned packages:
NV_LIST="cacerts xorg-env kde-pre-install-config kf5-intro lxqt-pre-install \
ojdk-conf tex-path"

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
    <xsl:when test="contains(@id,'udev')">
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
<!-- Although versioned, this page is not a package. But
     the sect2 with id "xorg-env" is referred to at several
     places in the book. We have added it to the list of non
     versioned packages. -->
    <xsl:when test="@id='xorg7'">
      <xsl:apply-templates select="child::sect2" mode="special"/>
    </xsl:when>
EOF

# Non-versionned packages. Add to NV_LIST if you need more.
for nv_id in $NV_LIST; do
  cat >>$SPECIAL_FILE << EOF
    <xsl:when test="@id='$nv_id'">
      <xsl:text>      </xsl:text>
      <package><xsl:text>&#xA;        </xsl:text>
        <xsl:element name="name">$nv_id</xsl:element>
        <xsl:text>&#xA;        </xsl:text>
        <xsl:element name="version">1.0.0</xsl:element>
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

# Taking packages inside x7proto etc, as versionned modules.
# We also write a dependency expansion when a dep is of the form
# xorg7-something. Since that is another template, we need
# a temporary file, which we shall concatenate at the end
cat >tmpfile << EOF
  <xsl:template name="expand-deps">
    <xsl:param name="section"/>
    <xsl:param name="status"/>
    <xsl:choose>
EOF
for file in $(ls ${BLFS_DIR}/x/installing/x7* | grep -v x7driver); do
  id=$(grep xreflabel $file | sed 's@.*id="\([^"]*\).*@\1@')
  cat >>$SPECIAL_FILE << EOF
    <xsl:when test="@id='$id'">
      <xsl:text>      </xsl:text>
      <package><xsl:text>&#xA;        </xsl:text>
        <xsl:element name="name">$id</xsl:element>
        <xsl:text>&#xA;        </xsl:text>
EOF
  cat >> tmpfile << EOF
      <xsl:when test="\$section='$id'">
EOF
# We extract the list of packages for an xorg page from
# the version part of the .xml file. Seems that
# the order is not always the same as in the "cat" command.
# So we have to read that command too, since it may be assumed
# that the preceding package is a dependency of the following,
# except the first.
  list_cat="$(sed -n '/>cat/,/EOF</p' $file | grep -v 'cat\|EOF' |
                 sed 's/^[^ ]*\ *\([^&]*\).*/\1/' | sed 's/-$//')"

# Rationale for the sed below: the following for breaks words at spaces (unless
# we tweak IFS). So replace spaces with commas in lines so that only newlines
# are separators.
  for pack in \
      $(grep 'ENTITY.*version' $file | sed 's/[ ]\+/,/g'); do
    packname=$(echo $pack | sed s'@.*ENTITY,\(.*\)-version.*@\1@')
    packversion=$(echo $pack | sed 's@[^"]*"\([^"]*\).*@\1@')
    precpack=NONE
    for i in $list_cat; do
      if [ "$i" = "$packname" ]; then break; fi
      precpack=$i
    done

    cat >>$SPECIAL_FILE << EOF
        <module><xsl:text>&#xA;          </xsl:text>
          <xsl:element name="name">$packname</xsl:element>
          <xsl:element name="version">$packversion</xsl:element>
          <xsl:if test="document(\$installed-packages)//package[name='$packname']">
            <xsl:element name="inst-version">
              <xsl:value-of
                select="document(\$installed-packages
                                )//package[name='$packname']/version"/>
            </xsl:element>
          </xsl:if>
<!-- Dependencies -->
EOF
    if test $precpack != NONE; then
      cat >>$SPECIAL_FILE << EOF
          <xsl:element name="dependency">
            <xsl:attribute name="status">required</xsl:attribute>
            <xsl:attribute name="name">$precpack</xsl:attribute>
            <xsl:attribute name="type">ref</xsl:attribute>
          </xsl:element>
EOF
    else
      cat >>$SPECIAL_FILE << EOF
          <xsl:apply-templates select=".//para[@role='required' or
                                               @role='recommended' or
                                               @role='optional']"
                               mode="dependency"/>
EOF
    fi
    cat >>$SPECIAL_FILE << EOF
<!-- End dependencies -->
        </module>
EOF
    cat >> tmpfile << EOF
        <xsl:element name="dependency">
          <xsl:attribute name="status">
            <xsl:value-of select="\$status"/>
          </xsl:attribute>
          <xsl:attribute name="name">$packname</xsl:attribute>
          <xsl:attribute name="type">ref</xsl:attribute>
        </xsl:element>
EOF
  done
  cat >>$SPECIAL_FILE << EOF
     </package>
   </xsl:when>
EOF
  cat >> tmpfile << EOF
      </xsl:when>
EOF
done

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
EOF
cat $SPECIAL_FILE tmpfile > tmpfile1
mv tmpfile1 $SPECIAL_FILE
rm tmpfile
cat >> $SPECIAL_FILE << EOF
    <xsl:otherwise>
      <xsl:message>
        <xsl:text>You should not be seeing this</xsl:text>
      </xsl:message>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
</xsl:stylesheet>
EOF
