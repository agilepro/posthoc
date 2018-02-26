<%@page errorPage="error.jsp"%>
<!DOCTYPE html>
<html>
<head>
<%@include file="Includes.jsp" %>

<script type="text/javascript">

var app = angular.module('myApp', ['textAngular']);
app.controller('myCtrl', ['$scope', '$http', '$window', 'textAngularManager', function myCtrl($scope, $http, $window, textAngularManager) {
    $scope.msg = {};
    $scope.mode = "Create Mail";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.mailHeader = {
    		'from' : '',
            'to' :  '',
            'subject' :  '',
            'mailType': ''
    };
   
    $scope.sendMail = function() {
        $http({
            url : 'servlet/send',
            method : "POST",
            data : {
                'from' :  $scope.mailHeader.from,
                'to' :  $scope.mailHeader.to,
                'subject' :  $scope.mailHeader.subject,
                'mailContent' :  $scope.mailContent,
                'mailType': $scope.mailHeader.mailType
            }
        }).then(function(response) {
            console.log(response.data);
            $scope.message = response.data;
            if($scope.message ==='Status : Mail sent succesfully'){
            	var res = $window.location.pathname.split("/");
            	var url = "http://" + $window.location.host + "/" + res[1] + "/outbox.jsp";
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
        <tr><td><b>From:</b> </td><td><input type="text" ng-model="mailHeader.from" /></td></tr>
        <tr><td><b>To:</b> </td><td><input type="text" ng-model="mailHeader.to" /></td></tr>       
        <tr><td><b>Subject:</b> </td><td><input type="text" ng-model="mailHeader.subject" /></td></tr>
        </table>
            
            <div class="msgmain" text-angular="text-angular" name="htmlcontent" ng-model="mailContent">            
            </div>

</div>

        
<div style="height:100px"></div>
</body>
</html>

