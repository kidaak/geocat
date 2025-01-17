//==============================================================================
//===	Copyright (C) 2001-2008 Food and Agriculture Organization of the
//===	United Nations (FAO-UN), United Nations World Food Programme (WFP)
//===	and United Nations Environment Programme (UNEP)
//===
//===	This program is free software; you can redistribute it and/or modify
//===	it under the terms of the GNU General Public License as published by
//===	the Free Software Foundation; either version 2 of the License, or (at
//===	your option) any later version.
//===
//===	This program is distributed in the hope that it will be useful, but
//===	WITHOUT ANY WARRANTY; without even the implied warranty of
//===	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//===	General Public License for more details.
//===
//===	You should have received a copy of the GNU General Public License
//===	along with this program; if not, write to the Free Software
//===	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
//===
//===	Contact: Jeroen Ticheler - FAO - Viale delle Terme di Caracalla 2,
//===	Rome - Italy. email: geonetwork@osgeo.org
//==============================================================================

package org.fao.geonet.geocat.services.extent;


import com.google.common.collect.Sets;
import jeeves.interfaces.Service;
import jeeves.server.ServiceConfig;
import jeeves.server.context.ServiceContext;
import org.fao.geonet.Util;
import org.fao.geonet.domain.Pair;
import org.fao.geonet.geocat.kernel.extent.ExtentFormat;
import org.fao.geonet.geocat.kernel.extent.ExtentHelper;
import org.fao.geonet.geocat.kernel.extent.ExtentManager;
import org.fao.geonet.geocat.kernel.extent.ExtentSelection;
import org.fao.geonet.geocat.kernel.extent.FeatureType;
import org.fao.geonet.geocat.kernel.extent.Source;
import org.fao.geonet.geocat.kernel.reusable.ExtentsStrategy;
import org.fao.geonet.utils.Xml;
import org.geotools.data.DataStore;
import org.geotools.data.FeatureSource;
import org.geotools.data.Query;
import org.geotools.feature.FeatureIterator;
import org.jdom.Element;
import org.jdom.JDOMException;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;

import java.io.IOException;
import java.nio.file.Path;
import java.util.AbstractCollection;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashSet;

import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.DESC;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.DESC_COLUMN;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.FEATURE;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.FEATURE_TYPE;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.GEO_ID;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.GEO_ID_COLUMN;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.ID;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.ID_COLUMN;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.MODIFIABLE_FEATURE_TYPE;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.NUM_RESULTS;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.RESPONSE;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.SELECTED;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.SOURCE;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.TYPENAME;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.error;
import static org.fao.geonet.geocat.kernel.extent.ExtentHelper.getSelection;

/**
 * List all the available extents
 *
 * @author jeichar
 */
public class List implements Service {

    private static final class AllCollection extends AbstractCollection<String> {
        private Collection<?> restricted;

        @Override
        public boolean contains(Object o) {
            if (restricted == null) {
                return true;
            } else {
                return this.restricted.contains(o);
            }

        }

        @Override
        public Iterator<String> iterator() {
            return null;
        }

        @Override
        public boolean retainAll(Collection<?> c) {
            restricted = c;
            return true;
        }

        @Override
        public int size() {
            return 0;
        }
    }

    private static final String HREF = "href";
    private Collection<String> defaultTypesToShow;
    private int maxFeatures;

    public void init(Path appPath, ServiceConfig params) throws Exception {
        java.util.List<Element> types = params.getChildren("typename");
        if (types != null) {
            defaultTypesToShow = new LinkedHashSet<String>();
            for (Element type : types) {
                defaultTypesToShow.add(type.getTextTrim());
            }
        }
        final String max = params.getValue("max", String.valueOf(Integer.MAX_VALUE));
        this.maxFeatures = Integer.parseInt(max);
    }

    /**
     * Returns a string if the parameters are not acceptable. This version
     * returns null (no error)
     */
    protected String validateParams(Element params) {
        return null;
    }

    public Element exec(Element params, ServiceContext context) throws Exception {
        Util.toLowerCase(params);
        final String paramError = validateParams(params);
        if (paramError != null) {
            return error(paramError);
        }
        final ExtentManager extentMan = context.getBean(ExtentManager.class);

        final String typenameParam = Util.getParamText(params, TYPENAME);

        ExtentFormat format = ExtentFormat.lookup(Util.getParamText(params, "format"));

        Collection<String> typesToShow = new AllCollection();
        if (typenameParam != null) {
            typesToShow = Sets.newLinkedHashSet(Arrays.asList(typenameParam.split(",")));
        }
        if (this.defaultTypesToShow != null) {
            typesToShow.retainAll(this.defaultTypesToShow);
        }
        final Element result = new Element(RESPONSE);

        Page page = new Page(params);

        final Source wfs = extentMan.getSource();
        final Element wfsElem = new Element(SOURCE);
        wfsElem.setAttribute(ID, wfs.wfsId);

        boolean hasMore = false;
        final DataStore ds = wfs.getDataStore();
        for (final FeatureType featureType : wfs.getFeatureTypes()) {
            if (typesToShow.contains(featureType.typename)) {
                hasMore = listFeatureType(params, context, wfs, wfsElem, ds, featureType, page, format);
                if (page.limitReached()) {
                    break;
                }
            }
        }

        Element hasMoreElem = new Element("hasMore");
        result.addContent(hasMoreElem);
        hasMoreElem.setText(String.valueOf(hasMore));

        if (wfsElem.getChildren().size() > 0) {
            result.addContent(wfsElem);
        }

        return result;
    }

    private final boolean listFeatureType(Element params, ServiceContext context, Source wfs, Element wfsElem,
                                          DataStore ds, FeatureType featureType, Page page, ExtentFormat format) throws Exception {
        final FeatureSource<SimpleFeatureType, SimpleFeature> featureSource = featureType.getFeatureSource();
        final String modifiable = String.valueOf(featureType.isModifiable());

        final String baseURL = context.getBaseUrl();
        final String langCode = context.getLanguage();

        final Element typeElem = new Element(FEATURE_TYPE);
        typeElem.setAttribute(TYPENAME, featureType.typename);
        typeElem.setAttribute(ID_COLUMN, featureType.idColumn);
        typeElem.setAttribute(MODIFIABLE_FEATURE_TYPE, modifiable);
        typeElem.setAttribute(DESC_COLUMN, featureType.descColumn);
        typeElem.setAttribute(GEO_ID_COLUMN, featureType.geoIdColumn);

        java.util.Set<String> properties = new HashSet<String>();

        properties.add(featureType.idColumn);
        if (featureType.descColumn != null) {
            properties.add(featureType.descColumn);
        }

        if (featureType.geoIdColumn != null && !DESC_COLUMN.equals(GEO_ID_COLUMN)) {
            properties.add(featureType.geoIdColumn);
        }

        final Query query = createQuery(params, featureType, properties.toArray(new String[0]), maxFeatures);
        final FeatureIterator<SimpleFeature> features = featureSource.getFeatures(query).features();
        final ExtentSelection selection = getSelection(context);

        try {
            while (features.hasNext() && !page.limitReached()) {
                final SimpleFeature next = features.next();
                if (page.canAddFeature(next)) {
                    createFeatureElem(wfs, featureType, baseURL, langCode, typeElem, selection, next, format);
                }
                page.inc();
            }
            wfsElem.addContent(typeElem);
            return features.hasNext();
        } finally {
            features.close();
        }

    }

    private void createFeatureElem(Source wfs, FeatureType featureType, final String baseURL, final String langCode,
                                   final Element typeElem, final ExtentSelection selection, final SimpleFeature next, ExtentFormat format)
            throws IOException, JDOMException {
        final Element featureElem = new Element(FEATURE);
        String id = next.getAttribute(featureType.idColumn).toString();
        try {
            int intId = (int) Double.parseDouble(id);
            id = String.valueOf(intId);
        } catch (NumberFormatException e) {
            // ignore
        }
        featureElem.setAttribute(ID, id);

        final boolean selected;
        synchronized (selection.getIds()) {
            selected = selection.getIds().contains(Pair.read(featureType, id));
        }
        featureElem.setAttribute(SELECTED, String.valueOf(selected));

        final String href = ExtentsStrategy.baseHref(id, wfs.wfsId, featureType.typename) + "&format=" + format;
        featureElem.setAttribute(HREF, href);
        if (featureType.descColumn != null) {
            String descAt = ExtentHelper.decodeDescription((String) next.getAttribute(featureType.descColumn));
            final Element desc = Xml.loadString("<" + DESC + ">" + descAt + "</" + DESC + ">", false);
            featureElem.addContent(desc);

        }
        if (featureType.geoIdColumn != null) {
            String geoIdAt = ExtentHelper.decodeDescription((String) next.getAttribute(featureType.geoIdColumn));
            if (geoIdAt == null)
                geoIdAt = "";
            final Element geoId = Xml.loadString("<" + GEO_ID + ">" + geoIdAt + "</" + GEO_ID + ">", false);
            featureElem.addContent(geoId);
        }
        typeElem.addContent(featureElem);
    }

    protected Query createQuery(Element params, FeatureType featureType, String[] properties, int maxFeatures)
            throws Exception {
        final Query defaultQuery = featureType.createQuery(properties);
        defaultQuery.setMaxFeatures(maxFeatures);
        return defaultQuery;
    }

    private final class Page {
        final int startOfPage, endOfPage;
        int currentCount = 0;

        public Page(Element params) {
            final String maxParam = Util.getParamText(params, NUM_RESULTS);

            final int maxFeatures;
            if (maxParam != null) {
                maxFeatures = Integer.parseInt(maxParam);
            } else {
                maxFeatures = List.this.maxFeatures;
            }

            final String pageParam = Util.getParamText(params, "page");
            int page;
            try {
                page = Integer.parseInt(pageParam);
            } catch (Exception e) {
                page = 1;
            }

            startOfPage = (page - 1) * maxFeatures;
            endOfPage = page * maxFeatures;
        }

        public void inc() {
            currentCount++;
        }

        public boolean canAddFeature(SimpleFeature next) {
            return startOfPage <= currentCount && currentCount < endOfPage;
        }

        public boolean limitReached() {
            return endOfPage <= currentCount;
        }
    }

}
