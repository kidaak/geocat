<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:geonet="http://www.fao.org/geonetwork"
                xmlns:gfc="http://www.isotc211.org/2005/gfc" xmlns:gmx="http://www.isotc211.org/2005/gmx"
                xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:gmd="http://www.isotc211.org/2005/gmd"
                exclude-result-prefixes="#all">



    <xsl:template name="view-with-header-iso19110">
        <xsl:param name="tabs"/>

        <xsl:call-template name="md-content">
            <xsl:with-param name="title">
                <xsl:value-of select="//gfc:FC_FeatureCatalogue/gfc:name" />
            </xsl:with-param>
            <xsl:with-param name="exportButton"/>
            <xsl:with-param name="logo">
                <img src="../../images/logos/{//geonet:info/source}.gif" alt="logo" class="logo"/>
            </xsl:with-param>
            <xsl:with-param name="relatedResources">
                <table class="related">
                    <tbody>
                        <tr style="display:none;"><!-- FIXME needed by JS-->
                            <td class="main"></td>
                            <td></td>
                        </tr>
                    </tbody>
                </table>
            </xsl:with-param>
            <xsl:with-param name="tabs" select="$tabs"/>

        </xsl:call-template>
    </xsl:template>

    <!-- iso19110-simple -->
    <xsl:template name="metadata-iso19110view-simple" match="metadata-iso19110view-simple">

        <xsl:call-template name="md-content">
            <xsl:with-param name="title" select="//gfc:FC_FeatureCatalogue/gfc:name"/>
            <xsl:with-param name="exportButton"/>
            <xsl:with-param name="abstract"/>
            <xsl:with-param name="logo">
                <img src="../../images/logos/{//geonet:info/source}.gif" alt="logo"/>
            </xsl:with-param>
            <xsl:with-param name="relatedResources">
                <table class="related">
                    <tbody>
                        <tr style="display:none;"><!-- FIXME needed by JS-->
                            <td class="main"></td>
                            <td></td>
                        </tr>
                    </tbody>
                </table>
            </xsl:with-param>
            <xsl:with-param name="tabs">

                <xsl:call-template name="complexElementSimpleGui">
                    <xsl:with-param name="title" select="string(/root/gui/schemas/iso19110/labels/element[@name='gfc:producer']/label)"/>
                    <xsl:with-param name="content">
                        <xsl:apply-templates mode="block"
                                             select="gfc:producer"/>
                    </xsl:with-param>
                </xsl:call-template>

                <xsl:call-template name="complexElementSimpleGui">
                    <xsl:with-param name="title">
                        <xsl:call-template name="getTitle">
                            <xsl:with-param name="name" select="name(.)"/>
                            <xsl:with-param name="schema" select="$schema"/>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="content">
                        <xsl:apply-templates mode="block"
                                             select="//gfc:FC_FeatureType"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <xsl:template mode="block" match="gfc:producer" priority="100">

        <xsl:call-template name="simpleElementSimpleGUI">
            <xsl:with-param name="title">
                <xsl:value-of
                        select="geonet:getCodeListValue(/root/gui/schemas, 'iso19139', 'gmd:CI_RoleCode', */gmd:role/gmd:CI_RoleCode/@codeListValue)"
                        />
            </xsl:with-param>
            <xsl:with-param name="helpLink">
                <xsl:call-template name="getHelpLink">
                    <xsl:with-param name="schema" select="$schema"/>
                    <xsl:with-param name="name" select="name(.)"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="content">
                <xsl:apply-templates mode="iso19110-simple"
                                     select="
          gmd:CI_ResponsibleParty/gmd:contactInfo/gmd:CI_Contact/gmd:address/descendant::node()[(gco:CharacterString and normalize-space(gco:CharacterString)!='')]
          "/>

                <xsl:for-each
                        select="gmd:CI_ResponsibleParty/gmd:contactInfo/gmd:CI_Contact/gmd:onlineResource/gmd:CI_OnlineResource">

                    <xsl:call-template name="simpleElement">
                        <xsl:with-param name="id" select="generate-id(.)"/>
                        <xsl:with-param name="title">
                            <xsl:call-template name="getTitle">
                                <xsl:with-param name="name" select="'gmd:onlineResource'"/>
                                <xsl:with-param name="schema" select="$schema"/>
                            </xsl:call-template>
                        </xsl:with-param>
                        <xsl:with-param name="help"></xsl:with-param>
                        <xsl:with-param name="content">
                            <a href="{gmd:linkage/gmd:URL}" target="_blank">
                                <xsl:value-of select="gmd:name/gco:CharacterString"/>
                            </a>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:for-each>

                <xsl:if test="descendant::gmx:FileName">
                    <img src="{descendant::gmx:FileName/@src}" alt="logo" class="orgLogo" style="float:right;"/>
                    <!-- FIXME : css -->
                </xsl:if>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <xsl:template mode="block" match="gfc:FC_FeatureType" priority="100">
        <xsl:call-template name="simpleElementSimpleGUI">
            <xsl:with-param name="title">
                <xsl:value-of select="string(/root/gui/schemas/iso19110/labels/element[@name='gfc:FC_FeatureType']/label)"/>
            </xsl:with-param>
            <xsl:with-param name="helpLink">
                <xsl:call-template name="getHelpLink">
                    <xsl:with-param name="schema" select="$schema"/>
                    <xsl:with-param name="name" select="name(.)"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="content">

                    <xsl:for-each
                            select="gfc:carrierOfCharacteristics/gfc:FC_FeatureAttribute">

                        <table class="gn">
                        <tr>
                            <th style="width: 100px"><label for="_">
                                <xsl:value-of select="string(/root/gui/schemas/iso19139/labels/element[@name='gco:LocalName']/label)"/>
                            </label></th>
                            <td>
                                <xsl:value-of select="gfc:memberName/gco:LocalName"/>

                                <xsl:if test="string(gfc:definition/gco:CharacterString)">
                                    -
                                    <xsl:value-of select="gfc:definition/gco:CharacterString"/>
                                </xsl:if>
                            </td>
                        </tr>

                        <tr>
                            <th><label for="_">
                                <xsl:value-of select="string(/root/gui/schemas/iso19110/labels/element[@name='gfc:valueType']/label)"/>
                            </label></th>
                            <td>
                                <xsl:value-of select="gfc:valueType/gco:TypeName/gco:aName/gco:CharacterString"/>
                            </td>
                        </tr>

                        <tr>
                            <th><label for="_">
                                <xsl:value-of select="string(/root/gui/schemas/iso19110/labels/element[@name='gfc:cardinality']/label)"/>
                            </label></th>
                            <td>

                                <xsl:variable name="minValue"
                                              select="gfc:cardinality/gco:Multiplicity/gco:range/gco:MultiplicityRange/gco:lower/gco:Integer"/>
                                <xsl:variable name="maxValue"
                                              select="gfc:cardinality/gco:Multiplicity/gco:range/gco:MultiplicityRange/gco:upper/gco:UnlimitedInteger"/>
                                <xsl:variable name="isInfinite"
                                              select="gfc:cardinality/gco:Multiplicity/gco:range/gco:MultiplicityRange/gco:upper/gco:UnlimitedInteger/@isInfinite"/>

                                <xsl:value-of select="$minValue"/> -
                                <xsl:choose>
                                    <xsl:when test="$isInfinite = 'true'">
                                        n
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$maxValue"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </td>
                        </tr>

                        <xsl:if test="gfc:listedValue">
                            <tr>
                                <th><label for="_">
                                    <xsl:value-of select="string(/root/gui/schemas/iso19110/labels/element[@name='gfc:listedValue']/label)"/>
                                </label></th>
                                <td>
                                    <table class="gn" width="80%">
                                        <tr>
                                            <th style="width: 10%"><label for="_">
                                                <xsl:value-of select="string(/root/gui/schemas/iso19110/labels/element[@name='gfc:code']/label)"/>

                                            </label></th>
                                            <th style="width: 40%"><label for="_">
                                                <xsl:value-of select="string(/root/gui/schemas/iso19110/labels/element[@name='gfc:label']/label)"/>

                                            </label></th>
                                            <th style="width: 50%"><label for="_">
                                                <xsl:value-of select="string(/root/gui/schemas/iso19110/labels/element[@name='gfc:definition']/label)"/>

                                            </label></th>
                                        </tr>

                                        <xsl:for-each
                                                select="gfc:listedValue/gfc:FC_ListedValue">

                                            <tr>
                                                <td ><xsl:value-of select="gfc:code/gco:CharacterString" /></td>
                                                <td ><xsl:value-of select="gfc:label/gco:CharacterString" /></td>
                                                <td ><xsl:value-of select="gfc:definition/gco:CharacterString" /></td>
                                            </tr>
                                        </xsl:for-each>
                                    </table>
                                </td>
                            </tr>
                        </xsl:if>

                            <tr>
                            <td colspan="2"><br/></td>
                            </tr>
                        </table>
                    </xsl:for-each>

            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <xsl:template mode="iso19110-simple" match="*[gco:CharacterString]" priority="2">
        <xsl:variable name="adjustedSchema">
            <xsl:choose>
                <xsl:when test="namespace-uri(.) != 'http://www.isotc211.org/2005/gfc'">
                    <xsl:text>iso19139</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$schema"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:call-template name="simpleElement">
            <xsl:with-param name="id" select="generate-id(.)"/>
            <xsl:with-param name="title">
                <xsl:call-template name="getTitle">
                    <xsl:with-param name="name" select="name(.)"/>
                    <xsl:with-param name="schema" select="$adjustedSchema"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="help"></xsl:with-param>
            <xsl:with-param name="content">
                <xsl:value-of select="gco:CharacterString"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

</xsl:stylesheet>
