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

package org.fao.geonet.services.metadata;

import jeeves.server.ServiceConfig;
import jeeves.server.UserSession;
import jeeves.server.context.ServiceContext;
import org.fao.geonet.Util;
import org.fao.geonet.domain.Metadata;
import org.fao.geonet.repository.MetadataRepository;
import org.fao.geonet.utils.Xml;
import org.fao.geonet.GeonetContext;
import org.fao.geonet.constants.Geonet;
import org.fao.geonet.constants.Params;
import org.fao.geonet.domain.ReservedOperation;
import org.fao.geonet.exceptions.MetadataNotFoundEx;
import org.fao.geonet.kernel.*;
import org.fao.geonet.lib.Lib;
import org.fao.geonet.services.Utils;
import org.jdom.Attribute;
import org.jdom.Element;

import java.nio.file.Path;

//=============================================================================

/** Retrieves a particular metadata. Access is restricted
  */

public class Show extends ShowViewBaseService
{
    //--------------------------------------------------------------------------
	//---
	//--- Init
	//---
	//--------------------------------------------------------------------------

    // GEOCAT
	private boolean keepXLinks;
	public void init(Path appPath, ServiceConfig params) throws Exception{
		super.init(appPath, params);
		this.keepXLinks = "y".equalsIgnoreCase(params.getValue("keepXLinks", "n"));
		     // END GEOCAT
		cache = "y".equalsIgnoreCase(params.getValue("cache", "n"));
	}

	//--------------------------------------------------------------------------
	//---
	//--- Service
	//---
	//--------------------------------------------------------------------------

	public Element exec(Element params, ServiceContext context) throws Exception
	{
		UserSession session = context.getUserSession();

		//-----------------------------------------------------------------------
		//--- handle current tab

		Element elCurrTab = params.getChild(Params.CURRTAB);
		boolean removeSchemaLocation = Util.getParam(params, "removeSchemaLocation", "false").equals("true");

		if (elCurrTab != null)
			session.setProperty(Geonet.Session.METADATA_SHOW, elCurrTab.getText());

		//-----------------------------------------------------------------------
		//--- check access

		GeonetContext gc = (GeonetContext) context.getHandlerContext(Geonet.CONTEXT_NAME);
		DataManager dm = gc.getBean(DataManager.class);
		SchemaManager sm = gc.getBean(SchemaManager.class);

		String id = Utils.getIdentifierFromParameters(params, context);
		boolean skipPopularity = this.skipPopularity;
		if (!skipPopularity) { // skipPopularity could be a URL param as well
			String skip = Util.getParam(params, "skipPopularity", "n");
			skipPopularity = skip.equals("y");
		}
		
		boolean witholdWithheldElements = Util.getParam(params, "hide_withheld", false);
		if (XmlSerializer.getThreadLocal(false) != null || witholdWithheldElements) {
		   XmlSerializer.getThreadLocal(true).setForceFilterEditOperation(witholdWithheldElements);
		}
		if (id == null) {
            throw new MetadataNotFoundEx("Metadata not found.");
        }
		
		Lib.resource.checkPrivilege(context, id, ReservedOperation.view);

		//-----------------------------------------------------------------------
		//--- get metadata
		
		Element elMd;

        // GEOCAT
		boolean addEditing = "true".equalsIgnoreCase(Util.getParam(params, "addEditing","false"));
		if (!skipInfo) {
            elMd = gc.getBean(DataManager.class).getGeocatMetadata(context, id, addEditing, this.keepXLinks);
            // END GEOCAT
		} else {
			elMd = dm.getMetadataNoInfo(context, id);
		}

		if (elMd == null) {
            throw new MetadataNotFoundEx(id);
        }

		if (addRefs) { // metadata.show for GeoNetwork needs geonet:element 
			elMd = dm.enumerateTree(elMd);
		}

		//
		// setting schemaLocation - if there isn't one then use the schemaLocation 
		// that is in the GeoNetwork schema identification and if there isn't one 
		// of those then build one pointing to the XSD in GeoNetwork 

		Metadata info = context.getBean(MetadataRepository.class).findOne(id);
		Attribute schemaLocAtt = sm.getSchemaLocation(info.getDataInfo().getSchemaId(), context);

		if (schemaLocAtt != null) {
			if (elMd.getAttribute(schemaLocAtt.getName(), schemaLocAtt.getNamespace()) == null) {
				elMd.setAttribute(schemaLocAtt);
				// make sure namespace declaration for schemalocation is present -
				// remove it first (does nothing if not there) then add it
				elMd.removeNamespaceDeclaration(schemaLocAtt.getNamespace()); 
				elMd.addNamespaceDeclaration(schemaLocAtt.getNamespace());
			}
		}

		//--- increase metadata popularity
		if (!skipPopularity)
			dm.increasePopularity(context, id);

		if(cache) {
		    cache(context.getUserSession(), elMd, id);
		}
		if (removeSchemaLocation) {
		    elMd.removeAttribute("schemaLocation", Xml.xsiNS);
		}
		return elMd;
	}

	private final static String KEY = "SHOW_METADATA";
    private static void cache( UserSession userSession, Element elMd, String id ) {
        userSession.setProperty(KEY+id, elMd);
    }
    
    public static Element getCached(UserSession userSession, String id) {
        return (Element) userSession.getProperty(KEY+id);
    }

    static void unCache(UserSession userSession, String id) {
        userSession.removeProperty(KEY+id);
    }

    //--------------------------------------------------------------------------
	//---
	//--- Variables
	//---
	//--------------------------------------------------------------------------
    private boolean cache;
    
}
