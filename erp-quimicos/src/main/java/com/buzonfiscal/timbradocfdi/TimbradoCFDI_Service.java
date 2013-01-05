
package com.buzonfiscal.timbradocfdi;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.logging.Logger;
import javax.xml.namespace.QName;
import javax.xml.ws.Service;
import javax.xml.ws.WebEndpoint;
import javax.xml.ws.WebServiceClient;
import javax.xml.ws.WebServiceFeature;


/**
 * This class was generated by the JAX-WS RI.
 * JAX-WS RI 2.1.3-b02-
 * Generated source version: 2.1
 * 
 */
@WebServiceClient(name = "TimbradoCFDI", targetNamespace = "http://www.buzonfiscal.com/TimbradoCFDI/", wsdlLocation = "file:/home/agnux/tools/kit/KIT%20TIMBRE%203.2/XSD,%20XSLT%20Y%20WSDL/TimbradoCFDI.wsdl")
public class TimbradoCFDI_Service
    extends Service
{

    private final static URL TIMBRADOCFDI_WSDL_LOCATION;
    private final static Logger logger = Logger.getLogger(com.buzonfiscal.timbradocfdi.TimbradoCFDI_Service.class.getName());

    static {
        URL url = null;
        try {
            URL baseUrl;
            baseUrl = com.buzonfiscal.timbradocfdi.TimbradoCFDI_Service.class.getResource(".");
            url = new URL(baseUrl, "file:/home/agnux/tools/kit/KIT%20TIMBRE%203.2/XSD,%20XSLT%20Y%20WSDL/TimbradoCFDI.wsdl");
        } catch (MalformedURLException e) {
            logger.warning("Failed to create URL for the wsdl Location: 'file:/home/agnux/tools/kit/KIT%20TIMBRE%203.2/XSD,%20XSLT%20Y%20WSDL/TimbradoCFDI.wsdl', retrying as a local file");
            logger.warning(e.getMessage());
        }
        TIMBRADOCFDI_WSDL_LOCATION = url;
    }

    public TimbradoCFDI_Service(URL wsdlLocation, QName serviceName) {
        super(wsdlLocation, serviceName);
    }

    public TimbradoCFDI_Service() {
        super(TIMBRADOCFDI_WSDL_LOCATION, new QName("http://www.buzonfiscal.com/TimbradoCFDI/", "TimbradoCFDI"));
    }

    /**
     * 
     * @return
     *     returns TimbradoCFDI
     */
    @WebEndpoint(name = "TimbradoCFDISOAP")
    public TimbradoCFDI getTimbradoCFDISOAP() {
        return super.getPort(new QName("http://www.buzonfiscal.com/TimbradoCFDI/", "TimbradoCFDISOAP"), TimbradoCFDI.class);
    }

    /**
     * 
     * @param features
     *     A list of {@link javax.xml.ws.WebServiceFeature} to configure on the proxy.  Supported features not in the <code>features</code> parameter will have their default values.
     * @return
     *     returns TimbradoCFDI
     */
    @WebEndpoint(name = "TimbradoCFDISOAP")
    public TimbradoCFDI getTimbradoCFDISOAP(WebServiceFeature... features) {
        return super.getPort(new QName("http://www.buzonfiscal.com/TimbradoCFDI/", "TimbradoCFDISOAP"), TimbradoCFDI.class, features);
    }

}