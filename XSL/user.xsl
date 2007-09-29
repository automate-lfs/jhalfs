<?xml version="1.0"?>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- Base system build customization templates.
     This is a collection of free non-book dependant templates that can be
     used to customize the build scripts content, how each of the base system
     packages is build, or to insert scripts into the system build flow.
     Don't edit the templates directly here, this file is only for reference
     and you changes will be lost if updating the jhalfs code.
     Select what of them you need and place it into you customization layout.-->


<!-- ########## TEMPLATES TO INSERT CODE AND TO ADD EXTRA SCRIPTS ########## -->

    <!-- Hock to insert extra code after the logs date timestamp dump and
         before the envars settings -->
  <xsl:template name="user_header">
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>


    <!-- Hock to add envars or extra commands after unpacking the tarball
         but before cd into the sources dir -->
  <xsl:template name="user_pre_commands">
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>


    <!-- Hock for commands additions after the book commands but before
         removing sources dir -->
  <xsl:template name="user_footer">
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>


    <!-- Hock for inserting scripts before a selected one -->
  <xsl:template name="insert_script_before">
      <!-- Inherited values -->
    <xsl:param name="reference" select="foo"/>
    <xsl:param name="order" select="foo"/>
      <!-- Added a string to be sure that this scripts are run
           before the selected one -->
    <xsl:variable name="insert_order" select="concat($order,'_0')"/>
      <!-- Add an xsl:if block for each referenced sect1 you want
           to insert scripts before -->
    <xsl:if test="$reference = 'ID_of_selected_sect1'">
        <!-- Add an exsl:document block for each script to be inserted
             at this point of the build. This one is only a dummy example. -->
      <exsl:document href="{$insert_order}01-dummy" method="text">
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
    </xsl:if>
  </xsl:template>


    <!-- Hock for inserting scripts after a selected one -->
  <xsl:template name="insert_script_after">
      <!-- Inherited values -->
    <xsl:param name="reference" select="foo"/>
    <xsl:param name="order" select="foo"/>
      <!-- Added a string to be sure that this scripts are run
           after the selected one -->
    <xsl:variable name="insert_order" select="concat($order,'_z')"/>
      <!-- Add an xsl:if block for each referenced sect1 you want
           to insert scripts after -->
    <xsl:if test="$reference = 'ID_of_selected_sect1'">
        <!-- Add an exsl:document block for each script to be inserted
             at this point of the build. This one is only a dummy example. -->
      <exsl:document href="{$insert_order}01-dummy" method="text">
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
    </xsl:if>
  </xsl:template>


<!-- ######################################################################## -->

<!-- ########## TEMPLATES TO SELECT THE MODE USED ON SCREEN BLOCKS ########## -->

<!-- NOTE: Testsuites commands are handled on the master stylesheets -->


    <!-- userinput @remap='pre' -->
  <xsl:template match="userinput[@remap='pre']">
    <xsl:apply-templates select="." mode="pre"/>
  </xsl:template>


    <!-- userinput @remap='configure' -->
  <xsl:template match="userinput[@remap='configure']">
    <xsl:apply-templates select="." mode="configure"/>
  </xsl:template>


    <!-- userinput @remap='make' -->
  <xsl:template match="userinput[@remap='make']">
    <xsl:apply-templates select="." mode="make"/>
  </xsl:template>


    <!-- userinput @remap='install' -->
  <xsl:template match="userinput[@remap='install']">
    <xsl:apply-templates select="." mode="install"/>
  </xsl:template>


    <!-- userinput @remap='adjust' -->
  <xsl:template match="userinput[@remap='adjust']">
    <xsl:apply-templates select="." mode="adjust"/>
  </xsl:template>


    <!-- userinput @remap='locale-full' -->
  <xsl:template match="userinput[@remap='locale-full']">
    <xsl:apply-templates select="." mode="locale-full"/>
  </xsl:template>



    <!-- userinput without @remap -->
  <xsl:template match="userinput">
    <xsl:choose>
      <xsl:when test="ancestor::sect2[@role='configuration']">
        <xsl:apply-templates select="." mode="configuration_section"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="no_remap"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


<!-- ######################################################################## -->

<!-- ############## STOCK MODE TEMPLATES USED ON SCREEN BLOCKS ############## -->

<!-- NOTE: You can used this modes or create you own ones -->


    <!-- mode pre  -->
  <xsl:template match="userinput" mode="pre">
    <xsl:apply-templates select="." mode="default"/>
  </xsl:template>


    <!-- mode configure  -->
  <xsl:template match="userinput" mode="configure">
    <xsl:apply-templates select="." mode="default"/>
  </xsl:template>


    <!-- mode make  -->
  <xsl:template match="userinput" mode="make">
    <xsl:apply-templates select="." mode="default"/>
  </xsl:template>


    <!-- mode install  -->
  <xsl:template match="userinput" mode="install">
    <xsl:apply-templates select="." mode="default"/>
  </xsl:template>


    <!-- mode adjust  -->
  <xsl:template match="userinput" mode="adjust">
    <xsl:apply-templates select="." mode="default"/>
  </xsl:template>


    <!-- mode locale-full  -->
  <xsl:template match="userinput" mode="locale-full">
    <xsl:apply-templates select="." mode="default"/>
  </xsl:template>


    <!-- mode configuration_section  -->
  <xsl:template match="userinput" mode="configuration_section">
    <xsl:apply-templates select="." mode="default"/>
  </xsl:template>


    <!-- mode no_remap  -->
  <xsl:template match="userinput" mode="no_remap">
    <xsl:apply-templates select="." mode="default"/>
  </xsl:template>


    <!-- mode default  -->
  <xsl:template match="userinput" mode="default">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
