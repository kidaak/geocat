<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:geonet="http://www.fao.org/geonetwork">

  <xsl:include href="../schema-xsl-edit-loader.xsl"/>
  <xsl:include href="common-noedit.xsl"/>
  <xsl:variable name="langId">
    <xsl:call-template name="getLangId">
      <xsl:with-param name="langGui" select="/root/gui/language"/>
      <xsl:with-param name="md" select="$metadata"/>
    </xsl:call-template>
  </xsl:variable>
</xsl:stylesheet>
