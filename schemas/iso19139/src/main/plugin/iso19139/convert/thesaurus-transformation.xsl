<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:gmx="http://www.isotc211.org/2005/gmx"
                xmlns:gco="http://www.isotc211.org/2005/gco"
                xmlns:gmd="http://www.isotc211.org/2005/gmd"
                xmlns:srv="http://www.isotc211.org/2005/srv"
                xmlns:geonet="http://www.fao.org/geonetwork"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:util="java:org.fao.geonet.util.XslUtil"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="#all">


  <!-- A set of templates use to convert thesaurus concept to ISO19139 fragments. -->



  <xsl:include href="../process/process-utility.xsl"/>


  <!-- Convert a concept to an ISO19139 fragment with an Anchor
        for each keywords pointing to the concept URI-->
  <xsl:template name="to-iso19139-keyword-with-anchor">
    <xsl:call-template name="to-iso19139-keyword">
      <xsl:with-param name="withAnchor" select="true()"/>
    </xsl:call-template>
  </xsl:template>


  <!-- Convert a concept to an ISO19139 gmd:MD_Keywords with an XLink which
    will be resolved by XLink resolver. -->
  <xsl:template name="to-iso19139-keyword-as-xlink">
    <xsl:call-template name="to-iso19139-keyword">
      <xsl:with-param name="withXlink" select="true()"/>
    </xsl:call-template>
  </xsl:template>


  <!-- Convert a concept to an ISO19139 keywords.
    If no keyword is provided, only thesaurus section is adaded.
    -->
  <xsl:template name="to-iso19139-keyword">
    <xsl:param name="withAnchor" select="false()"/>
    <xsl:param name="withXlink" select="false()"/>
    <!-- Add thesaurus identifier using an Anchor which points to the download link.
        It's recommended to use it in order to have the thesaurus widget inline editor
        which use the thesaurus identifier for initialization. -->
    <xsl:param name="withThesaurusAnchor" select="true()"/>


    <!-- The lang parameter contains a list of languages
    with the main one as the first element. If only one element
    is provided, then CharacterString or Anchor are created.
    If more than one language is provided, then PT_FreeText
    with or without CharacterString can be created. -->
    <xsl:variable name="listOfLanguage" select="tokenize(/root/request/lang, ',')"/>
    <xsl:variable name="textgroupOnly"
                  as="xs:boolean"
                  select="if (/root/request/textgroupOnly and normalize-space(/root/request/textgroupOnly) != '')
                          then /root/request/textgroupOnly
                          else false()"/>


    <xsl:apply-templates mode="to-iso19139-keyword" select="." >
      <xsl:with-param name="withAnchor" select="$withAnchor"/>
      <xsl:with-param name="withXlink" select="$withXlink"/>
      <xsl:with-param name="withThesaurusAnchor" select="$withThesaurusAnchor"/>
      <xsl:with-param name="listOfLanguage" select="$listOfLanguage"/>
      <xsl:with-param name="textgroupOnly" select="$textgroupOnly"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template mode="to-iso19139-keyword" match="*[not(/root/request/skipdescriptivekeywords)]">
    <xsl:param name="textgroupOnly"/>
    <xsl:param name="listOfLanguage"/>
    <xsl:param name="withAnchor"/>
    <xsl:param name="withXlink"/>
    <xsl:param name="withThesaurusAnchor"/>

    <gmd:descriptiveKeywords>
      <xsl:choose>
        <xsl:when test="$withXlink">
          <xsl:variable name="multiple"
                        select="if (contains(/root/request/id, ',')) then 'true' else 'false'"/>
          <xsl:variable name="isLocalXlink"
                        select="util:getSettingValue('system/xlinkResolver/localXlinkEnable')"/>
          <xsl:variable name="prefixUrl"
                        select="if ($isLocalXlink = 'true')
																then  concat('local://', /root/gui/language)
																else $serviceUrl"/>

          <xsl:attribute name="xlink:href"
                         select="concat($prefixUrl, '/xml.keyword.get?thesaurus=', thesaurus/key,
							                '&amp;amp;id=', replace(/root/request/id, '#', '%23'),
							                '&amp;amp;multiple=', $multiple,
							                if (/root/request/lang) then concat('&amp;amp;lang=', /root/request/lang) else '',
							                if ($textgroupOnly) then '&amp;amp;textgroupOnly' else '')"/>
          <xsl:attribute name="xlink:show">replace</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="to-md-keywords">
            <xsl:with-param name="withAnchor" select="$withAnchor"/>
            <xsl:with-param name="withThesaurusAnchor" select="$withThesaurusAnchor"/>
            <xsl:with-param name="listOfLanguage" select="$listOfLanguage"/>
            <xsl:with-param name="textgroupOnly" select="$textgroupOnly"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </gmd:descriptiveKeywords>
  </xsl:template>

  <xsl:template mode="to-iso19139-keyword" match="*[/root/request/skipdescriptivekeywords]">
    <xsl:param name="textgroupOnly"/>
    <xsl:param name="listOfLanguage"/>
    <xsl:param name="withAnchor"/>
    <xsl:param name="withThesaurusAnchor"/>

    <xsl:call-template name="to-md-keywords">
      <xsl:with-param name="withAnchor" select="$withAnchor"/>
      <xsl:with-param name="withThesaurusAnchor" select="$withThesaurusAnchor"/>
      <xsl:with-param name="listOfLanguage" select="$listOfLanguage"/>
      <xsl:with-param name="textgroupOnly" select="$textgroupOnly"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="to-md-keywords">
    <xsl:param name="textgroupOnly"/>
    <xsl:param name="listOfLanguage"/>
    <xsl:param name="withAnchor"/>
    <xsl:param name="withThesaurusAnchor"/>

    <gmd:MD_Keywords>
      <!-- Get thesaurus ID from keyword or from request parameter if no keyword found. -->
      <xsl:variable name="currentThesaurus" select="if (thesaurus/key) then thesaurus/key else /root/request/thesaurus" />
      <!-- Loop on all keyword from the same thesaurus -->
      <xsl:for-each select="//keyword[thesaurus/key = $currentThesaurus]">
        <gmd:keyword>
          <xsl:if test="$currentThesaurus = 'external.none.allThesaurus'">
            <!--
                if 'all' thesaurus we need to encode the thesaurus name so that update-fixed-info can re-organize the
                keywords into the correct thesaurus sections.
            -->
            <xsl:variable name="keywordThesaurus" select="replace(./uri, 'http://org.fao.geonet.thesaurus.all/([^@]+)@@@.+', '$1')" />
            <xsl:attribute name="gco:nilReason" select="concat('thesaurus::', $keywordThesaurus)" />
          </xsl:if>
          <xsl:if test="$textgroupOnly or count($listOfLanguage) > 1">
            <xsl:attribute name="xsi:type">gmd:PT_FreeText_PropertyType</xsl:attribute>
          </xsl:if>

          <!-- Multilingual output if more than one requested language -->
          <xsl:choose>
            <xsl:when test="count($listOfLanguage) > 1">

              <xsl:variable name="keyword" select="." />

              <xsl:if test="not($textgroupOnly)">
                <gco:CharacterString>
                  <xsl:value-of select="$keyword/values/value[@language = $listOfLanguage[1]]/text()"></xsl:value-of>
                </gco:CharacterString>
              </xsl:if>

              <gmd:PT_FreeText>
                <xsl:for-each select="$listOfLanguage">
                  <xsl:variable name="lang" select="." />
                  <xsl:if test="$textgroupOnly or $lang != $listOfLanguage[1]">
                    <gmd:textGroup>
                      <gmd:LocalisedCharacterString locale="#{upper-case(util:twoCharLangCode($lang))}">
                        <xsl:value-of select="$keyword/values/value[@language = $lang]/text()"></xsl:value-of>
                      </gmd:LocalisedCharacterString>
                    </gmd:textGroup>
                  </xsl:if>
                </xsl:for-each>
              </gmd:PT_FreeText>
            </xsl:when>
            <xsl:otherwise>
              <!-- ... default mode -->
              <xsl:choose>
                <xsl:when test="$withAnchor">
                  <!-- TODO multilingual Anchor ? -->
                  <gmx:Anchor xlink:href="{$serviceUrl}/xml.keyword.get?thesaurus={thesaurus/key}&amp;id={uri}">
                    <xsl:value-of select="value" />
                  </gmx:Anchor>
                </xsl:when>
                <xsl:otherwise>
                  <gco:CharacterString>
                    <xsl:value-of select="value" />
                  </gco:CharacterString>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </gmd:keyword>
      </xsl:for-each>
      <xsl:copy-of select="geonet:add-thesaurus-info($currentThesaurus, $withThesaurusAnchor, /root/gui/thesaurus/thesauri,
                                                     not(/root/request/keywordOnly), $textgroupOnly, $listOfLanguage)" />
    </gmd:MD_Keywords>
  </xsl:template>

  <xsl:function name="geonet:add-thesaurus-info">
    <xsl:param name="currentThesaurus" as="xs:string"/>
    <xsl:param name="withThesaurusAnchor" as="xs:boolean"/>
    <xsl:param name="thesauri" as="node()"/>
    <xsl:param name="thesaurusInfo" as="xs:boolean"/>
    <xsl:param name="textgroupOnly"/>
    <xsl:param name="listOfLanguage"/>

    <xsl:variable name="thesaurusEl" select="$thesauri/thesaurus[key = $currentThesaurus]"/>
    <!-- Add thesaurus theme -->
    <gmd:type>
      <gmd:MD_KeywordTypeCode codeList="http://www.isotc211.org/2005/resources/codeList.xml#MD_KeywordTypeCode"
        codeListValue="{$thesaurusEl/dname}" />
    </gmd:type>
    <xsl:if test="$thesaurusInfo">
      <gmd:thesaurusName>
        <gmd:CI_Citation>
          <gmd:title>
            <gco:CharacterString>
              <xsl:value-of select="$thesauri/thesaurus[key = $currentThesaurus]/title" />
            </gco:CharacterString>
          </gmd:title>

          <xsl:variable name="thesaurusDate"
                        select="normalize-space($thesauri/thesaurus[key = $currentThesaurus]/date)" />

          <xsl:if test="$thesaurusDate != ''">
            <gmd:date>
              <gmd:CI_Date>
                <gmd:date>
                  <xsl:choose>
                    <xsl:when test="contains($thesaurusDate, 'T')">
                      <gco:DateTime>
                        <xsl:value-of select="$thesaurusDate" />
                      </gco:DateTime>
                    </xsl:when>
                    <xsl:otherwise>
                      <gco:Date>
                        <xsl:value-of select="$thesaurusDate" />
                      </gco:Date>
                    </xsl:otherwise>
                  </xsl:choose>
                </gmd:date>
                <gmd:dateType>
                  <gmd:CI_DateTypeCode
                          codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/Codelist/ML_gmxCodelists.xml#CI_DateTypeCode"
                          codeListValue="publication" />
                </gmd:dateType>
              </gmd:CI_Date>
            </gmd:date>
          </xsl:if>

          <xsl:if test="$withThesaurusAnchor">
            <gmd:identifier>
              <gmd:MD_Identifier>
                <gmd:code>
                  <gmx:Anchor xlink:href="{$thesauri/thesaurus[key = $currentThesaurus]/url}">geonetwork.thesaurus.<xsl:value-of
                          select="$currentThesaurus" />
                  </gmx:Anchor>
                </gmd:code>
              </gmd:MD_Identifier>
            </gmd:identifier>
          </xsl:if>
        </gmd:CI_Citation>
      </gmd:thesaurusName>
    </xsl:if>
  </xsl:function>

  <!-- Convert a concept to an ISO19139 extent -->
  <xsl:template name="to-iso19139-extent">
    <xsl:param name="isService" select="false()"/>

    <xsl:variable name="currentThesaurus" select="thesaurus/key"/>
    <!-- Loop on all keyword from the same thesaurus -->
    <xsl:for-each select="//keyword[thesaurus/key = $currentThesaurus]">
      <xsl:choose>
        <xsl:when test="$isService">
          <srv:extent>
            <xsl:copy-of select="geonet:make-iso-extent(geo/west, geo/south, geo/east, geo/north, value)"/>
          </srv:extent>
        </xsl:when>
        <xsl:otherwise>
          <gmd:extent>
            <xsl:copy-of select="geonet:make-iso-extent(geo/west, geo/south, geo/east, geo/north, value)"/>
          </gmd:extent>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
