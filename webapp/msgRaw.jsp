<%@page errorPage="error.jsp"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.List"
%><%@page import="org.workcast.posthoc.EmailModel"
%><%@page import="org.workcast.posthoc.MailListener"
%><%@page import="org.workcast.streams.HTMLWriter"
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
    FileInputStream fis = new FileInputStream(foundMsg);
    InputStreamReader isr = new InputStreamReader(fis, "UTF-8");
    HTMLWriter hw = new HTMLWriter(out);

%><!DOCTYPE html>
<html>
<head>
<%@include file="Includes.jsp" %>

<script type="text/javascript">

var app = angular.module('myApp', []);
app.controller('myCtrl', function($scope, $http) {
    $scope.msg = {};
    $scope.mode = "Message Raw";

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
<div class="emailbox">
<tt>
<%
    int ch = isr.read();
    while (ch>0) {
        if (ch=='\n') {
            out.write("<br/>\n");
        }
        else {
            hw.write((char) ch);
        }
        ch = isr.read();
    }
%>
</tt>
</div>
</div>

<div style="height:100px"></div>
</body>
</html>