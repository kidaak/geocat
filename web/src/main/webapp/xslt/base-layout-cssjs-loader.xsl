<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:util="java:org.fao.geonet.util.XslUtil"
                exclude-result-prefixes="#all">
  <!-- Template to load CSS and Javascript -->


  <xsl:import href="common/base-variables.xsl"/>

  <xsl:variable name="minimizedParam">
      <xsl:choose>
          <xsl:when test="/root/request/debug">?minimize=false</xsl:when>
          <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
  </xsl:variable>

  <xsl:template name="css-load">
    <!--
            TODO : less compilation
            <link href="style/app.css" rel="stylesheet" media="screen" />
-->
    <xsl:if test="$withD3">
      <link href="{/root/gui/url}/static/nv.d3.css{$minimizedParam}" rel="stylesheet" media="screen" />
    </xsl:if>

    <link href="{/root/gui/url}/static/{$customFilename}.css{$minimizedParam}" rel="stylesheet" media="screen" />

    <link href="{/root/gui/url}/static/{/root/gui/nodeId}_custom_style.css{$minimizedParam}" rel="stylesheet" media="screen" />
  </xsl:template>


  <xsl:template name="javascript-load">

    <script>var geonet={provide:function(s){},require:function(s){}}</script>
    <xsl:choose>
      <xsl:when test="$isDebugMode">

        <script src="{$uiResourcesPath}lib/modernizr.js"></script>
        <script src="{$uiResourcesPath}lib/closure/base.js"></script>

        <script src="{$uiResourcesPath}lib/base64.js"></script>

        <script src="{$uiResourcesPath}lib/jquery-2.0.3.js"></script>

        <script src="{$uiResourcesPath}lib/moment+langs.min.js"></script>

        <script src="{$uiResourcesPath}lib/angular/angular.js"></script>
        <script src="{$uiResourcesPath}lib/angular/angular-resource.js"></script>
        <script src="{$uiResourcesPath}lib/angular/angular-route.js"></script>
        <script src="{$uiResourcesPath}lib/angular/angular-sanitize.js"></script>
        <script src="{$uiResourcesPath}lib/angular/angular-cookies.js"></script>

        <script src="{$uiResourcesPath}lib/angular-translate.js"></script>
        <script src="{$uiResourcesPath}lib/angular-md5.js"></script>
        <script src="{$uiResourcesPath}lib/angular-filter.min.js"></script>
        <script src="{$uiResourcesPath}lib/angular.ext/hotkeys/hotkeys.js"></script>
        <script src="{$uiResourcesPath}lib/angular.ext/datetimepicker.js"></script>
        <script src="{$uiResourcesPath}lib/angular.ext/buttons.js"></script>
        <script src="{$uiResourcesPath}lib/angular.ext/rating.js"></script>
        <script src="{$uiResourcesPath}lib/angular.ext/typeahead.js"></script>
        <script src="{$uiResourcesPath}lib/angular.ext/position.js"></script>
        <script src="{$uiResourcesPath}lib/angular.ext/bindHtml.js"></script>
        <script src="{$uiResourcesPath}lib/angular.ext/tabs.js"></script>
        <script src="{$uiResourcesPath}lib/angular.ext/slider.js"></script>

        <script src="{$uiResourcesPath}lib/style/bootstrap/dist/js/bootstrap.js"></script>
        <script src="{$uiResourcesPath}lib/jquery.ext/jquery-ui-slider.min.js"></script>
        <script src="{$uiResourcesPath}lib/proj4js-compressed.js"></script>
        <script src="{$uiResourcesPath}lib/ngeo/ngeo-debug.js"></script>
        <xsl:if test="$withD3">
          <script src="{$uiResourcesPath}lib/d3.v3.js"></script>
          <script src="{$uiResourcesPath}lib/nv.d3.js"></script>
        </xsl:if>

        <xsl:if test="$angularApp = 'gn_search'">
          <script src="{$uiResourcesPath}lib/zip/zip.js"></script>
          <script type="text/javascript">
            zip.workerScriptsPath = "../../catalog/lib/zip/";
          </script>
        </xsl:if>

        <!-- Jsonix resources (OWS Context) -->
        <script src="{$uiResourcesPath}lib/jsonix/jsonix/Jsonix-min.js"></script>
        <script src="{$uiResourcesPath}lib/jsonix/w3c-schemas/XLink_1_0.js"></script>
        <script src="{$uiResourcesPath}lib/jsonix/ogc-schemas/OWS_1_0_0.js"></script>
        <script src="{$uiResourcesPath}lib/jsonix/ogc-schemas/Filter_1_0_0.js"></script>
        <script src="{$uiResourcesPath}lib/jsonix/ogc-schemas/GML_2_1_2.js"></script>
        <script src="{$uiResourcesPath}lib/jsonix/ogc-schemas/SLD_1_0_0.js"></script>
        <script src="{$uiResourcesPath}lib/jsonix/ogc-schemas/OWC_0_3_1.js"></script>


        <!--<xsl:if test="$isEditing">-->
        <script src="{$uiResourcesPath}lib/jquery.ext/jquery.ui.widget.js"></script>
        <script src="{$uiResourcesPath}lib/jquery.ext/jquery.iframe-transport.js"></script>
        <script src="{$uiResourcesPath}lib/jquery.ext/jquery.fileupload.js"></script>
        <script src="{$uiResourcesPath}lib/jquery.ext/jquery.fileupload-process.js"></script>
        <script src="{$uiResourcesPath}lib/jquery.ext/jquery.fileupload-angular.js"></script>
        <script src="{$uiResourcesPath}lib/bootstrap.ext/typeahead.js/typeahead.bundle.js"></script>
        <script src="{$uiResourcesPath}lib/bootstrap.ext/typeahead.js/handlebars-v2.0.0.js"></script>
        <script src="{$uiResourcesPath}lib/bootstrap.ext/tagsinput/bootstrap-tagsinput.js"></script>
        <script src="{$uiResourcesPath}lib/bootstrap.ext/datepicker/bootstrap-datepicker.js"></script>
        <!--</xsl:if>-->

      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:choose>
        <xsl:when test="/root/request/debug">
            <!-- Use Closure to load the application scripts -->
            <script src="{/root/gui/url}/static/closure_deps.js"></script>
            <script>
                 goog.require('<xsl:value-of select="$angularModule"/>');
            </script>
        </xsl:when>
        <xsl:otherwise>
            <script src="{/root/gui/url}/static/lib.js"></script>
            <script src="{/root/gui/url}/static/{$angularModule}.js{$minimizedParam}"></script>
        </xsl:otherwise>
    </xsl:choose>


    <xsl:variable name="mapConfig"
                  select="util:getSettingValue('map/config')"/>

    <xsl:variable name="isMapViewerEnabled">
	    <xsl:choose>
	    <xsl:when test="util:getSettingValue('map/isMapViewerEnabled')"><xsl:value-of select="util:getSettingValue('map/isMapViewerEnabled')"/></xsl:when>
	    <xsl:otherwise>true</xsl:otherwise> <!-- default value -->
	  </xsl:choose>
                  
    </xsl:variable>

    <xsl:if test="$angularApp = 'gn_search'">
      <script type="text/javascript">
        var module = angular.module('gn_search');
        module.config(['gnViewerSettings', 'gnGlobalSettings',
                function(gnViewerSettings, gnGlobalSettings) {
          <xsl:if test="$owsContext">
            gnViewerSettings.owsContext = '<xsl:value-of select="$owsContext"/>';
          </xsl:if>
          <xsl:if test="$wmsUrl and $layerName">
            gnViewerSettings.wmsUrl = '<xsl:value-of select="$wmsUrl"/>';
            gnViewerSettings.layerName = '<xsl:value-of select="$layerName"/>';
          </xsl:if>
          gnViewerSettings.mapConfig = <xsl:value-of select="$mapConfig"/>;
          gnGlobalSettings.isMapViewerEnabled = <xsl:value-of select="$isMapViewerEnabled"/>;
        }]);
      </script>
    </xsl:if>
    
    <xsl:if test="$angularApp = 'gn_editor'">
      <script type="text/javascript">
        var module = angular.module('gn_editor');
        module.config(['gnViewerSettings', 'gnGlobalSettings',
                function(gnViewerSettings, gnGlobalSettings) {
          <xsl:if test="$owsContext">
            gnViewerSettings.owsContext = '<xsl:value-of select="$owsContext"/>';
          </xsl:if>
          <xsl:if test="$wmsUrl and $layerName">
            gnViewerSettings.wmsUrl = '<xsl:value-of select="$wmsUrl"/>';
            gnViewerSettings.layerName = '<xsl:value-of select="$layerName"/>';
          </xsl:if>
          gnViewerSettings.mapConfig = <xsl:value-of select="$mapConfig"/>;
          gnGlobalSettings.isMapViewerEnabled = <xsl:value-of select="$isMapViewerEnabled"/>;
        }]);
      </script>
    </xsl:if>
    
    <xsl:if test="$angularApp = 'gn_editor'">
      <script type="text/javascript">
        var module = angular.module('gn_editor');
        module.config(['gnViewerSettings', 'gnGlobalSettings',
                function(gnViewerSettings, gnGlobalSettings) {
          <xsl:if test="$owsContext">
            gnViewerSettings.owsContext = '<xsl:value-of select="$owsContext"/>';
          </xsl:if>
          <xsl:if test="$wmsUrl and $layerName">
            gnViewerSettings.wmsUrl = '<xsl:value-of select="$wmsUrl"/>';
            gnViewerSettings.layerName = '<xsl:value-of select="$layerName"/>';
          </xsl:if>
          gnViewerSettings.mapConfig = <xsl:value-of select="$mapConfig"/>;
          gnGlobalSettings.isMapViewerEnabled = <xsl:value-of select="$isMapViewerEnabled"/>;
        }]);
      </script>
    </xsl:if>

    <!--geocatch specific settings initialization-->
    <xsl:if test="$searchView = 'geocat' and $angularApp = 'gn_search'">
      <script type="text/javascript">
        var module = angular.module('gn_search');
        module.config(['gnSearchSettings', function(gnSearchSettings) {
        gnSearchSettings.geoserverUrl = '<xsl:value-of select="/root/gui/config/geoserver.url"/>';
        gnSearchSettings.permlink = '<xsl:value-of select="/root/gui/strings/permlink"/>';
        gnSearchSettings.mapConfig = <xsl:value-of select="/root/gui/env/map/config"/>;
        gnSearchSettings.gnStores = {
        'topicCat': [['', '<xsl:value-of select="/root/gui/strings/any"/>']<xsl:apply-templates select="/root/gui/schemas/iso19139/codelists/codelist[@name='gmd:MD_TopicCategoryCode']/entry" mode="js-translations-topicCat"/>],
        'sources_groups': [<xsl:apply-templates select="/root/gui/groups/record" mode="js-translations-sources-groups"><xsl:sort select="label/*[name()=/root/gui/language]"/><xsl:sort select="name"/></xsl:apply-templates><xsl:if
              test="count(/root/gui/groups/record) > 0 and count(/root/gui/sources/record) > 0">,</xsl:if><xsl:apply-templates select="/root/gui/sources/record[not(./siteid = preceding::record/siteid)]" mode="js-translations-sources-groups"><xsl:sort select="label/*[name()=/root/gui/language]"/><xsl:sort select="name"/></xsl:apply-templates>],
        'formats': [['', '<xsl:value-of select="/root/gui/strings/any"/>']<xsl:apply-templates select="/root/gui/formats/record" mode="js-translations-formats"/>]
        };
        }]);
      </script>
    </xsl:if>
    <!--enf of geocatch specific settings initialization-->

    
    <xsl:if test="$angularApp = 'gn_admin'">
      <script type="text/javascript">
        var module = angular.module('gn_admin');
        module.config(['gnGlobalSettings',
                function(gnGlobalSettings) {
          gnGlobalSettings.isMapViewerEnabled = <xsl:value-of select="$isMapViewerEnabled"/>;
        }]);
      </script>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*" mode="js-translations-combo-suite">
    ,["<xsl:value-of select="@value"/><xsl:value-of select="@id"/>", "<xsl:value-of select="."/>"]</xsl:template>

  <xsl:template match="*" mode="js-translations-combo">
    <xsl:if test="position()>1">,</xsl:if>["<xsl:value-of select="@value"/><xsl:value-of select="@id"/>", "<xsl:value-of select="."/>"]</xsl:template>

  <xsl:template match="entry" mode="js-translations-topicCat">
    ,["<xsl:value-of select="code"/>", "<xsl:value-of select="label"/>"]</xsl:template>

  <xsl:template match="record" mode="js-translations-sources-groups">
    <xsl:if test="position()>1">,</xsl:if>
    <xsl:choose>
      <xsl:when test="siteid">["_source/<xsl:value-of select="siteid"/>", "<xsl:value-of select="normalize-space(replace(translate(name,'&quot;', '`'), '[\n\r]+', ' '))"/>"</xsl:when>
      <xsl:otherwise>["_groupOwner/<xsl:value-of select="id"/>", "<xsl:value-of select="normalize-space(replace(translate(label/*[name()=/root/gui/language],'&quot;', '`'), '[\n\r]+', ' '))"/>"
      </xsl:otherwise>
    </xsl:choose>]
  </xsl:template>

  <xsl:template match="record" mode="js-translations-formats">
    ,["<xsl:value-of select="name"/><xsl:if test="version != '-'">_<xsl:value-of select="version"/></xsl:if>", "<xsl:value-of select="name"/> (<xsl:value-of select="version"/>)"]</xsl:template>

</xsl:stylesheet>
