package com.purplehillsbooks.posthoc;

import java.io.File;
import java.net.InetAddress;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

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
    	initializeMailServices(config);
    }
    
    public void initializeMailServices(ServletConfig config){
    	 try {
             System.out.println("PostHoc Servlet: Server starting");
             ServletContext sc = config.getServletContext();
             File contextPath = new File(sc.getRealPath("/"));
             phConfig = new PostHocConfig(contextPath);

             dataFolder = phConfig.dataFolder;             
             InetAddress bindAddress = InetAddress.getByName(phConfig.hostName);
            
             if(SMTPServerHandler.getSmtpServer() == null)
            	 SMTPServerHandler.startServer(phConfig.hostPort, bindAddress);
             System.out.println("PostHocServlet: Server started on "+phConfig.hostName+":"+phConfig.hostPort);
             System.out.println("PostHocServlet: Server saving data in: "+dataFolder);
             
             if(POPServer.theOneBigPopServer == null)
            	 POPServer.startListening(phConfig);
             
         }
         catch (Exception e) {
             fatalServerError = e;
             System.out.println("PostHocServlet: crash on initialization:");
             Throwable t = e;
             int count = 0;
             while (t!=null) {
                 System.out.println("    "+(++count)+": "+t.toString());
                 t = t.getCause();
             }            
             e.printStackTrace();
         }
    }
    
    public static File getDataFolder() throws Exception {
        if (fatalServerError!=null) {
            throw fatalServerError;
        }
        if (dataFolder==null) {
            throw new Exception("PostHoc server has not been initialized for some reason!");
        }
        return dataFolder;
    }
    
    /**
     * Returns outbox directory path 
     */
    public static File getOutBoxFolder() throws Exception {
       
        return new File(createOutbox(getDataFolder()+"/outbox"));
    }
    
    /**
     * Create outbox Directory if it does not exist
     */
    private static String createOutbox(String dirPAth) throws Exception{
    	File theOutboxDir = new File(dirPAth);
    	
    	if (!theOutboxDir.exists()) {    	    
    	    try{
    	    	theOutboxDir.mkdir();      	        
    	    } 
    	    catch(SecurityException se){
    	    	throw new Exception("Outbox Directory not created ",se);
    	    }
    	}
    	return dirPAth;
    }

}

