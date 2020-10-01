package com.purplehillsbooks.posthoc;

import java.io.File;
import java.net.InetAddress;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.json.JSONException;

public class PostHocServlet extends javax.servlet.http.HttpServlet {

    private static final long serialVersionUID = 1L;
    private static File dataFolder;    
    public static PostHocConfig phConfig;
    public static Exception fatalServerError;

    @Override
    public void doPost(HttpServletRequest req, HttpServletResponse resp) {
        //nothing doing
    }

    @Override
    public void init(ServletConfig config) throws ServletException {
         try {
             //For first time phConfig will be null
             //second time phConfig will have value c:/opt/PostHocData/
             if(phConfig == null){               
                 System.out.println("PostHoc Servlet: Server starting");
 
                 ServletContext sc = config.getServletContext();
                 File contextPath = new File(sc.getRealPath("/"));
                 phConfig = new PostHocConfig(contextPath);
 
                 dataFolder = phConfig.dataFolder;
                 InetAddress bindAddress = InetAddress.getByName(phConfig.hostName);
 
                 SMTPServerHandler.startServer(phConfig.hostPort, bindAddress);
                 System.out.println("PostHocServlet: Server started on "+phConfig.hostName+":"+phConfig.hostPort);
                 System.out.println("PostHocServlet: Server saving data in: "+dataFolder);
 
                 POPServer.startListening(phConfig);
             } 
         }
         catch (Exception e) {
             fatalServerError = e;
             JSONException.traceException(e,"PostHocServlet: crash on initialization");
         }
    } 
    
    
    public static File getDataFolder() throws Exception {
        if (fatalServerError!=null) {
            throw fatalServerError;
        }
        if (dataFolder==null) {
            throw new JSONException("PostHoc server not initialized!  DataFolder is null.");
        }
        return dataFolder;
    }
    
    /**
     * Returns outbox directory path 
     * Create outbox Directory if it does not exist
     */
    public static File getOutBoxFolder() throws Exception {
        File theOutboxDir = new File(getDataFolder(), "outbox");
        if (!theOutboxDir.exists()) {           
            try{
                if (!theOutboxDir.mkdir()) {
                    throw new JSONException("Create folder failed: {0}", theOutboxDir.getCanonicalPath());
                };               
            } 
            catch(SecurityException se){
                throw new JSONException("Outbox Directory not created at {0}",se,theOutboxDir.getCanonicalPath());
            }
        }
        return theOutboxDir;
    }
    
    
    public static File getTempFolder() throws Exception {
        File tempFolder = new File(getDataFolder(), "temp");
        if (!tempFolder.exists()) {           
            try{
                if (!tempFolder.mkdir()) {
                    throw new JSONException("Create folder failed: {0}", tempFolder.getCanonicalPath());
                };               
            } 
            catch(SecurityException se){
                throw new JSONException("Temp Directory not created at {0}",se,tempFolder.getCanonicalPath());
            }
        }
        return tempFolder;
    }

}

