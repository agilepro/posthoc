<%@page errorPage="error.jsp"
%><%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
%><%@page import="com.purplehillsbooks.posthoc.EmailModel"
%><%@page import="com.purplehillsbooks.posthoc.MailListener"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
%><%@page import="com.purplehillsbooks.streams.MemFile"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
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
%><%

    request.setCharacterEncoding("utf-8");
    String selectedName = request.getParameter("msg");
    EmailModel foundMsg = EmailModel.getInboxMessage(selectedName);
    
    if (foundMsg==null) {
        throw new Exception("Can not find a message with name: "+selectedName);
    }
    
    JSONObject mailHeader = foundMsg.getJSON();
    
    EmailModel newReply = foundMsg.createReply();
    newReply.from = foundMsg.to;
    String bodyHtml = newReply.body;
    


%><!DOCTYPE html>
<html>
<head>
<%@include file="Includes.jsp" %>

<script type="text/javascript">



var app = angular.module('myApp', ['textAngular']);
app.directive('ngFiles', ['$parse', function ($parse) {

    function fn_link(scope, element, attrs) {
        var onChange = $parse(attrs.ngFiles);
        element.on('change', function (event) {
            onChange(scope, { $files: event.target.files });
        });
    };

    return {
        link: fn_link
    }
} ]);
app.controller('myCtrl', ['$scope', '$http', '$window', 'textAngularManager', function myCtrl($scope, $http, $window, textAngularManager) {
    
    $scope.mailInfo = <% newReply.getJSON().write(out, 2, 2); %>;
    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.files = []; 
    $scope.getTheFiles = function ($files) {
        angular.forEach($files, function (value, key) {
        	$scope.files.push(value);
        });
    };
    
    
    $scope.sendMail = function() {
        var jsonEncoded = JSON.stringify($scope.mailInfo);
    	var hexEncoded = thoroughlyEncode(jsonEncoded);
        $http({
            url : 'servlet/send',
            method : "POST",
            headers: {'Content-Type':undefined,"Content-Transfer-Encoding":"8bit"},              
            transformRequest: function (data) {  
                var formData = new FormData();  
                formData.append("model", angular.toJson(data.model));  
                for (var i = 0; i < data.files.length; i++) {  
                    formData.append("file" + i, data.files[i]);  
                }  
                console.log("FORMDATA: ", formData);
                return formData;  
            },  
            data: { model: hexEncoded, files: $scope.files } 
        }).then(function(response) {
            console.log("RESULT:", response);
            //confirm("ready to refresh?");
            $scope.message = response.data;
            if($scope.message.indexOf('email message stored')>0){
            	var url = "outbox.jsp";
                $window.location.href = url;
        	}
        }, function(response) {
            console.log(response);
            $scope.message = response;
        });
 
    };
}]);
</script>
</head>

<body ng-app="myApp" ng-controller="myCtrl" >
<%@include file="NavBar.jsp" %>
<%@include file="ErrorPanel.jsp"%>

<div class="msgmain">
<a href="list.jsp">
    <button class="iconbutton"><span class="fa fa-sign-in" style="font-size:24px"></span>
    <span>Inbox</span>
    </button></a>
<a href="list.jsp">
    <button class="iconbutton"><span class="fa fa-remove" style="font-size:24px"></span>
    <span>Cancel</span>
    </button></a>
<span style="margin:20px"></span>
<a ng-click="sendMail()">
    <button class="iconbutton"><span class="fa fa-send-o" style="font-size:24px"></span>
    <span>Send</span>
    </button></a>
</div>

<div class="msgmain">
    <table class="table">
        <tr><td><b>From:</b> </td><td><input type="text" ng-model="mailInfo.from" /></td></tr>
        <tr><td><b>To:</b> </td><td><input type="text" ng-model="mailInfo.to" /></td></tr>       
        <tr><td><b>Subject:</b> </td><td><input type="text" ng-model="mailInfo.subject" /></td></tr>
        <tr><td>Attachment:</td><td><input type="file" id="file1" name="file" multiple
            ng-files="getTheFiles($files)" /></td></tr>
    </table>
         <div class="msgmain" text-angular="text-angular" name="htmlcontent" ng-model="mailInfo.body"><%=bodyHtml%></div>

</div>

        
<div style="height:400px"></div>
</body>
</html>
