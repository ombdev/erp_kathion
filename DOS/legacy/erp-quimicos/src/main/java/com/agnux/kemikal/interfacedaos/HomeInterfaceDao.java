/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.agnux.kemikal.interfacedaos;

import java.util.HashMap;

/**
 *
 * @author agnux
 */
public interface HomeInterfaceDao {
    public HashMap<String, String> getUserByName(String name);
    public HashMap<String, String> getUserById(Integer id_user);
    
}
