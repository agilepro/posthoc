<%@page errorPage="error.jsp"
%><%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.List"
%><%@page import="java.util.ArrayList"
%><%@page import="com.purplehillsbooks.posthoc.EmailModel"
%><%@page import="com.purplehillsbooks.posthoc.MailListener"
%><%@page import="com.purplehillsbooks.posthoc.SendMailListener"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
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