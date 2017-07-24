<%@page errorPage="error.jsp"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.Reader"
%><%@page import="java.io.StringReader"
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
%><%@page import="org.workcast.posthoc.MailListener"
%><%@page import="org.workcast.posthoc.EmailModel"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.workcast.streams.MemFile"
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
    $scope.mode = "Message";

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

        <table class="table">
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
            %><div class="well" style="margin-top:15px">Part <%=(i+1)%> of <%=mult.getCount()%> </div>
            <div class="emailbox"><%
            if (content2 instanceof String) {
                out.write((String)content2);
            }
            else {
                out.write("Attachment: <a href=\"attachRaw.jsp?msg="+URLEncoder.encode(selectedName)+"&attach="+i+"\">");
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
        HTMLWriter.writeHtml(out, array[i].toString());
        out.write(" ");
    }
}

%>