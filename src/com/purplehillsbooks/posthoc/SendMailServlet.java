package com.purplehillsbooks.posthoc;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

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

	@Override
	public void doGet(HttpServletRequest req, HttpServletResponse resp) {

	}

	@Override
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {

		JSONObject jObj;
		String str = null;
		String sendStatus = "";
		StringBuilder sb = new StringBuilder();
		BufferedReader br = request.getReader();
		try {
			
			while ((str = br.readLine()) != null) {
				sb.append(str);
			}

			jObj = new JSONObject(sb.toString());
			List<File> attachement = new ArrayList<File>();
			SendMailListener.createMessage(jObj.getString("from"), jObj.getString("to"), jObj.getString("subject"),
					jObj.getString("mailContent"), attachement, jObj.getString("mailType"));
			sendStatus = "Mail sent succesfully";

		} catch (JSONException e) {
			sendStatus = "Mail not sent" + e.getMessage();
		} catch (Exception e) {
			sendStatus = "Mail not sent" + e.getMessage();
		}

		response.setContentType("text/plain");
		response.setCharacterEncoding("UTF-8");
		response.getWriter().write("Status : " + sendStatus);

	}

	public static File getOutBoxFolder() throws Exception {
		if (fatalServerError != null) {
			throw fatalServerError;
		}
		if (outBoxFolder == null) {
			throw new Exception("PostHoc server has not been initialized for some reason!");
		}
		return outBoxFolder;
	}

}
