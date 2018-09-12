<%@page errorPage="error.jsp"
%><%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
%><%@page import="com.purplehillsbooks.posthoc.EmailModel"
%><%@page import="com.purplehillsbooks.posthoc.MailListener"
%><%@page import="com.purplehillsbooks.posthoc.SendMailListener"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
%><%@page import="com.purplehillsbooks.streams.MemFile"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.Reader"
%><%@page import="java.io.StringReader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Date"
%><%@page import="java.util.List"
%><%@page import="java.util.Properties"
%><%@page import="javax.mail.Address"
%><%@page import="javax.mail.BodyPart"
%><%@page import="javax.mail.Multipart"
%><%@page import="javax.mail.Session"
%><%@page import="javax.mail.internet.InternetAddress"
%><%@page import="javax.mail.internet.MimeMessage"
%><%@page import="javax.mail.Message.RecipientType"
%><%

    String selectedName = request.getParameter("msg");
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


    Properties props = new Properties();
    Session mSession = Session.getDefaultInstance(props);

    HTMLWriter hw = new HTMLWriter(out);
    FileInputStream fis = new FileInputStream(foundMsg);

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

    Date mmSentDate = mm.getSentDate();

%><!DOCTYPE html>
<html>
<head>
<%@include file="Includes.jsp" %>

<script type="text/javascript">

var app = angular.module('myApp', []);
app.controller('myCtrl', function($scope, $http) {
    $scope.msg = {};
    $scope.mode = "Message";
	
    $scope.mailType = "<%JavaScriptWriter.encode(out, mailType);%>";
    $scope.selectedName = "<%JavaScriptWriter.encode(out, selectedName);%>";
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    	
});
app.filter('escape', function() {
    return function(input) {
        if(input) {
            return window.encodeURIComponent(input); 
        }
        return "";
    }
});
</script>
</head>

<body ng-app="myApp" ng-controller="myCtrl" >
<%@include file="NavBar.jsp" %>
<%@include file="ErrorPanel.jsp"%>

<div class="msgmain">
<a href="list.jsp" ng-show="'inbox'==mailType">
    <button class="iconbutton"><span class="glyphicon glyphicon-list"></span>
    <span>Inbox List</span>
    </button></a>
<a href="reply.jsp?msg={{selectedName|escape}}" ng-show="'inbox'==mailType">
	<button class="iconbutton"><span class="fa fa-newspaper-o" style="font-size:24px"></span>
	<span>Create Reply</span>
	    </button></a>
<a href="outbox.jsp" ng-show="'outbox'==mailType">
	<button class="iconbutton"><span class="glyphicon glyphicon-list"></span>
	    <span>Outbox List</span>
    </button></a>
<span style="margin:20px"></span>
<a href="msgHtml.jsp?msg={{selectedName|escape}}&mailType={{mailType|escape}}">
 <button class="iconbutton"><span class="glyphicon glyphicon-font"></span>
    <span>Normal</span>
    </button></a>
<a href="msgTxt.jsp?msg={{selectedName|escape}}&mailType={{mailType|escape}}">
    <button class="iconbutton"><span class="glyphicon glyphicon-tags"></span>
    <span>HTML</span>
    </button></a>
<a href="msgRaw.jsp?msg={{selectedName|escape}}&mailType={{mailType|escape}}">
    <button class="iconbutton"><span class="glyphicon glyphicon-list-alt"></span>
    <span>Raw</span>
    </button></a>
</div>

<div class="msgmain">

<%
    if (stringBody!=null) {
        HTMLWriter.writeHtmlWithLines(out,stringBody);
    }
    else if (mult!=null) {

        %>

        <table class="table">
        <tr><td>From: </td><td> <%writeArray(out, mm.getFrom());%></td></tr>
        <tr><td>To: </td><td> <%writeArray(out, mm.getRecipients(RecipientType.TO));%></td></tr>
		<%
        if (mm.getRecipients(RecipientType.CC)!=null) { %>
         <tr><td>Cc: </td><td> <%writeArray(out, mm.getRecipients(RecipientType.CC));%></td></tr>
        <% }
        else{
        } %>
        <tr><td>Date: </td><td> <%
            if (mmSentDate==null) {
                %><span style="color:red;">(missing from message)</span><%
            }
            else {
                HTMLWriter.writeHtml(out, mmSentDate.toString());
            }
            %></td></tr>
        <tr><td>Subject: </td><td> <%HTMLWriter.writeHtml(out, mm.getSubject());%></td></tr>
        </table>
        <%
        for (int i=0; i<mult.getCount(); i++) {
            BodyPart p = mult.getBodyPart(i);
            Object content2 = p.getContent();
            %><div class="well" style="margin-top:15px">Part <%=(i+1)%> of <%=mult.getCount()%> </div>
            <div class="emailbox"><%
            if (content2 instanceof String) {
                out.write((String)content2);
            }
            else {
                out.write("Attachment: <a href=\"attachRaw.jsp?msg="+URLEncoder.encode(selectedName)+"&mailType="+mailType+"&attach="+i+"\">");
                HTMLWriter.writeHtml(out, p.getFileName());
                out.write("</a>");
                if (p.getDescription()!=null) {
                    out.write("\n<br/>Description: ");
                    HTMLWriter.writeHtml(out, p.getDescription());
                }
                out.write("\n<br/>Size: "+p.getSize());
            }
            %></div><%
        }
    }
%>
</div>

<div style="height:100px"></div>

</body>
</html>

<%!

public void writeArray(Writer out, Address[] array) throws Exception  {
    for (int i=0; i<array.length; i++) {
        HTMLWriter.writeHtml(out, ((InternetAddress)array[i]).toUnicodeString());
        out.write(" ");
    }
}

%>