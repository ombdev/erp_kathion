/*
 * Clase para Crear Adenda para SUM CHEMICAL.
 * Aqui se reciben los datos necesarios, se crea el xml y se incrusta en el archivo xml despues del timrado.
 */
package com.agnux.cfdi.adendas;

import com.agnux.common.helpers.FileHelper;
import com.agnux.common.obj.AgnuxXmlObject;
import java.io.File;
import java.io.StringWriter;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 *
 * @author Noe Martinez
 * gpmarsan@gmail.com
 * 28/noviembre/2013
 * 
 */
public class AdendaSunchemical extends Adenda{

    @Override
    public void createAdenda(Integer noAdenda, LinkedHashMap<String, Object> dataAdenda, String dirXml, String fileNameXml) {
        String pathXmlCfdi = dirXml+"/"+fileNameXml;
        
        if (noAdenda==2){
            try {
                System.out.println(this.getClass().toString());
                
                //Objeto para contruir xml de la Adenda
                XmlBuilder xmlBuilder = new XmlBuilder(dataAdenda);
                //String outXmlString = xmlBuilder.getOutXmlString();
                //System.out.println("Adenda: "+outXmlString);
                
                //Objeto para agregar la Adenda al XML del CDFI
                AgregarAdendaXmlCfdi addAdenda = new AgregarAdendaXmlCfdi(pathXmlCfdi, xmlBuilder.getDoc());
                //Ejecutar metodo que agrega elemento al xml del CFDI
                addAdenda.agregarAdenda();
                //Obtener la cadena XML del CFDI con Adenda
                String xmlString = addAdenda.getXmlOutString();
                
                
                System.out.println("pathXmlCfdi: "+pathXmlCfdi);
                //Esta impresion es por  si llega a fallar la creacion del nuevo fichero xml con adenda, 
                //si esto sucede podremos buscar en el log la cadena  que debe contener el xml, ya que en este punto fue timbrado y generado PDF y actualizado el Inventario.
                System.out.println("xmlCfdiConAdenda:\n"+xmlString);
                
                
                //Crear fichero
                File xml_cfdi= new File(pathXmlCfdi);
                
                //Verificar si ya existe
                if(xml_cfdi.exists()){
                    //Si ya existe un fichero con el mismo nombre hay que eliminarlo
                    FileHelper.delete(pathXmlCfdi);
                }
                
                //Crear el nuevo fichero del XML
                boolean fichero_xml_con_adenda_ok = FileHelper.createFileWithText(dirXml, fileNameXml, xmlString);
                
                if(fichero_xml_con_adenda_ok){
                    System.out.println("Fichero xml con adenda se creó con éxito.");
                }else{
                    System.out.println("Fichero xml con adenda NO se creó.");
                }
            } catch (Exception ex) {
                System.out.println("Error al agregar Adenda al CFDI.");
                Logger.getLogger(AdendaFemsaQuimiproductos.class.getName()).log(Level.SEVERE, null, ex);
            }
            
        }else{
            next.createAdenda(noAdenda, dataAdenda, dirXml, fileNameXml);
        }
    }
    
    
    private class XmlBuilder extends AgnuxXmlObject{
        public XmlBuilder(LinkedHashMap<String, Object> data){
            super();
            this.construyeNodoAdenda(data);
        }
        
        private void construyeNodoAdenda(LinkedHashMap<String, Object> data){
            //String elemento = new String();
            Document tmp = this.getDb().newDocument();
            
            Element root = tmp.createElement("cfdi:Addenda");
            Element child_1 = tmp.createElement("CABECERA");
            
            //El arreglo elements debe tener exactamente los mismos nombres de los indices que trae el objeto data.
            String[] elements = {"PO_NUMBER"};
            List<String>  lista_elementos = (List<String>) Arrays.asList(elements);
            for ( String elemento : lista_elementos){
                Element element = tmp.createElement(elemento);
                if(!data.get(elemento).equals("")){
                    element.setTextContent(String.valueOf(data.get(elemento)));
                }
                child_1.appendChild(element);
            }
            
            root.appendChild(child_1);
            tmp.appendChild(root);
            
            this.setDoc(tmp);
        }
        
        
        
        
        
        public String getOutXmlString() throws TransformerConfigurationException, TransformerException{
            Transformer transformer = TransformerFactory.newInstance().newTransformer();
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
            
            //initialize StreamResult with File object to save to file
            StreamResult result = new StreamResult(new StringWriter());
            DOMSource source = new DOMSource(this.getDoc());
            transformer.transform(source, result);
            
            return result.getWriter().toString().replace("standalone=\"no\"", " ");
        }
    }
}
