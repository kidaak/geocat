<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:gn="http://www.fao.org/geonetwork"
  xmlns:saxon="http://saxon.sf.net/" extension-element-prefixes="saxon"
  xmlns:gmd="http://www.isotc211.org/2005/gmd"
  xmlns:srv="http://www.isotc211.org/2005/srv"
  >
  <!-- Global XSL variables about the metadata record. This should be included for
  service dealing with one metadata record (eg. viewing, editing). -->
  
  <xsl:include href="base-variables.xsl"/>
  
  <!-- The metadata record in whatever profile -->
  <xsl:variable name="metadata" select="/root/*[name(.)!='gui' and name(.) != 'request']"/>
  
  
  <!-- Get the last gn:info element in case something added it twice to the record 
  which may break the editor. In that case, XML view can help fixing the record. -->
  <xsl:variable name="metadataInfo" select="$metadata/gn:info[position() = last()]"/>
  
  <!-- The metadata schema -->
  <xsl:variable name="schema" select="$metadataInfo/schema"/>
  <xsl:variable name="metadataUuid" select="$metadataInfo/uuid"/>
  <xsl:variable name="metadataId" select="$metadataInfo/id"/>
  <xsl:variable name="isTemplate" select="$metadataInfo/isTemplate"/>

  <xsl:variable name="isService">
    <saxon:call-template name="{concat('get-', $schema, '-is-service')}"/>
  </xsl:variable>

  <!--GEOCAT-->
  <xsl:variable name="currTab" select="/root/gui/currTab" />
  <xsl:variable name="defaultMetadataLanguage" select="'ger'" />
  <xsl:variable name="defaultMetadataOtherLanguages">
    <lang id="DE" code="ger"/>
    <lang id="FR" code="fre"/>
    <lang id="IT" code="ita"/>
    <lang id="EN" code="eng"/>
    <lang id="RM" code="roh"/>
  </xsl:variable>
  <xsl:variable name="defaultMetadataOtherLanguagesJson" select="'{
    &quot;ger&quot;:&quot;#DE&quot;,
    &quot;fre&quot;:&quot;#FR&quot;,
    &quot;ita&quot;:&quot;#IT&quot;,
    &quot;eng&quot;:&quot;#EN&quot;,
    &quot;roh&quot;:&quot;#RM&quot;
    }'" />

  <xsl:variable name="metadataLanguage">
    <xsl:choose>
      <xsl:when test="$isTemplate = 's'">
        <xsl:value-of select="$defaultMetadataLanguage" />
      </xsl:when>
      <xsl:otherwise>
        <saxon:call-template name="{concat('get-', $schema, '-language')}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="metadataOtherLanguages">
    <xsl:choose>
      <xsl:when test="$isTemplate = 's'">
        <xsl:copy-of select="$defaultMetadataOtherLanguages" />
      </xsl:when>
      <xsl:otherwise>
        <saxon:call-template name="{concat('get-', $schema, '-other-languages')}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="metadataOtherLanguagesAsJson">
    <xsl:choose>
      <xsl:when test="$isTemplate = 's'">
        <xsl:value-of select="$defaultMetadataOtherLanguagesJson" />
      </xsl:when>
      <xsl:otherwise>
        <saxon:call-template name="{concat('get-', $schema, '-other-languages-as-json')}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <!--END GEOCAT-->
  <xsl:variable name="metadataIsMultilingual" select="count($metadataOtherLanguages/*) > 0"/>
  
  <!-- The list of thesaurus -->
  <xsl:variable name="listOfThesaurus" select="/root/gui/thesaurus/thesauri"/>
  
  
  <!-- The labels, codelists and profiles specific strings -->
  <!-- TODO : label inheritance between profiles - maybe in Java ? -->
  <xsl:variable name="schemaInfo" select="/root/gui/schemas/*[name(.)=$schema]"/>
  <xsl:variable name="labels" select="$schemaInfo/labels"/>
  <xsl:variable name="codelists" select="$schemaInfo/codelists"/>
  <xsl:variable name="strings" select="$schemaInfo/strings"/>

  <xsl:variable name="iso19139schema" select="/root/gui/schemas/iso19139"/>
  <xsl:variable name="iso19139labels" select="$iso19139schema/labels"/>
  <xsl:variable name="iso19139codelists" select="$iso19139schema/codelists"/>
  <xsl:variable name="iso19139strings" select="$iso19139schema/strings"/>
  
  <xsl:variable name="isEditing" select="$service = 'md.edit' or $service = 'md.element.add'"/>
  
  <!-- Display attributes in editor -->
  <xsl:variable name="isDisplayingAttributes" select="/root/request/displayAttributes = 'true'"/>
  <xsl:variable name="isDisplayingTooltips" select="/root/request/displayTooltips = 'true'"/>
  
  <xsl:variable name="withInlineEditing" select="false()"/>
  
  <xsl:variable name="withXPath" select="false()"/>
  
  <xsl:variable name="editorConfig">
    <saxon:call-template name="{concat('get-', $schema, '-configuration')}"/>
  </xsl:variable>
  
  <xsl:variable name="iso19139EditorConfig">
    <!-- TODO only load for ISO profiles -->
    <xsl:call-template name="get-iso19139-configuration"/>
  </xsl:variable>
  
  
  <xsl:variable name="tab" select="if (/root/gui/currTab) then /root/gui/currTab else 
    $editorConfig/editor/views/view/tab[@default]/@id"/>
  
  <xsl:variable name="viewConfig" select="$editorConfig/editor/views/view[tab/@id = $tab]"/>
  <xsl:variable name="tabConfig" select="$editorConfig/editor/views/view/tab[@id = $tab]"/>
  <xsl:variable name="thesaurusList" select="$editorConfig/editor/views/view[tab/@id = $tab]/thesaurusList"/>
  
  <xsl:variable name="isFlatMode" select="if (/root/request/flat) then /root/request/flat = 'true'
    else $tabConfig/@mode = 'flat'"/>
  
  
</xsl:stylesheet>
