/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.agnux.cfdi.adendas;

import java.util.LinkedHashMap;

/**
 *
 * @author Noe Martinez
 * gpmarsan@gmail.com
 * 22/octubre/2013
 * 
 */
public abstract class Adenda {
    protected Adenda next;
    
    public void SetNext(Adenda next){
        this.next = next;
    }
    
    public abstract void createAdenda(Integer noAdenda, LinkedHashMap<String, Object> dataAdenda, String dirXml, String fileNameXml);
}
