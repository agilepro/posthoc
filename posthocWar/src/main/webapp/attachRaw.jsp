<%@page errorPage="error.jsp"
%><%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.OutputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.util.List"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Properties"
%><%@page import="javax.mail.BodyPart"
%><%@page import="javax.mail.Multipart"
%><%@page import="javax.mail.Session"
%><%@page import="com.purplehillsbooks.posthoc.EmailModel"
%><%@page import="com.purplehillsbooks.posthoc.EmailAttachment"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%

    request.setCharacterEncoding("utf-8");
    String selectedName = request.getParameter("msg");
	String mailType = request.getParameter("mailType");
	String selectedAttach = request.getParameter("attach");
    EmailModel foundMsg = null;
    if("outbox".equals(mailType)) {
    	foundMsg = EmailModel.getOutboxMessage(selectedName);
    }
    else {
    	foundMsg = EmailModel.getInboxMessage(selectedName);
    }
    
    if (foundMsg==null) {
        throw new Exception("Can not find a message with name: "+selectedName);
    }
    
    EmailAttachment matt = foundMsg.getAttachmentByName(selectedAttach);
    


    response.setHeader("Content-Disposition", "attachment; filename=\""+selectedAttach+"\"");
    response.setHeader("Content-Type", "application/octet-stream");

    InputStream attachInput = matt.contents.getInputStream();
    OutputStream out2 = response.getOutputStream();

    byte[] buf  = new byte[1000];
    int amt = attachInput.read(buf);
    while (amt>0) {
        out2.write(buf, 0, amt);
        amt = attachInput.read(buf);
    }

%>