<%@page errorPage="error.jsp"
%><%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
%>
<!DOCTYPE html>
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
} ])
app.controller('myCtrl', ['$scope', '$http', '$window', 'textAngularManager', function myCtrl($scope, $http, $window, textAngularManager) {
    $scope.mailInfo = {};
    $scope.mode = "Create Mail";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    $scope.mailContent = "z <b>gg</b>xc";
    
    $scope.files = []; 
    $scope.getTheFiles = function ($files) {
        angular.forEach($files, function (value, key) {
            $scope.files.push(value);
        });
    };
    
    $scope.mailHeader = {
            'from' : '',
            'to' :  '',
            'subject' :  '',
            'mailType': ''
    };
    
    $scope.sendMail = function() {
        var jsonEncoded = JSON.stringify($scope.mailInfo);
        console.log("SENDING-1: ", jsonEncoded);
    	var hexEncoded = thoroughlyEncode(jsonEncoded);
        console.log("SENDING-2: ", hexEncoded, hexEncoded.length);
        $http({
            url : 'servlet/send',
            method : "POST",
            headers: { 'Content-Type': undefined },              
            transformRequest: function (data) {  
                var formData = new FormData();  
                formData.append("model", angular.toJson(data.model));  
                for (var i = 0; i < data.files.length; i++) {  
                    formData.append("file" + i, data.files[i]);  
                }  
                return formData;  
            },  
            data: { model: hexEncoded, files: $scope.files } 
        }).then(function(response) {
            console.log(response.data);
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
         <div class="msgmain" text-angular="text-angular" name="htmlcontent" ng-model="mailInfo.body"></div>
</div>
<div style="height:100px"></div>
</body>
</html>

