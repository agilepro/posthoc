<%@page errorPage="error.jsp"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Date"
%><%@page import="java.util.List"
%><%@page import="java.util.Properties"
%><%@page import="javax.mail.Address"
%><%@page import="javax.mail.BodyPart"
%><%@page import="javax.mail.Multipart"
%><%@page import="javax.mail.Session"
%><%@page import="javax.mail.internet.MimeMessage"
%><%@page import="com.purplehillsbooks.posthoc.EmailModel"
%><%@page import="com.purplehillsbooks.posthoc.MailListener"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.MemFile"
%><%

    String selectedName = request.getParameter("msg");
    List<EmailModel> msgs = MailListener.listAllMessages();
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
    $scope.mode = "Message Text";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

});
</script>
</head>

<body ng-app="myApp" ng-controller="myCtrl" >
<%@include file="NavBar.jsp" %>
<%@include file="ErrorPanel.jsp"%>

<div class="msgmain">
<a href="list.jsp">
    <button class="iconbutton"><span class="glyphicon glyphicon-list"></span>
    <span>List</span>
    </button></a>
<span style="margin:20px"></span>
<a href="msgHtml.jsp?msg=<%=URLEncoder.encode(selectedName)%>">
    <button class="iconbutton"><span class="glyphicon glyphicon-font"></span>
    <span>Normal</span>
    </button></a>
<a href="msgTxt.jsp?msg=<%=URLEncoder.encode(selectedName)%>">
    <button class="iconbutton"><span class="glyphicon glyphicon-tags"></span>
    <span>HTML</span>
    </button></a>
<a href="msgRaw.jsp?msg=<%=URLEncoder.encode(selectedName)%>">
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

        <table  class="table">
        <tr><td>From: </td><td> <%writeArray(out, mm.getFrom());%></td></tr>
        <tr><td>To: </td><td> <%writeArray(out, mm.getAllRecipients());%></td></tr>
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
            %><div class="well">Part <%=(i+1)%> of <%=mult.getCount()%> </div>
            <div class="emailbox"><%
            if (content2 instanceof String) {
                %><tt><%
                HTMLWriter.writeHtmlWithLines(out,(String)content2);
                %></tt><%
            }
            else {
                out.write("\n<p>Content Type: "+content2.getClass().getName());
                out.write("\n<br/>File name: "+p.getFileName());
                out.write("\n<br/>Description: "+p.getDescription());
                out.write("\n<br/>Size: "+p.getSize()+"\n</p>");
            }
            %></div><%
        }
        %>
        <%
    }
%>

<div style="height:100px"></div>
</body>
</html>

<%!

public void SafeStrem() {

}

%>
<%!

public void writeArray(Writer out, Address[] array) throws Exception  {
    for (int i=0; i<array.length; i++) {
        HTMLWriter.writeHtml(out, array[i].toString());
        out.write(" ");
    }
}

%>