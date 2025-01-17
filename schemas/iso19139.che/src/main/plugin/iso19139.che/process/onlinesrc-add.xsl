<?xml version="1.0" encoding="UTF-8"?>
<!--  
Stylesheet used to update metadata for a service and 
attached it to the metadata for data.
-->
<xsl:stylesheet version="2.0" xmlns:gmd="http://www.isotc211.org/2005/gmd"
  xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gts="http://www.isotc211.org/2005/gts"
  xmlns:gml="http://www.opengis.net/gml" xmlns:srv="http://www.isotc211.org/2005/srv"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:che="http://www.geocat.ch/2008/che" xmlns:gmx="http://www.isotc211.org/2005/gmx"
  xmlns:mime="java:org.fao.geonet.util.MimeTypeFinder">

  <!-- ============================================================================= -->

  <xsl:param name="uuidref"/>
  <xsl:param name="extra_metadata_uuid"/>
  <xsl:param name="protocol" select="'WWW:LINK-1.0-http--link'"/>
  <xsl:param name="url"/>
  <xsl:param name="name"/>
  <xsl:param name="desc"/>

  <!-- ============================================================================= -->

  <xsl:template match="/gmd:MD_Metadata|*[@gco:isoType='gmd:MD_Metadata']">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:copy-of
        select="gmd:fileIdentifier|
		    gmd:language|
		    gmd:characterSet|
		    gmd:parentIdentifier|
		    gmd:hierarchyLevel|
		    gmd:hierarchyLevelName|
		    gmd:contact|
		    gmd:dateStamp|
		    gmd:metadataStandardName|
		    gmd:metadataStandardVersion|
		    gmd:dataSetURI|
		    gmd:locale|
		    gmd:spatialRepresentationInfo|
		    gmd:referenceSystemInfo|
		    gmd:metadataExtensionInfo|
		    gmd:identificationInfo|
		    gmd:contentInfo"/>

      <gmd:distributionInfo>
        <gmd:MD_Distribution>
          <xsl:copy-of
            select="gmd:distributionInfo/gmd:MD_Distribution/gmd:distributionFormat"/>
          <xsl:copy-of
            select="gmd:distributionInfo/gmd:MD_Distribution/gmd:distributor"/>
          <gmd:transferOptions>
            <gmd:MD_DigitalTransferOptions>
              <xsl:copy-of
                select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions[1]/gmd:MD_DigitalTransferOptions/gmd:unitsOfDistribution"/>
              <xsl:copy-of
                select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions[1]/gmd:MD_DigitalTransferOptions/gmd:transferSize"/>
              <xsl:copy-of
                select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions[1]/gmd:MD_DigitalTransferOptions/gmd:onLine"/>


              <!-- Add all online source from the target metadata to the
              current one -->
              <xsl:if test="//extra">
                <xsl:for-each select="//extra//gmd:onLine">
                  <gmd:onLine>
                    <xsl:if test="$extra_metadata_uuid">
                      <xsl:attribute name="uuidref" select="$extra_metadata_uuid"/>
                    </xsl:if>
                    <xsl:copy-of select="*"/>
                  </gmd:onLine>
                </xsl:for-each>
              </xsl:if>
              <xsl:if test="$url">

                <xsl:variable name="separator" select="'\|'"/>

                <!-- In case the protocol is an OGC protocol
                the name parameter may contains a list of layers
                separated by comma.
                In that case on one online element is added per
                layer/featureType.
                -->
                <xsl:choose>
                  <xsl:when test="starts-with($protocol, 'OGC:')">

                    <xsl:for-each select="tokenize($name, ',')">
                      <xsl:variable name="pos" select="position()"/>
                      <gmd:onLine>
                        <xsl:if test="$uuidref">
                          <xsl:attribute name="uuidref" select="$uuidref"/>
                        </xsl:if>
                        <gmd:CI_OnlineResource>
                          <gmd:linkage xsi:type="che:PT_FreeURL_PropertyType">
                            <xsl:choose>
                              <xsl:when test="contains($url, '#')">
                                <che:PT_FreeURL>
                                  <xsl:for-each select="tokenize($url, $separator)">
                                    <xsl:variable name="nameLang" select="substring-before(., '#')"></xsl:variable>
                                    <xsl:variable name="nameValue" select="substring-after(., '#')"></xsl:variable>
                                    <che:URLGroup>
                                      <che:LocalisedURL locale="{concat('#', $nameLang)}"><xsl:value-of select="$nameValue" /></che:LocalisedURL>
                                    </che:URLGroup>
                                  </xsl:for-each>
                                </che:PT_FreeURL>
                              </xsl:when>
                              <xsl:otherwise>
                                <gmd:URL>
                                  <xsl:value-of select="$url"/>
                                </gmd:URL>
                              </xsl:otherwise>
                            </xsl:choose>
                          </gmd:linkage>
                          <gmd:protocol>
                            <gco:CharacterString>
                              <xsl:value-of select="$protocol"/>
                            </gco:CharacterString>
                          </gmd:protocol>

                          <xsl:if test=". != ''">
                            <gmd:name>
                              <gco:CharacterString>
                                <xsl:value-of select="."/>
                              </gco:CharacterString>
                            </gmd:name>
                          </xsl:if>

                          <xsl:if test="tokenize($desc, ',')[position() = $pos] != ''">
                            <gmd:description>
                              <gco:CharacterString>
                                <xsl:value-of select="tokenize($desc, ',')[position() = $pos]"/>
                              </gco:CharacterString>
                            </gmd:description>
                          </xsl:if>
                        </gmd:CI_OnlineResource>
                      </gmd:onLine>
                    </xsl:for-each>
                  </xsl:when>
                  <xsl:otherwise>
                    <!-- ... the name is simply added in the newly
                    created online element. -->

                    <gmd:onLine>
                      <xsl:if test="$uuidref">
                        <xsl:attribute name="uuidref" select="$uuidref"/>
                      </xsl:if>
                      <gmd:CI_OnlineResource>
                        <gmd:linkage xsi:type="che:PT_FreeURL_PropertyType">
                          <che:PT_FreeURL>
                            <xsl:for-each select="tokenize($url, $separator)">
                              <xsl:variable name="nameLang" select="substring-before(., '#')"></xsl:variable>
                              <xsl:variable name="nameValue" select="substring-after(., '#')"></xsl:variable>
                              <che:URLGroup>
                                <che:LocalisedURL locale="{concat('#', $nameLang)}"><xsl:value-of select="$nameValue" /></che:LocalisedURL>
                              </che:URLGroup>
                            </xsl:for-each>
                          </che:PT_FreeURL>
                        </gmd:linkage>

                        <xsl:if test="$protocol != ''">
                          <gmd:protocol>
                            <gco:CharacterString>
                              <xsl:value-of select="$protocol"/>
                            </gco:CharacterString>
                          </gmd:protocol>
                        </xsl:if>

                        <xsl:if test="$name != ''">
                          <xsl:choose>
                            <xsl:when test="contains($name, '#')">
                              <gmd:name xsi:type="gmd:PT_FreeText_PropertyType">
                                <gmd:PT_FreeText>
                                  <xsl:for-each select="tokenize($name, $separator)">
                                    <xsl:variable name="nameLang" select="substring-before(., '#')"></xsl:variable>
                                    <xsl:variable name="nameValue" select="substring-after(., '#')"></xsl:variable>
                                    <gmd:textGroup>
                                      <gmd:LocalisedCharacterString locale="{concat('#', $nameLang)}"><xsl:value-of select="$nameValue" /></gmd:LocalisedCharacterString>
                                    </gmd:textGroup>
                                  </xsl:for-each>
                                </gmd:PT_FreeText>
                              </gmd:name>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:variable name="mimeType" select="mime:detectMimeTypeFile(/root/env/datadir,$name)"/>
                              <gmd:name>
                                <gmx:MimeFileType type="{$mimeType}"><xsl:value-of select="$name"/></gmx:MimeFileType>
                              </gmd:name>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:if>

                        <xsl:if test="$desc != ''">
                          <xsl:choose>
                            <xsl:when test="contains($desc, '#')">
                              <gmd:description xsi:type="gmd:PT_FreeText_PropertyType">
                                <gmd:PT_FreeText>
                                  <xsl:for-each select="tokenize($desc, $separator)">
                                    <xsl:variable name="descLang" select="substring-before(., '#')"></xsl:variable>
                                    <xsl:variable name="descValue" select="substring-after(., '#')"></xsl:variable>
                                    <gmd:textGroup>
                                      <gmd:LocalisedCharacterString locale="{concat('#', $descLang)}"><xsl:value-of select="$descValue" /></gmd:LocalisedCharacterString>
                                    </gmd:textGroup>
                                  </xsl:for-each>
                                </gmd:PT_FreeText>
                              </gmd:description>
                            </xsl:when>
                            <xsl:otherwise>
                              <gmd:description xsi:type="gmd:PT_FreeText_PropertyType">
                                <gco:CharacterString><xsl:value-of select="$desc"/></gco:CharacterString>
                              </gmd:description>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:if>
                        <!-- TODO may be relevant to add the function -->
                      </gmd:CI_OnlineResource>
                    </gmd:onLine>
                  </xsl:otherwise>
                </xsl:choose>


              </xsl:if>
              <xsl:copy-of
                select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions[1]/gmd:MD_DigitalTransferOptions/gmd:offLine"
                />
            </gmd:MD_DigitalTransferOptions>
          </gmd:transferOptions>
          <xsl:copy-of
            select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions[position() > 1]"
            />
        </gmd:MD_Distribution>

      </gmd:distributionInfo>

      <xsl:copy-of
        select="gmd:dataQualityInfo|
			gmd:portrayalCatalogueInfo|
			gmd:metadataConstraints|
			gmd:applicationSchemaInfo|
			gmd:metadataMaintenance|
			gmd:series|
			gmd:describes|
			gmd:propertyType|
			gmd:featureType|
			gmd:featureAttribute|
			legislationInformation"/>

    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
