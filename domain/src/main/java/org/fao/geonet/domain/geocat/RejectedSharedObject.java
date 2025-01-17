package org.fao.geonet.domain.geocat;

import org.fao.geonet.domain.GeonetEntity;
import org.fao.geonet.domain.ISODate;
import org.fao.geonet.utils.Xml;
import org.hibernate.annotations.Type;
import org.jdom.Element;
import org.jdom.JDOMException;
import org.jdom.Namespace;

import java.io.IOException;
import javax.persistence.Access;
import javax.persistence.AccessType;
import javax.persistence.AttributeOverride;
import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Lob;
import javax.persistence.SequenceGenerator;
import javax.persistence.Table;

/**
 * Represents a rejected shared object.
 *
 * User: Jesse
 * Date: 11/14/13
 */
@Entity
@Access(AccessType.PROPERTY)
@Table(name = "DeletedObjects")
@SequenceGenerator(name=RejectedSharedObject.ID_SEQ_NAME, initialValue=100, allocationSize=1)
public class RejectedSharedObject extends GeonetEntity {
    static final String ID_SEQ_NAME = "rejected_shared_object_id_seq";

    private static final Namespace XLINK = Namespace.getNamespace("xlink", "http://www.w3.org/1999/xlink");
    private int id;
    private String description;
    private String xml;
    private String rejectionMessage;
    private ISODate deletionDate = new ISODate();

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = ID_SEQ_NAME)
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    @Column(nullable = false)
    @Lob
    @Basic(fetch = FetchType.LAZY)
    @Type(type="org.hibernate.type.StringClobType") // this is a work around for postgres so postgres can correctly load clobs
    public String getXml() {
        return xml;
    }

    public RejectedSharedObject setXml(String xml) {
        this.xml = xml;
        return this;
    }

    @Column(nullable = false)
    @AttributeOverride(name = "dateAndTime", column = @Column(name = "deletiondate", nullable = false, length = 30))
    public ISODate getDeletionDate() {
        return deletionDate;
    }

    public RejectedSharedObject setDeletionDate(ISODate deletionDate) {
        this.deletionDate = deletionDate;
        return this;
    }

    public Element getXmlElement(boolean validate) throws IOException, JDOMException {
        final Element obj = Xml.loadString(getXml(), false);
        obj.removeAttribute("title", XLINK);
        obj.removeNamespaceDeclaration(XLINK);
        return obj;
    }

    public String getRejectionMessage() {
        return rejectionMessage;
    }

    public void setRejectionMessage(String rejectionMessage) {
        this.rejectionMessage = rejectionMessage;
    }
}
