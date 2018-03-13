package com.purplehillsbooks.posthoc;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;

public class SendMailServlet extends javax.servlet.http.HttpServlet {
	
	private static final long serialVersionUID = 1L;
	public static Exception fatalServerError;
    int counter;
/*
	@Override
	public void init(ServletConfig config) throws ServletException {
        //PostHocServlet postHocServlet= new PostHocServlet();
        //postHocServlet.initializeMailServices(config);
        super.init(config);
	}
*/
	@Override
	public void doGet(HttpServletRequest req, HttpServletResponse resp) {
		//do nothing
	}

	@Override
	public void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {

		JSONObject jObj;
		String sendStatus = "";
		String fieldvalue = "{}";		
			List<FileItem> attachement = new ArrayList<FileItem>();
		try {
			List <FileItem> multiparts = new ServletFileUpload(new DiskFileItemFactory()).parseRequest(request);			
            for(FileItem item : multiparts){
            	if(item.isFormField()){            		
            		fieldvalue = item.getString();
            	}
                if(!item.isFormField()){                	
                	attachement.add(item);                    
                }
            }           
            jObj = new JSONObject(new JSONTokener(fieldvalue));			
			SendMailListener.saveEmail(jObj.getString("from"), jObj.getString("to"), jObj.getString("subject"),
					jObj.getString("mailContent"), attachement, jObj.getString("mailType"));
			
			sendStatus = "email message stored in POP message box";
		}  catch (Exception e) {
			sendStatus = "Mail not sent" + e.getMessage();
		}

		response.setContentType("text/plain");
		response.setCharacterEncoding("UTF-8");
		response.getWriter().write("Status : " + sendStatus);
	}	
}
