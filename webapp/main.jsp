<%@page errorPage="error.jsp"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.posthoc.PostHocServlet"
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
        <h4 class="modal-title">Server Status</h4>
      </div>
      <div class="modal-body">
<% if (PostHocServlet.phConfig!=null) { %>
        <p>You can send email to this server with the following settings:</p>
        <ul>
        <li>host:  <% HTMLWriter.writeHtml(out, PostHocServlet.phConfig.hostName ); %></li>
        <li>port:  <%=PostHocServlet.phConfig.hostPort%></li>
        </ul>
        <p>Message files will be stored for <%= MailListener.storageDays %> days in the folder:
        <tt><% HTMLWriter.writeHtml(out, PostHocServlet.getDataFolder().toString() ); %></tt></p>
        <p>You can delete all the messages now by pressing this button:</p>
        <p><a href="delete.jsp?check=yes">
            <button type="button" class="btn btn-danger">Delete All Mail</button>
            </a></p>
        <p>Running build version: <% HTMLWriter.writeHtml(out, PostHocServlet.phConfig.buildNumber ); %></p>
<% } else { %>
        <p>Server configuration problem: </p>
        <ul><%
            Throwable t = PostHocServlet.fatalServerError;
            while(t!=null) {
                %><li><%
                HTMLWriter.writeHtml(out, t.toString() );
                t=t.getCause();
                %></li><%
            }
            %></ul>
<% } %>
      </div>
      <div class="modal-footer">
        <a href="list.jsp"><button type="button" class="btn btn-primary">Return to List</button></a>
      </div>
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->


</body>
</html>