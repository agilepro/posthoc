<%@page errorPage="error.jsp"
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
%><%@page import="javax.mail.internet.MimeMessage"
%><%@page import="com.purplehillsbooks.posthoc.MailListener"
%><%@page import="com.purplehillsbooks.posthoc.SendMailListener"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%

    Properties props = new Properties();
    Session mSession = Session.getDefaultInstance(props);

    String selectedName = request.getParameter("msg");
    String selectedAttach = request.getParameter("attach");
    String mailType = request.getParameter("mailType");
    List<EmailModel> msgs= new ArrayList<EmailModel>();
    if("inbox".equals(mailType))
    	msgs = MailListener.listAllMessages();
    else if("outbox".equals(mailType))
    	msgs = SendMailListener.listAllOutboxMessages();   
    File foundMsg = null;
    for (EmailModel msgMod : msgs) {
        File msg = msgMod.filePath;       
        String name = msg.getName();       
        if (selectedName.equals(name)) {
            foundMsg = msg;
        }
    }

    if (foundMsg==null) {
        %>
        <html><body><h1>ERROR: no email message named: <%=selectedName%></h1></body></html>
        <%
        return;
    }
    if (selectedAttach==null) {
        %>
        <html><body><h1>Attachment page must have a parameter named 'attach'</h1></body></html>
        <%
        return;
    }

    int attachNo = Integer.parseInt(selectedAttach);

    FileInputStream fis = new FileInputStream(foundMsg);
    InputStreamReader isr = new InputStreamReader(fis, "UTF-8");

    MimeMessage mm = new MimeMessage(mSession, fis);
    String stringBody = null;
    Multipart mult = null;

    Object content = mm.getContent();
    if (content instanceof String) {
        stringBody = (String)content;
    }
    else if (content instanceof Multipart) {
        mult = (Multipart)content;
    }
    if (mult==null) {
        %>
        <html><body><h1>Message does not appear to have any attachments??</h1></body></html>
        <%
        return;
    }

    BodyPart p = mult.getBodyPart(attachNo);
    Object content2 = p.getContent();
    String attachFileName = p.getFileName();

    if (!(content2 instanceof InputStream)) {
        %>
        <html><body><h1>Expecting an input stream but did nto seem to get that</h1></body></html>
        <%
        return;
    }

    response.setHeader("Content-Disposition", "attachment; filename=\""+attachFileName+"\"");
    response.setHeader("Content-Type", "application/octet-stream");

    InputStream attachInput = (InputStream) content2;
    OutputStream out2 = response.getOutputStream();

    byte[] buf  = new byte[1000];
    int amt = attachInput.read(buf);
    while (amt>0) {
        out2.write(buf, 0, amt);
        amt = attachInput.read(buf);
    }

%>