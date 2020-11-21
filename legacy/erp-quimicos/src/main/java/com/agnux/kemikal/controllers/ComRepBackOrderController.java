/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.agnux.kemikal.controllers;

import com.agnux.cfd.v2.Base64Coder;
import com.agnux.common.obj.ResourceProject;
import com.agnux.common.obj.UserSessionData;
import com.agnux.kemikal.interfacedaos.ComInterfaceDao;
import com.agnux.kemikal.interfacedaos.GralInterfaceDao;
import com.agnux.kemikal.interfacedaos.HomeInterfaceDao;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.SessionAttributes;

/**
 * @author Noe Martinez
 * gpmarsan@gmail.com
 * 27/mayo/2014
 * 
 * Reporte de BackOrder de Ordenes de Compra
 */

@Controller
@SessionAttributes({"user"})
@RequestMapping("/comrepbackorder/")
public class ComRepBackOrderController {
    private static final Logger log  = Logger.getLogger(InvRepExisController.class.getName());
    ResourceProject resource = new ResourceProject();
    
    @Autowired
    @Qualifier("daoCom")
    private ComInterfaceDao ComDao;
    
    @Autowired
    @Qualifier("daoHome")
    private HomeInterfaceDao HomeDao;
    
    @Autowired
    @Qualifier("daoGral")
    private GralInterfaceDao gralDao;
    
    public ComInterfaceDao getComDao() {
        return ComDao;
    }
    
    public HomeInterfaceDao getHomeDao() {
        return HomeDao;
    }
    
    public GralInterfaceDao getGralDao() {
        return gralDao;
    }
    
    
    
    @RequestMapping(value="/startup.agnux")
    public ModelAndView startUp(HttpServletRequest request, HttpServletResponse response, 
            @ModelAttribute("user") UserSessionData user)
            throws ServletException, IOException {
        
        log.log(Level.INFO, "Ejecutando starUp de {0}", ComRepBackOrderController.class.getName());
        LinkedHashMap<String,String> infoConstruccionTabla = new LinkedHashMap<String,String>();
        
        
        ModelAndView x = new ModelAndView("comrepbackorder/startup", "title", "BackOrder");
        
        x = x.addObject("layoutheader", resource.getLayoutheader());
        x = x.addObject("layoutmenu", resource.getLayoutmenu());
        x = x.addObject("layoutfooter", resource.getLayoutfooter());
        x = x.addObject("grid", resource.generaGrid(infoConstruccionTabla));
        x = x.addObject("url", resource.getUrl(request));
        x = x.addObject("username", user.getUserName());
        x = x.addObject("empresa", user.getRazonSocialEmpresa());
        x = x.addObject("sucursal", user.getSucursal());
        
        String userId = String.valueOf(user.getUserId());
        
        String codificado = Base64Coder.encodeString(userId);
        
        //id de usuario codificado
        x = x.addObject("iu", codificado);
        
        return x;
    }
    
    
    
    
    
    /*
    //Obtiene datos para el buscador de traspasos
    @RequestMapping(method = RequestMethod.POST, value="/getAlmacenes.json")
    public @ResponseBody HashMap<String,ArrayList<HashMap<String, String>>> getAlmacenesJson(
            @RequestParam(value="iu", required=true) String id_user,
            Model model
            ) {
        
        log.log(Level.INFO, "Ejecutando getAlmacenesJson de {0}", InvRepExisController.class.getName());
        HashMap<String,ArrayList<HashMap<String, String>>> jsonretorno = new HashMap<String,ArrayList<HashMap<String, String>>>();
        ArrayList<HashMap<String, String>> Almacenes = new ArrayList<HashMap<String, String>>();
        HashMap<String, String> userDat = new HashMap<String, String>();
        
        //decodificar id de usuario
        Integer id_usuario = Integer.parseInt(Base64Coder.decodeString(id_user));
        userDat = this.getHomeDao().getUserById(id_usuario);
        
        Integer id_empresa = Integer.parseInt(userDat.get("empresa_id"));
        
        Almacenes = this.getComDao().getAlmacenes2(id_empresa);
        
        jsonretorno.put("Almacenes", Almacenes);
        
        return jsonretorno;
    }
    */
    
    
    
    
    
    
    
   
    //obtiene la existencia de un Almacen en especifico
    @RequestMapping(method = RequestMethod.POST, value="/getBackorder.json")
    public @ResponseBody HashMap<String,ArrayList<HashMap<String, String>>> getBackorderJson(
            @RequestParam("tipo") Integer tipo,
            @RequestParam("oc") String oc,
            @RequestParam("codigo") String codigo_producto,
            @RequestParam("descripcion") String descripcion,
            @RequestParam("proveedor") String proveedor,
            @RequestParam("finicial") String finicial,
            @RequestParam("ffinal") String ffinal,
            @RequestParam(value="iu", required=true) String id_user,
            Model model
        ) {
                                        
        
        log.log(Level.INFO, "Ejecutando getBackorder de {0}", ComRepBackOrderController.class.getName());
        HashMap<String,ArrayList<HashMap<String, String>>> jsonretorno = new HashMap<String,ArrayList<HashMap<String, String>>>();
        ArrayList<HashMap<String, String>> datos = new ArrayList<HashMap<String, String>>();
        HashMap<String, String> userDat = new HashMap<String, String>();
        
        //decodificar id de usuario
        Integer id_usuario = Integer.parseInt(Base64Coder.decodeString(id_user));
        userDat = this.getHomeDao().getUserById(id_usuario);
        
        Integer id_empresa = Integer.parseInt(userDat.get("empresa_id"));
        
        datos = this.getComDao().getCom_DatosRepBackOrder(tipo, oc, codigo_producto, descripcion, proveedor, finicial, ffinal, id_empresa);
        
        jsonretorno.put("Datos", datos);
        
        return jsonretorno;
    }
    
   
    
    

    
    
    
    /*
   //Genera pdf de Reporte de Existencias en Inventario
    @RequestMapping(value = "/getReporteExistencias/{cadena}/{iu}/out.json", method = RequestMethod.GET ) 
    public ModelAndView getReporteExistenciasJson(ho
                @PathVariable("cadena") String cadena,
                @PathVariable("iu") String id_user,
                HttpServletRequest request, 
                HttpServletResponse response, 
                Model model)
            throws ServletException, IOException, URISyntaxException, DocumentException, Exception {
        
        HashMap<String, String> userDat = new HashMap<String, String>();
        
        System.out.println("cadena: "+cadena);
        
        String cad[] = cadena.split("___");
        
        Integer opcion_reporte = Integer.parseInt(cad[0]);
        Integer almacen = Integer.parseInt(cad[1]);
        String codigo_producto = cad[2];
        String descripcion = cad[3];
        String lote_interno = cad[4];
        
        
        if(codigo_producto.equals("0")){
            codigo_producto="";
        }
        
        if(descripcion.equals("0")){
            descripcion="";
        }
        
        if(lote_interno.equals("0")){
            lote_interno="";
        }
        
        System.out.println("Generando Reporte de Existencias de Lotes");
        
        //decodificar id de usuario
        Integer id_usuario = Integer.parseInt(Base64Coder.decodeString(id_user));
        
        userDat = this.getHomeDao().getUserById(id_usuario);
        Integer id_empresa = Integer.parseInt(userDat.get("empresa_id"));
        String rfc_empresa = this.getGralDao().getRfcEmpresaEmisora(id_empresa);
        String razon_social_empresa = this.getGralDao().getRazonSocialEmpresaEmisora(id_empresa);
        
        //obtener el directorio temporal
        String dir_tmp = this.getGralDao().getTmpDir();
        
        
        String[] array_company = razon_social_empresa.split(" ");
        String company_name= array_company[0].toLowerCase();
        //String ruta_imagen = this.getGralDao().getImagesDir() +"logo_"+ company_name +".png";
        
        File file_dir_tmp = new File(dir_tmp);
        System.out.println("Directorio temporal: "+file_dir_tmp.getCanonicalPath());
        
        
        String file_name = "exis_lote_"+rfc_empresa+".pdf";
        //ruta de archivo de salida
        String fileout = file_dir_tmp +"/"+  file_name;
        
        ArrayList<HashMap<String, String>> lista_existencias = new ArrayList<HashMap<String, String>>();
        
        //obtiene las facturas del periodo indicado
        lista_existencias = this.getComDao().getReporteExistenciasLotes_Datos(almacen, codigo_producto, descripcion, opcion_reporte, lote_interno);
        
        String fecha_actual = TimeHelper.getFechaActualYMD();
        
        System.out.println("fecha_actual: "+fecha_actual);
        
        //instancia a la clase que construye el pdf del reporte de existencias
        PdfReporteInvExisLotes pdf = new PdfReporteInvExisLotes( lista_existencias, fileout, razon_social_empresa);
        pdf.ViewPDF();
        
        System.out.println("Recuperando archivo: " + fileout);
        File file = new File(fileout);
        int size = (int) file.length(); // Tamaño del archivo
        BufferedInputStream bis = new BufferedInputStream(new FileInputStream(file));
        response.setBufferSize(size);
        response.setContentLength(size);
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition","attachment; filename=\"" + file.getCanonicalPath() +"\"");
        FileCopyUtils.copy(bis, response.getOutputStream());  	
        response.flushBuffer();
        
        FileHelper.delete(fileout);
        return null;
    } 
    */
}
