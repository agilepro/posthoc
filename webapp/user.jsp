<%@page errorPage="error.jsp"
%><%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.posthoc.MailListener"
%><!DOCTYPE html>
<html>
<head>
<%@include file="Includes.jsp" %>

<script type="text/javascript">

var app = angular.module('myApp', []);
app.controller('myCtrl', function($scope, $http) {
    $scope.msg = {};
    $scope.mode = "Server Status";

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


  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h4 class="modal-title">Users in Post Hoc</h4>
      </div>
      <div class="modal-body">
        <p>There are no user settings for Post Hoc.</p>
        <p>There is no need to log in or out of Post Hoc.</p>
        <p>All email messages sent to Post Hoc (via SMTP) are displayed 
           in a single list called 'Inbox' showing
           the message subject, whom it was from, whom it is to, and the date of delivery.
           Post Hoc looks to an application like a normal email server, except that
           all messages are equally accessible to everyone, without having to log in, and
           without ever having to change users.</p>
        <p>All messages created in PostHoc to be picked up (using POP) are in another 
           list called 'Outbox'.
        <p>PostHoc is quite useful for demonstrations and testing 
           in order to see all of the email produced by an application,
           and to create email to be picked up by an application,
           and to keep email from ever escaping into the real world.
           Clearly Post Hoc is not intended for real production email use.</p>
      </div>
      <div class="modal-footer">
        <a href="list.jsp"><button type="button" class="btn btn-primary">Return to List</button></a>
      </div>
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->


</body>
</html>