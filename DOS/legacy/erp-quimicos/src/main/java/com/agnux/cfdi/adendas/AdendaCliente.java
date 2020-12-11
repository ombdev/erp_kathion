package com.agnux.cfdi.adendas;

import java.util.LinkedHashMap;


public class AdendaCliente extends Adenda{
    @Override
    public void createAdenda(Integer noAdenda, LinkedHashMap<String, Object> dataAdenda, String dirXml, String fileNameXml) {
        AdendaFemsaQuimiproductos femsaQuimiproductos = new AdendaFemsaQuimiproductos();
        this.SetNext(femsaQuimiproductos);
        next.createAdenda(noAdenda, dataAdenda, dirXml, fileNameXml);
    }
}
