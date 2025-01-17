//=============================================================================
//===	Copyright (C) 2001-2007 Food and Agriculture Organization of the
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

package org.fao.geonet.guiservices.util;

import jeeves.interfaces.Service;
import jeeves.server.ServiceConfig;
import jeeves.server.context.ServiceContext;
import org.fao.geonet.GeonetContext;
import org.fao.geonet.constants.Geonet;
import org.fao.geonet.kernel.setting.HarvesterSettingsManager;
import org.fao.geonet.kernel.setting.SettingManager;
import org.fao.geonet.repository.SourceRepository;
import org.fao.geonet.utils.Xml;
import org.jdom.Element;

import java.nio.file.Path;

//=============================================================================

public class Sources implements Service
{
	public void init(Path appPath, ServiceConfig params) throws Exception {}

	//--------------------------------------------------------------------------
	//---
	//--- Service
	//---
	//--------------------------------------------------------------------------

	public Element exec(Element params, ServiceContext context) throws Exception
	{
		GeonetContext  gc = (GeonetContext) context.getHandlerContext(Geonet.CONTEXT_NAME);
		SettingManager sm =gc.getBean(SettingManager.class);

		//--- create local node

		String name   = sm.getSiteName();
		String siteId = sm.getSiteId();
        String url = sm.getSiteURL(context);

		Element local = new Element("record");

		local.addContent(new Element("name")  .setText(name));
		local.addContent(new Element("siteid").setText(siteId));
		local.addContent(new Element("url").setText(url));

		//--- retrieve known nodes
        final Element asXml = context.getBean(SourceRepository.class).findAllAsXml();
        asXml.addContent(local);

        // GEOCAT
        final HarvesterSettingsManager bean = context.getBean(HarvesterSettingsManager.class);

        Element harvestingNodes = bean.get("harvestingy", -1);

        for (Object obj : asXml.getChildren()) {
            Element record = (Element) obj;
            siteId = record.getChildTextTrim("siteid");
            url = Xml.selectString(harvestingNodes, "*//site[.//uuid/value/text() = '" + siteId + "']//url/value/text()");
            if(url != null) {
                record.addContent(new Element("url").setText(url));
            }
        }
        // END GEOCAT

		return asXml;
	}
}

//=============================================================================

