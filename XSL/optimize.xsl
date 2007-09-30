<?xml version="1.0"?>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

<!-- ####################### PARAMETERS ################################### -->

          <!-- ###### MAKEFLAGS ###### -->

    <!-- Should MAKEFLAGS be set? y = yes, n = no -->
  <xsl:param name="set_makeflags">y</xsl:param>


    <!-- Jobs control level. Left it empty for no jobs control -->
  <xsl:param name="jobs">-j3</xsl:param>


    <!-- Jobs control black-listed packages. One in each line.
         NOTE: This and other similar parameters uses the PKG_PHASE value -->
  <xsl:param name="no_jobs">
    keep_this_line
    autoconf
    dejagnu
    gettext
    groff
    man-db
    keep_this_line
  </xsl:param>


    <!-- Additional make flags. -->
  <xsl:param name="makeflags"></xsl:param>


    <!-- Additional make flags black-listed packages. One in each line. -->
  <xsl:param name="no_mkflags">
    keep_this_line
    keep_this_line
  </xsl:param>


          <!-- ############################ -->

          <!-- ###### COMPILER FLAGS ###### -->

    <!-- Should compiler envars be set? y = yes, n = no -->
  <xsl:param name="set_buildflags">y</xsl:param>


    <!-- Compiler optimizations black-listed packages. One in each line. -->
  <xsl:param name="no_buildflags">
    keep_this_line
    binutils
    binutils-pass1
    binutils-pass2
    gcc
    gcc-pass1
    gcc-pass2
    glibc
    grub
    keep_this_line
  </xsl:param>


  <!-- Default envars setting. Left empty to not set a variable. -->

    <!-- Default CFLAGS -->
  <xsl:param name="cflags">-O3 -pipe</xsl:param>


    <!-- Default CXXFLAGS -->
  <xsl:param name="cxxflags">$CFLAGS</xsl:param>


    <!-- Default OTHER_CFLAGS -->
  <xsl:param name="other_cflags">$CFLAGS</xsl:param>


    <!-- Default OTHER_CXXFLAGS -->
  <xsl:param name="other_cxxflags">$CXXFLAGS</xsl:param>


    <!-- Default LDFLAGS -->
  <xsl:param name="ldflags"></xsl:param>


    <!-- Default OTHER_LDFLAGS -->
  <xsl:param name="other_ldflags"></xsl:param>

                         <!-- -->

  <!-- By-package additional settings. A pair "package value" on each line.
       The values set here will be added to the ones set above -->

    <!-- Extra CFLAGS -->
  <xsl:param name="extra_cflags">
    zlib -fPIC
  </xsl:param>


    <!-- Extra CXXFLAGS -->
  <xsl:param name="extra_cxxflags">
  </xsl:param>


    <!-- Extra OTHER_CFLAGS -->
  <xsl:param name="extra_other_cflags">
  </xsl:param>


    <!-- Extra OTHER_CXXFLAGS -->
  <xsl:param name="extra_other_cxxflags">
  </xsl:param>


    <!-- Extra LDFLAGS -->
  <xsl:param name="extra_ldflags">
  </xsl:param>


    <!-- Extra OTHER_LDFLAGS -->
  <xsl:param name="extra_other_ldflags">
  </xsl:param>

                         <!-- -->

  <!-- By-package settings. A pair "package value" on each line.
       The values set here will override the ones set above -->

    <!-- Extra CFLAGS -->
  <xsl:param name="override_cflags">
  </xsl:param>


    <!-- Extra CXXFLAGS -->
  <xsl:param name="override_cxxflags">
  </xsl:param>


    <!-- Extra OTHER_CFLAGS -->
  <xsl:param name="override_other_cflags">
  </xsl:param>


    <!-- Extra OTHER_CXXFLAGS -->
  <xsl:param name="override_other_cxxflags">
  </xsl:param>


    <!-- Extra LDFLAGS -->
  <xsl:param name="override_ldflags">
  </xsl:param>


    <!-- Extra OTHER_LDFLAGS -->
  <xsl:param name="override_other_ldflags">
  </xsl:param>


<!-- ######################################################################## -->

<!-- ########################### NAMED TEMPLATES ########################### -->

     <!-- Master optimizations template -->
  <xsl:template name="optimize">
    <xsl:param name="package" select="foo"/>
    <xsl:text>&#xA;&#xA;</xsl:text>
    <xsl:if test="$set_makeflags = 'y'">
      <xsl:call-template name="makeflags">
        <xsl:with-param name="package" select="$package"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$set_buildflags = 'y' and
            not(contains(normalize-space($no_buildflags),concat(' ',$package,' ')))">
      <xsl:call-template name="buildflags">
        <xsl:with-param name="package" select="$package"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>


    <!-- MAKEFLAGS template -->
  <xsl:template name="makeflags">
    <xsl:param name="package" select="foo"/>
      <!-- Test if jobs control must be set -->
    <xsl:variable name="set_jobs">
      <xsl:if test="$jobs != '' and
              not(contains(normalize-space($no_jobs),concat(' ',$package,' ')))">1</xsl:if>
    </xsl:variable>
      <!-- Test if additional make flags must be set -->
    <xsl:variable name="add_mkflags">
      <xsl:if test="$makeflags != '' and
              not(contains(normalize-space($no_mkflags),concat(' ',$package,' ')))">1</xsl:if>
    </xsl:variable>
      <!-- Write the envar -->
    <xsl:if test="$set_jobs = '1' or $add_mkflags = '1'">
      <xsl:text>MAKEFLAGS="</xsl:text>
        <!-- Write jobs control value -->
      <xsl:if test="$set_jobs = '1'">
        <xsl:value-of select="$jobs"/>
      </xsl:if>
        <!-- If both values will be written, be sure that are space separated -->
      <xsl:if test="$set_jobs = '1' and $add_mkflags = '1'">
        <xsl:text> </xsl:text>
      </xsl:if>
        <!-- Write additional make flags value -->
      <xsl:if test="$add_mkflags = '1'">
        <xsl:value-of select="$makeflags"/>
      </xsl:if>
      <xsl:text>"&#xA;</xsl:text>
    </xsl:if>
  </xsl:template>


    <!-- Master compiler flags template -->
  <xsl:template name="buildflags">
    <xsl:param name="package" select="foo"/>
    <xsl:if test="$cflags != ''">
      <xsl:call-template name="cflags">
        <xsl:with-param name="package" select="$package"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$cxxflags != ''">
      <xsl:call-template name="cxxflags">
        <xsl:with-param name="package" select="$package"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$other_cflags != ''">
      <xsl:call-template name="other_cflags">
        <xsl:with-param name="package" select="$package"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$other_cxxflags != ''">
      <xsl:call-template name="other_cxxflags">
        <xsl:with-param name="package" select="$package"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$ldflags != ''">
      <xsl:call-template name="ldflags">
        <xsl:with-param name="package" select="$package"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$other_ldflags != ''">
      <xsl:call-template name="other_ldflags">
        <xsl:with-param name="package" select="$package"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>


    <!-- CFLAGS template -->
  <xsl:template name="cflags">
    <xsl:param name="package" select="foo"/>
      <!-- Find the override value, if any -->
    <xsl:variable name="override">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($override_cflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Find the extra settings, if any -->
    <xsl:variable name="extra">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($extra_cflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Writte the envar -->
    <xsl:text>CFLAGS="</xsl:text>
    <xsl:choose>
      <xsl:when test="$override != ''">
        <xsl:value-of select="$override"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$cflags"/>
        <xsl:if test="$extra != ''">
          <xsl:value-of select="concat(' ',$extra)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>"&#xA;</xsl:text>
  </xsl:template>


    <!-- CXXFLAGS template -->
  <xsl:template name="cxxflags">
    <xsl:param name="package" select="foo"/>
      <!-- Find the override value, if any -->
    <xsl:variable name="override">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($override_cxxflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Find the extra settings, if any -->
    <xsl:variable name="extra">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($extra_cxxflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Writte the envar -->
    <xsl:text>CXXFLAGS="</xsl:text>
    <xsl:choose>
      <xsl:when test="$override != ''">
        <xsl:value-of select="$override"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$cxxflags"/>
        <xsl:if test="$extra != ''">
          <xsl:value-of select="concat(' ',$extra)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>"&#xA;</xsl:text>
  </xsl:template>


    <!-- OTHER_CFLAGS template -->
  <xsl:template name="other_cflags">
    <xsl:param name="package" select="foo"/>
      <!-- Find the override value, if any -->
    <xsl:variable name="override">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($override_other_cflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Find the extra settings, if any -->
    <xsl:variable name="extra">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($extra_other_cflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Writte the envar -->
    <xsl:text>OTHER_CFLAGS="</xsl:text>
    <xsl:choose>
      <xsl:when test="$override != ''">
        <xsl:value-of select="$override"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$other_cflags"/>
        <xsl:if test="$extra != ''">
          <xsl:value-of select="concat(' ',$extra)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>"&#xA;</xsl:text>
  </xsl:template>


    <!-- OTHER_CXXFLAGS template -->
  <xsl:template name="other_cxxflags">
    <xsl:param name="package" select="foo"/>
      <!-- Find the override value, if any -->
    <xsl:variable name="override">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($override_other_cxxflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Find the extra settings, if any -->
    <xsl:variable name="extra">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($extra_other_cxxflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Writte the envar -->
    <xsl:text>OTHER_CXXFLAGS="</xsl:text>
    <xsl:choose>
      <xsl:when test="$override != ''">
        <xsl:value-of select="$override"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$other_cxxflags"/>
        <xsl:if test="$extra != ''">
          <xsl:value-of select="concat(' ',$extra)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>"&#xA;</xsl:text>
  </xsl:template>


    <!-- LDFLAGS template -->
  <xsl:template name="ldflags">
    <xsl:param name="package" select="foo"/>
      <!-- Find the override value, if any -->
    <xsl:variable name="override">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($override_ldflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Find the extra settings, if any -->
    <xsl:variable name="extra">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($extra_ldflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Writte the envar -->
    <xsl:text>LDFLAGS="</xsl:text>
    <xsl:choose>
      <xsl:when test="$override != ''">
        <xsl:value-of select="$override"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$ldflags"/>
        <xsl:if test="$extra != ''">
          <xsl:value-of select="concat(' ',$extra)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>"&#xA;</xsl:text>
  </xsl:template>


    <!-- OTHER_LDFLAGS template -->
  <xsl:template name="other_ldflags">
    <xsl:param name="package" select="foo"/>
      <!-- Find the override value, if any -->
    <xsl:variable name="override">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($override_other_ldflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Find the extra settings, if any -->
    <xsl:variable name="extra">
      <xsl:call-template name="lookup.key">
        <xsl:with-param name="key" select="$package"/>
        <xsl:with-param name="table" select="normalize-space($extra_other_ldflags)"/>
      </xsl:call-template>
    </xsl:variable>
      <!-- Writte the envar -->
    <xsl:text>OTHER_LDFLAGS="</xsl:text>
    <xsl:choose>
      <xsl:when test="$override != ''">
        <xsl:value-of select="$override"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$other_ldflags"/>
        <xsl:if test="$extra != ''">
          <xsl:value-of select="concat(' ',$extra)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>"&#xA;</xsl:text>
  </xsl:template>


    <!-- Parses a table-like param finding a pair key-value.
         Copied from DocBook-XSL -->
  <xsl:template name="lookup.key">
    <xsl:param name="key" select="''"/>
    <xsl:param name="table" select="''"/>
    <xsl:if test="contains($table, ' ')">
      <xsl:choose>
        <xsl:when test="substring-before($table, ' ') = $key">
          <xsl:variable name="rest" select="substring-after($table, ' ')"/>
          <xsl:choose>
            <xsl:when test="contains($rest, ' ')">
              <xsl:value-of select="substring-before($rest, ' ')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$rest"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="lookup.key">
            <xsl:with-param name="key" select="$key"/>
            <xsl:with-param name="table" select="substring-after(substring-after($table,' '), ' ')"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
