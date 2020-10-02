<%@page errorPage="error.jsp"
%><%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
%><%@page import="com.purplehillsbooks.posthoc.EmailModel"
%><%@page import="com.purplehillsbooks.posthoc.EmailAttachment"
%><%@page import="com.purplehillsbooks.posthoc.MailListener"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
%><%@page import="com.purplehillsbooks.streams.MemFile"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.Reader"
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
%><%

    String selectedName = request.getParameter("msg");
	String mailType = request.getParameter("mailType");
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


    JSONArray atts = new JSONArray();
    for (EmailAttachment eatt : foundMsg.loadAttachments()) {
        atts.put(eatt.listingJSON());
    }
    String foundbody = foundMsg.body;

    HTMLWriter hw = new HTMLWriter(out);

%><!DOCTYPE html>
<html>
<head>
<%@include file="Includes.jsp" %>

<script type="text/javascript">

var app = angular.module('myApp', []);
app.controller('myCtrl', function($scope, $http) {
    $scope.msg = {};
    $scope.mode = "Message Text";
    $scope.mailType = "<%JavaScriptWriter.encode(out, mailType);%>";
    $scope.mailInfo = <% foundMsg.getJSON().write(out, 2, 2); %>;
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


    <table class="table">
    <tr><td>From: </td><td> {{mailInfo.from}}</td></tr>
    <tr><td>To: </td><td> {{mailInfo.to}}</td></tr>
    <tr><td>Date: </td><td> {{mailInfo.timeStamp | date}}</td></tr>
    <tr><td>Subject: </td><td> {{mailInfo.subject}}</td></tr>
    </table>
    
    <div class="well" style="margin-top:15px">Body</div>
    <div class="emailbox"><% HTMLWriter.writeHtmlWithLines(out, foundbody); %></div>
    
    <div ng-repeat="att in atts">
      <div class="well" style="margin-top:15px">Attachment</div>
      <div class="emailbox">
        Attachment: <a href="attachRaw.jsp?msg={{selectedName}}&mailType={{mailType}}&attach={{att.name}}">{{att.name}}</a>
        <br/>
        Size: {{att.size}}
      </div>
    </div>

</div>

<div style="height:100px"></div>

</body>
</html>
