(function() {
  goog.provide('gn_map_service');

  goog.require('gn_ows');


  var module = angular.module('gn_map_service', [
    'gn_ows',
    'ngeo'
  ]);

  module.provider('gnMap', function() {
    this.$get = [
      'ngeoDecorateLayer',
      'gnOwsCapabilities',
      'gnConfig',
      '$log',
      'gnSearchLocation',
      '$rootScope',
      'gnUrlUtils',
      '$q',
      '$translate',
      'gnWmsQueue',
      'gnSearchManagerService',
      'Metadata',
      function(ngeoDecorateLayer, gnOwsCapabilities, gnConfig, $log, 
          gnSearchLocation, $rootScope, gnUrlUtils, $q, $translate,
          gnWmsQueue, gnSearchManagerService, Metadata) {

        var defaultMapConfig = {
          'useOSM': 'true',
          'projection': 'EPSG:3857',
          'projectionList': [{
            'code': 'EPSG:4326',
            'label': 'WGS84 (EPSG:4326)'
          },{
            'code': 'EPSG:3857',
            'label': 'Google mercator (EPSG:3857)'
          }]
        };

        return {

          importProj4js: function() {
            proj4.defs("EPSG:2154","+proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs");
            proj4.defs("EPSG:21781","+proj=somerc +lat_0=46.95240555555556 +lon_0=7.439583333333333 +k_0=1 +x_0=600000 +y_0=200000 +ellps=bessel +towgs84=660.077,13.551,369.344,2.484,1.783,2.939,5.66 +units=m +no_defs");
            if (proj4 && angular.isArray(gnConfig['map.proj4js'])) {
              angular.forEach(gnConfig['map.proj4js'], function(item) {
                proj4.defs(item.code, item.value);
              });
            }
          },

          /**
           * Reproject a given extent. Extent is an object
           * defined as
           * {left,bottom,right,top}
           *
           */
          reprojExtent: function(extent, src, dest) {
            if (src == dest || extent === null) {
              return extent;
            }
            else {
              return ol.proj.transformExtent(extent,
                  src, dest);
            }
          },

          isPoint: function(extent) {
            return (extent[0] == extent[2] &&
                extent[1]) == extent[3];
          },

          getPolygonFromExtent: function(extent) {
            return [
                    [
                     [extent[0], extent[1]],
                     [extent[0], extent[3]],
                     [extent[2], extent[3]],
                     [extent[2], extent[1]],
                     [extent[0], extent[1]]
              ]
            ];
          },

          /**
           * Get the extent of the md.
           * It is stored in the object md.geoBox as a String
           * '150|-12|160|12'.
           * Returns it as an array of floats.
           *
           * @param {Object} md
           */
          getBboxFromMd: function(md) {
            if (angular.isUndefined(md.geoBox)) return;

            var bbox = angular.isArray(md.geoBox) ?
                md.geoBox[0] : md.geoBox;
            var c = bbox.split('|');
            if (angular.isArray(c) && c.length == 4) {
              return [parseFloat(c[0]),
                parseFloat(c[1]),
                parseFloat(c[2]),
                parseFloat(c[3])];
            }
          },

          /**
           * Convert coordinates object into text
           *
           * @param {Array} coord must be an array of points (array with
           * dimension 2) or a point
           * @return {String} coordinates as text with format :
           * 'x1 y1,x2 y2,x3 y3'
           */
          getTextFromCoordinates: function(coord) {
            var text;

            var addPointToText = function(point) {
              if (text) {
                text += ',';
              }
              else {
                text = '';
              }
              text += point[0] + ' ' + point[1];
            };

            if (angular.isArray(coord) && coord.length > 0) {
              if (angular.isArray(coord[0])) {
                for (var i = 0; i < coord.length; ++i) {
                  var point = coord[i];
                  if (angular.isArray(point) && point.length == 2) {
                    addPointToText(point);
                  }
                }
              } else if (coord.length == 2) {
                addPointToText(coord);
              }
            }
            return text;
          },

          getMapConfig: function() {
            if (gnConfig['map.config'] &&
                angular.isObject(gnConfig['map.config'])) {
              return gnConfig['map.config'];
            } else {
              return defaultMapConfig;
            }
          },

          getLayersFromConfig: function() {
            var conf = this.getMapConfig();
            var source;

            if (conf.useOSM) {
              source = new ol.source.OSM();
            }
            else {
              source = new ol.source.TileWMS({
                url: conf.layer.url,
                params: {'LAYERS': conf.layer.layers,
                  'VERSION': conf.layer.version}
              });
            }
            return new ol.layer.Tile({
              source: source
            });
          },

          /**
           * Check if the extent is valid or not.
           */
          isValidExtent: function(extent) {
            var valid = true;
            if (extent && angular.isArray(extent)) {
              angular.forEach(extent, function(value, key) {
                if (!value || value == Infinity || value == -Infinity) {
                  valid = false;
                }
              });
            }
            else {
              valid = false;
            }
            return valid;
          },

          /**
           * Transform map extent into dublin-core schema for
           * dc:coverage metadata element.
           * Ex :
           * North 90, South -90, East 180, West -180
           * or
           * North 90, South -90, East 180, West -180. Global
           */
          getDcExtent: function(extent) {
            if (angular.isArray(extent)) {
              var dc = 'North ' + extent[3] + ', ' +
                  'South ' + extent[1] + ', ' +
                  'East ' + extent[0] + ', ' +
                  'West ' + extent[2];
              if (location) {
                dc += '. ' + location;
              }
              return dc;
            } else {
              return '';
            }
          },

          addKmlToMap: function(name, url, map) {
            if (!url || url == '') {
              return;
            }

            var proxyUrl = '../../proxy?url=' + encodeURIComponent(url);
            var kmlSource = new ol.source.KML({
              projection: map.getView().getProjection(),
              url: proxyUrl
            });

            var vector = new ol.layer.Vector({
              source: kmlSource,
              label: name
            });

            ngeoDecorateLayer(vector);
            vector.displayInLayerManager = true;
            map.getLayers().push(vector);
          },

          // Given only the url, it will show a dialog to select
          // what layers do we want to add to the map
          addOwsServiceToMap: function(url, type) {
            // move to map
            gnSearchLocation.setMap();
            // open dialog for WMS
            $rootScope.$broadcast('requestCapLoad' + type.toUpperCase(), url);
          },

          createOlWMS: function(map, layerParams, layerOptions, index) {

            var options = layerOptions || {};

            var source = new ol.source.TileWMS({
              params: layerParams,
              url: options.url
            });

            var olLayer = new ol.layer.Tile({
              url: options.url,
              type: 'WMS',
              opacity: options.opacity,
              visible: options.visible,
              source: source,
              legend: options.legend,
              attribution: options.attribution,
              label: options.label,
              group: options.group,
              isNcwms: options.isNcwms,
              cextent: options.extent
            });

            if (options.metadata) {
              olLayer.set('metadataUrl', options.metadata);
              var params = gnUrlUtils.parseKeyValue(
                  options.metadata.split('?')[1]);
              var uuid = params.uuid || params.id;
              if (uuid) {
                olLayer.set('metadataUuid', uuid);
              }
            }
            ngeoDecorateLayer(olLayer);
            olLayer.displayInLayerManager = true;

            // Specific geocat : don't need this as there is no map viewer
/*
            var unregisterEventKey = olLayer.getSource().on('tileloaderror',
                function(tileEvent, target) {
                  var msg = $translate('layerTileLoadError', {
                    url: tileEvent.tile && tileEvent.tile.getKey ?
                        tileEvent.tile.getKey() : '- no tile URL found-',
                    layer: tileEvent.currentTarget &&
                        tileEvent.currentTarget.getParams ?
                        tileEvent.currentTarget.getParams().LAYERS :
                        layerParams.LAYERS
                  });
                  console.warn(msg);
                  $rootScope.$broadcast('StatusUpdated', {
                    msg: msg,
                    timeout: 0,
                    type: 'danger'});
                  olLayer.get('errors').push(msg);
                  olLayer.getSource().unByKey(unregisterEventKey);
                });
*/
            return olLayer;
          },

          /**
           * Parse an object describing a layer from
           * a getCapabilities document parsing. Create a ol.Layer WMS
           * from this object and add it to the map with all known
           * properties.
           *
           * @param {ol.map} map
           * @param {Object} getCapLayer
           * @return {*}
           */
          createOlWMSFromCap: function(map, getCapLayer, layerCoreInfo) {

            var legend, attribution, metadata, errors = [];
            if (getCapLayer) {
              var layer = getCapLayer;

              var isLayerAvailableInMapProjection = false;
              // OL3 only parse CRS from WMS 1.3 (and not SRS in WMS 1.1.x)
              // so a WMS 1.1.x will always failed on this
              // https://github.com/openlayers/ol3/blob/master/src/
              // ol/format/wmscapabilitiesformat.js
              if (layer.CRS) {
                var mapProjection = map.getView().getProjection().getCode();
                for (var i = 0; i < layer.CRS.length; i++) {
                  if (layer.CRS[i] === mapProjection) {
                    isLayerAvailableInMapProjection = true;
                    break;
                  }
                }
              } else {
                errors.push($translate('layerCRSNotFound'));
                console.warn($translate('layerCRSNotFound'));
              }
              if (!isLayerAvailableInMapProjection) {
                errors.push($translate('layerNotAvailableInMapProj'));
                console.warn($translate('layerNotAvailableInMapProj'));
              }

              // TODO: parse better legend & attribution
              if (angular.isArray(layer.Style) && layer.Style.length > 0) {
                legend = layer.Style[layer.Style.length - 1]
                    .LegendURL[0].OnlineResource;
              }
              if (angular.isDefined(layer.Attribution)) {
                if (angular.isArray(layer.Attribution)) {

                } else {
                  attribution = layer.Attribution.Title;
                }
              }
              if (angular.isArray(layer.MetadataURL)) {
                metadata = layer.MetadataURL[0].OnlineResource;
              }
              var isNcwms = false;
              if (angular.isArray(layer.Dimension)) {
                for (var i = 0; i < layer.Dimension.length; i++) {
                  if (layer.Dimension[i].name == 'elevation') {
                    isNcwms = true;
                    break;
                  }
                }
              }

              var layer = this.createOlWMS(map, {
                LAYERS: layer.Name
              }, {
                url: layer.url,
                label: layer.Title,
                attribution: attribution,
                legend: legend,
                group: layer.group,
                metadata: metadata,
                isNcwms: isNcwms,
                extent: gnOwsCapabilities.getLayerExtentFromGetCap(map, layer)
              }
              );
              layer.set('errors', errors);
              return layer;
            }

          },
          addWmsToMapFromCap: function(map, getCapLayer) {
            var layer = this.createOlWMSFromCap(map, getCapLayer);
            map.addLayer(layer);
            return layer;
          },
          addWmsToMap: function(map, layerInfo) {
            if (layerInfo) {
              var layer = this.createOlWMS(map, {
                LAYERS: layerInfo.name
              }, {
                url: layerInfo.url,
                label: layerInfo.name
              }
              );
              map.addLayer(layer);
              return layer;
            }
          },
          addWmtsToMapFromCap: function(map, getCapLayer) {
            map.addLayer(this.createOlWMTSFromCap(map, getCapLayer));
          },

          /**
           * Here is the method to use when you want to add a wms layer from
           * a url and a layername. It will call the WMS getCapabilities,
           * create the ol.Layer with maximum info we got from capabilities,
           * then add the layer to the map.
           *
           * If the layer is not found in the capability, a simple WMS layer
           * based on the name only will be created.
           *
           * Return a promise with ol.Layer as data is succeed, and url/name
           * if failure.
           * If createOnly, we don't add the layer to the map.
           * If the md object is given, we add it to the layer, or we try
           * to retrieve it in the catalog
           *
           * @param {ol.Map} map
           * @param {string} url
           * @param {string} name
           * @param {boolean} createOnly
           * @param {!Object} md
           */
          addWmsFromScratch: function(map, url, name, createOnly, md) {
            var defer = $q.defer();
            var $this = this;

            gnWmsQueue.add(url, name);
            gnOwsCapabilities.getWMSCapabilities(url).then(function(capObj) {
              var capL = gnOwsCapabilities.getLayerInfoFromCap(name, capObj),
                  olL;
              if (!capL) {
                // If layer not found in the GetCapabilities
                // Try to add the layer from the metadata
                // information only. A tile error loading
                // may be reported after the layer is added
                // to the map and will give more details.
                var o = {
                  url: url,
                  name: name,
                  msg: 'layerNotInCap'
                }, errors = [];
                olL = $this.addWmsToMap(map, o);

                if (!angular.isArray(olL.get('errors'))) {
                  olL.set('errors', []);
                }
                var errormsg = $translate('layerNotfoundInCapability', {
                  layer: name,
                  url: url
                });
                errors.push(errormsg);
                console.warn(errormsg);

                olL.get('errors').push(errors);

                gnWmsQueue.error(o);
                defer.reject(o);
              } else {
                if (createOnly) {
                  olL = $this.createOlWMTSFromCap(map, capL);
                } else {
                  olL = $this.addWmsToMapFromCap(map, capL);
                }

                // attach the md object to the layer
                if (md) {
                  olL.set('md', md);
                }
                else {
                  $this.feedLayerMd(olL);
                }

                gnWmsQueue.removeFromQueue(url, name);
                defer.resolve(olL);
              }

            }, function() {
              var o = {
                url: url,
                name: name,
                msg: 'getCapFailure'
              };
              gnWmsQueue.error(o);
              defer.reject(o);
            });
            return defer.promise;
          },

          addWmtsFromScratch: function(map, url, name, createOnly) {
            var defer = $q.defer();
            var $this = this;

            gnWmsQueue.add(url, name);
            gnOwsCapabilities.getWMTSCapabilities(url).then(function(capObj) {

              var capL = gnOwsCapabilities.getLayerInfoFromCap(name, capObj);
              if (!capL) {
                var o = {
                  url: url,
                  name: name,
                  msg: 'layerNotInCap'
                };
                gnWmsQueue.error(o);
                defer.reject(o);
              }
              else {
                var olL = $this.createOlWMTSFromCap(map, capL, capObj);
                if (!createOnly) {
                  map.addLayer(olL);
                }
                gnWmsQueue.removeFromQueue(url, name);
                defer.resolve(olL);
              }
            }, function() {
              var o = {
                url: url,
                name: name,
                msg: 'getCapFailure'
              };
              gnWmsQueue.error(o);
              defer.reject(o);
            });
            return defer.promise;
          },

          /**
           * Parse an object describing a layer from
           * a getCapabilities document parsing. Create a ol.Layer WMS
           * from this object and add it to the map with all known
           * properties.
           *
           * @param {ol.map} map
           * @param {Object} getCapLayer
           * @return {*}
           */
          createOlWMTSFromCap: function(map, getCapLayer, capabilities) {

            var legend, attribution, metadata;
            if (getCapLayer) {
              var layer = getCapLayer;

              var url, urls = capabilities.operationsMetadata.GetTile.
                  DCP.HTTP.Get;

              for (var i = 0; i < urls.length; i++) {
                if (urls[i].Constraint[0].AllowedValues.Value[0].
                    toLowerCase() == 'kvp') {
                  url = urls[i].href;
                  break;
                }
              }

              var urlCap = capabilities.operationsMetadata.GetCapabilities.
                  DCP.HTTP.Get[0].href;

              var style = layer.Style[0].Identifier;

              var projection = map.getView().getProjection();

              // Try to guess which matrixId to use depending projection
              var matrixSetsId;
              for (var i = 0; i < layer.TileMatrixSetLink.length; i++) {
                if (layer.TileMatrixSetLink[i].TileMatrixSet ==
                    projection.getCode()) {
                  matrixSetsId = layer.TileMatrixSetLink[i].TileMatrixSet;
                  break;
                }
              }
              if (!matrixSetsId) {
                matrixSetsId = layer.TileMatrixSetLink[0].TileMatrixSet;
              }

              var matrixSet;
              for (var i = 0; i < capabilities.TileMatrixSet.length; i++) {
                if (capabilities.TileMatrixSet[i].Identifier == matrixSetsId) {
                  matrixSet = capabilities.TileMatrixSet[i];
                }
              }
              var nbMatrix = matrixSet.TileMatrix.length;

              var projectionExtent = projection.getExtent();
              var resolutions = new Array(nbMatrix);
              var matrixIds = new Array(nbMatrix);
              for (var z = 0; z < nbMatrix; ++z) {
                var matrix = matrixSet.TileMatrix[z];
                var size = ol.extent.getWidth(projectionExtent) /
                    matrix.TileWidth;
                resolutions[z] = matrix.ScaleDenominator * 0.00028 /
                    projection.getMetersPerUnit();
                matrixIds[z] = matrix.Identifier;
              }

              var source = new ol.source.WMTS({
                url: url,
                layer: layer.Identifier,
                matrixSet: matrixSet.Identifier,
                format: layer.Format[0] || 'image/png',
                projection: projection,
                tileGrid: new ol.tilegrid.WMTS({
                  origin: ol.extent.getTopLeft(projection.getExtent()),
                  resolutions: resolutions,
                  matrixIds: matrixIds
                }),
                style: style
              });

              var olLayer = new ol.layer.Tile({
                extent: projection.getExtent(),
                name: layer.Identifier,
                title: layer.Title,
                label: layer.Title,
                source: source,
                url: url,
                urlCap: urlCap
              });
              ngeoDecorateLayer(olLayer);
              olLayer.displayInLayerManager = true;

              return olLayer;
            }
          },

          addWmtsToMapFromCap: function(map, getCapLayer, capabilities) {
            map.addLayer(this.createOlWMTSFromCap(map,
                getCapLayer, capabilities));
          },

          /**
           * Zoom by delta with animation
           * @param {ol.map} map
           * @param {float} delta
           */
          zoom: function(map, delta) {
            var view = map.getView();
            var currentResolution = view.getResolution();
            if (angular.isDefined(currentResolution)) {
              map.beforeRender(ol.animation.zoom({
                resolution: currentResolution,
                duration: 250,
                easing: ol.easing.easeOut
              }));
              var newResolution = view.constrainResolution(
                  currentResolution, delta);
              view.setResolution(newResolution);
            }
          },

          /**
           * Zoom map to the layer extent if defined. The layer extent
           * is gotten from capabilities and store in cextent property
           * of the layer.
           * @param {ol.Layer} layer
           * @param {ol.map} map
           */
          zoomLayerToExtent: function(layer, map) {
            if (layer.get('cextent')) {
              map.getView().fitExtent(layer.get('cextent'), map.getSize());
            }
          },


          /**
           * Creates an ol.layer for a given type. Useful for contexts
           * @param {string} type
           * @param {Object} opt for url or layer name
           * @return {ol.layer}
           */
          createLayerForType: function(type, opt) {
            switch (type) {
              case 'mapquest':
                return new ol.layer.Tile({
                  style: 'Road',
                  source: new ol.source.MapQuest({layer: 'osm'}),
                  title: 'MapQuest'
                });
              case 'osm':
                return new ol.layer.Tile({
                  source: new ol.source.OSM(),
                  title: 'OpenStreetMap'
                });
              case 'bing_aerial':
                return new ol.layer.Tile({
                  preload: Infinity,
                  source: new ol.source.BingMaps({
                    key: 'Ak-dzM4wZjSqTlzveKz5u0d4I' +
                        'Q4bRzVI309GxmkgSVr1ewS6iPSrOvOKhA-CJlm3',
                    imagerySet: 'Aerial'
                  }),
                  title: 'Bing Aerial'
                });
              case 'wmts':
                var that = this;
                if (opt.name && opt.url) {
                    gnOwsCapabilities.getWMTSCapabilities(opt.url).
                        then(function(capObj) {
                          var info = gnOwsCapabilities.getLayerInfoFromCap(
                              opt.name, capObj);
                          //info.group = layer.group;
                        return that.addWmtsToMapFromCap(undefined, info,
                            capObj);
/*
                          l.setOpacity(layer.opacity);
                          l.setVisible(!layer.hidden);
*/
                        });
                  }
                else {
                    console.warn('cant load wmts, url or name not provided');
                  }
            }
            $log.warn('Unsupported layer type: ', type);
          },

          /**
           * Check if the layer is in the map to avoid adding duplicated ones.
           * @param {ol.Map} map
           * @param {string} name
           * @param {string} url
           */
          isLayerInMap: function(map, name, url) {
            if (gnWmsQueue.isPending(url, name)) {
              return true;
            }
            for (var i = 0; i < map.getLayers().getLength(); i++) {
              var l = map.getLayers().item(i);
              var source = l.getSource();
              if (source instanceof ol.source.WMTS &&
                  l.get('url') == url) {
                if (l.get('name') == name) {
                  return true;
                }
              }
              else if (source instanceof ol.source.TileWMS) {
                if (source.getParams().LAYERS == name &&
                    l.get('url').split('?')[0] == url.split('?')[0]) {
                  return true;
                }
              }
            }
            return false;
          },

          /**
           * If the layer contains a metadataUrl, we check if it is on
           * the same host as the catalog, if yes i search for this md in
           * the catalog and bind it to the layer.
           * @param {ol.Layer} layer
           */
          feedLayerMd: function(layer) {
            if (layer.get('metadataUrl')) {

              var mdUrl = gnUrlUtils.urlResolve(layer.get('metadataUrl'));
              if (mdUrl.host == gnSearchLocation.host()) {
                gnSearchManagerService.gnSearch({
                  uuid: layer.get('metadataUuid'),
                  fast: 'index',
                  _content_type: 'json'
                }).then(function(data) {
                  if (data.metadata.length == 1) {
                    layer.set('md', new Metadata(data.metadata[0]));
                  }
                });
              }
            }
          }

        };
      }];
  });

  module.provider('gnLayerFilters', function() {
    this.$get = function() {
      return {
        /**
         * Filters out background layers, preview
         * layers, draw, measure.
         * In other words, all layers that
         * were actively added by the user and that
         * appear in the layer manager
         */
        selected: function(layer) {
          return layer.displayInLayerManager;
        },
        visible: function(layer) {
          return layer.displayInLayerManager && layer.visible;
        }
      };
    };
  });


})();
