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
    public static PostHocConfig kmc;
    public static Exception fatalServerError;

    @Override
    public void doPost(HttpServletRequest req, HttpServletResponse resp) {
        //nothing doing
    }

    @Override
    public void init(ServletConfig config) throws ServletException {
        try {
            System.out.println("PostHoc Servlet: Server starting");
            ServletContext sc = config.getServletContext();
            File contextPath = new File(sc.getRealPath("/"));
            kmc = new PostHocConfig(contextPath);

            dataFolder = kmc.dataFolder;
            InetAddress bindAddress = InetAddress.getByName(kmc.hostName);
            SMTPServerHandler.startServer(kmc.hostPort, bindAddress);
            System.out.println("PostHocServlet: Server started on "+kmc.hostName+":"+kmc.hostPort);
            System.out.println("PostHocServlet: Server saving data in: "+dataFolder);
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

}
