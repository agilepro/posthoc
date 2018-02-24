package com.purplehillsbooks.posthoc;

import java.io.File;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;

public class SendMailServlet extends javax.servlet.http.HttpServlet {

	private static final long serialVersionUID = 1L;
	private static File outBoxFolder;
	public static PostHocConfig phConfig;
	public static Exception fatalServerError;

	@Override
	public void init(ServletConfig config) throws ServletException {
        try {
            ServletContext sc = config.getServletContext();
            File contextPath = new File(sc.getRealPath("/"));
            phConfig = new PostHocConfig(contextPath);

            outBoxFolder = new File(phConfig.dataFolder, "outbox");
            if (!outBoxFolder.exists()) {
                outBoxFolder.mkdirs();
            }
            if (!outBoxFolder.isDirectory()) {
                throw new Exception("SendMailServlet, outbox folder is not a directory: "
                                + outBoxFolder);
            }
        } 
        catch (Exception e) {
            fatalServerError = e;
            System.out.println("SendMailServlet: crash on initialization:");
            Throwable t = e;
            int count = 0;
            while (t != null) {
                System.out.println("    " + (++count) + ": " + t.toString());
                t = t.getCause();
            }
            e.printStackTrace();
        }
	}

	@Override
	public void doGet(HttpServletRequest req, HttpServletResponse resp) {

	}

	@Override
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {

		String sendStatus = "";
		try {
			
		    JSONObject jObj = new JSONObject(new JSONTokener(request.getReader()));
			List<File> attachement = new ArrayList<File>();
			SendMailListener.createMessage(jObj.getString("from"), jObj.getString("to"), jObj.getString("subject"),
					jObj.getString("mailContent"), attachement, jObj.getString("mailType"));
			sendStatus = "Mail sent succesfully";

		} catch (Exception e) {
			sendStatus = "Mail not sent" + e.getMessage();
		}

		response.setContentType("text/plain");
		response.setCharacterEncoding("UTF-8");
		Writer w = response.getWriter();
		w.write("Status : " + sendStatus);
		w.flush();

	}

	public static File getOutBoxFolder() throws Exception {
		if (fatalServerError != null) {
			throw fatalServerError;
		}
		if (outBoxFolder == null) {
			throw new Exception("SendMailServlet, the outboxFolder has not been initialized for some reason.");
		}
		return outBoxFolder;
	}

}
