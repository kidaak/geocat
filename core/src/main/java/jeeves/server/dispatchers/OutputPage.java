//=============================================================================
//===	Copyright (C) 2001-2005 Food and Agriculture Organization of the
//===	United Nations (FAO-UN), United Nations World Food Programme (WFP)
//===	and United Nations Environment Programme (UNEP)
//===
//===	This library is free software; you can redistribute it and/or
//===	modify it under the terms of the GNU Lesser General Public
//===	License as published by the Free Software Foundation; either
//===	version 2.1 of the License, or (at your option) any later version.
//===
//===	This library is distributed in the hope that it will be useful,
//===	but WITHOUT ANY WARRANTY; without even the implied warranty of
//===	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//===	Lesser General Public License for more details.
//===
//===	You should have received a copy of the GNU Lesser General Public
//===	License along with this library; if not, write to the Free Software
//===	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//===
//===	Contact: Jeroen Ticheler - FAO - Viale delle Terme di Caracalla 2,
//===	Rome - Italy. email: GeoNetwork@fao.org
//==============================================================================

package jeeves.server.dispatchers;

import jeeves.constants.ConfigFile;

import org.fao.geonet.utils.Xml;
import org.jdom.Element;

import java.util.ArrayList;
import java.util.List;

//=============================================================================

 /** This class represents a single output page of a service
  */

public class OutputPage extends AbstractPage
{
	private String  forward;
	private boolean isFile, isBLOB;
	private List<String> preStyleSheets = new ArrayList<String>();
	//--------------------------------------------------------------------------
	//---
	//--- API methods
	//---
	//--------------------------------------------------------------------------

	/**
	 * Gets the style sheets that will be applied <strong>BEFORE</strong> the
	 * primary stylesheet.
	 */
	public List<String> getPreStyleSheets()
    {
        return preStyleSheets;
    }

	   /**
     * Sets the style sheets that will be applied <strong>BEFORE</strong> the
     * primary stylesheet.
     */
    public void setPreStyleSheets(List<Element> preStyleSheets)
    {
        this.preStyleSheets = new ArrayList<String>();
        for (Element element : preStyleSheets) {
            this.preStyleSheets.add(element.getAttributeValue(ConfigFile.Output.Attr.SHEET));
        }
    }
	
	
	
	/** If the output page is a forward returns the service, otherwise returns null
	  */

	public String getForward() { return forward; }

	//--------------------------------------------------------------------------
	/** If the output page is a binary file returns the element name, otherwise returns null
	  */

	public boolean isFile() { return isFile; }

	//--------------------------------------------------------------------------

	public boolean isBLOB() { return isBLOB; }

	//--------------------------------------------------------------------------

	public void setForward(String f)
	{
		forward = f;
	}

	//--------------------------------------------------------------------------

	public void setFile(boolean yesno)
	{
		isFile = yesno;
	}

	//--------------------------------------------------------------------------

	public void setBLOB(boolean yesno)
	{
		isBLOB = yesno;
	}

	//---------------------------------------------------------------------------
	/** Returns true if the service output has attributes that match this page
	  */

	public boolean matches(Element el) throws Exception
	{
		String test = getTestCondition();

		if (test == null)	return true;
			else				return Xml.selectBoolean(el, test);
	}
}

//=============================================================================


