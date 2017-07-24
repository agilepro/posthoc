<%@page errorPage="error.jsp"
%><%@page import="java.io.File"
%><%@page import="java.util.Vector"
%><%@page import="java.util.List"
%><%@page import="java.util.Date"
%><%@page import="org.workcast.posthoc.EmailModel"
%><%@page import="org.workcast.posthoc.MailListener"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.workcast.json.JSONArray"
%><%@page import="org.workcast.json.JSONObject"
%><%@page import="java.text.SimpleDateFormat"
%><%

    List<EmailModel> msgs = MailListener.listAllMessages();

    SimpleDateFormat dFormat = new SimpleDateFormat("MMM dd - HH:mm:ss");

    int count = 0;
    JSONArray allMail = new JSONArray();
    for (EmailModel em : msgs) {
        File msg = em.filePath;
        String name = msg.getName();
        long timestamp=0;
        if (name.startsWith("email") && name.endsWith(".msg")) {
            String tVal = name.substring(5, name.length()-4);
            timestamp = Long.parseLong(tVal);
        }
        if (timestamp==0) {
            timestamp = msg.lastModified();
        }
        count++;
        JSONObject msgJO = new JSONObject();
        msgJO.put("name", name);
        msgJO.put("timestamp", timestamp);
        msgJO.put("subject", em.subject);
        msgJO.put("to", em.to);
        String from =  em.from;
        int anglePos1 = from.indexOf("<");
        int anglePos2 = from.indexOf(">");
        if (anglePos1>0 && anglePos2>anglePos1) {
            String justName = from.substring(0,anglePos1).trim();
            if (justName.startsWith("\"")) {
                justName = justName.replaceAll("\"", "");
            }
            msgJO.put("from", justName);
            msgJO.put("fromAddr", from.substring(anglePos1+1,anglePos2));
        }
        else {
            msgJO.put("from", from);
            msgJO.put("fromAddr", "");
        }
        allMail.put(msgJO);
    }


%><!DOCTYPE html>
<html>
<head>
<%@include file="Includes.jsp" %>

<script type="text/javascript">

var app = angular.module('myApp', []);
app.controller('myCtrl', function($scope, $http, $filter) {
    $scope.allMail = <% allMail.write(out, 2, 2); %>;
    $scope.mode = "List Messages";
    $scope.nowTime = new Date().getTime();

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };

    $scope.niceDatee = function(date) {
        var diff = $scope.nowTime - date;
        return "foo";
    }
    $scope.niceDate = function(date) {
        var diff = $scope.nowTime - date;
        if (diff>80000000) {
            return $filter('date')(date, "MMM d, y");
        }
        return $filter('date')(date, "h:mm:ss a");
    }
    $scope.go = function(row) {
        var dest = "msgHtml.jsp?msg="+row.name;
        window.location = dest;
    }

});
</script>
<style>
td {
    vertical-align: top;
    cursor:pointer;
}
tr:hover {
    background: #DEF;
}
</style>

</head>
<body ng-app="myApp" ng-controller="myCtrl" >
<%@include file="NavBar.jsp" %>
<%@include file="ErrorPanel.jsp"%>

<div class="msgmain">
<a href="list.jsp">
    <button class="iconbutton"><span class="glyphicon glyphicon-refresh"></span>
    <span>List</span>
    </button></a>
<span style="margin:20px"></span>
<a href="#">
    <button class="iconbutton-disabled"><span class="glyphicon glyphicon-font"></span>
    <span>Normal</span>
    </button></a>
<a href="#">
    <button class="iconbutton-disabled"><span class="glyphicon glyphicon-tags"></span>
    <span>HTML</span>
    </button></a>
<a href="#">
    <button class="iconbutton-disabled"><span class="glyphicon glyphicon-list-alt"></span>
    <span>Raw</span>
    </button></a>
</div>



<div style="margin:20px">
<table class="table" style="width:1050px">
<col width="80">
<col width="120">
<col width="120">
<col width="440">
<col width="100">

    <tr>
    <th></th>
    <th>From</th>
    <th>Date</th>
    <th>Subject</th>
    <th>To</th>
    </tr>

    <tr ng-repeat="row in allMail" ng-click="go(row)">
    <td>
    <span class="glyphicon glyphicon-font"></span>&nbsp;
    <span class="glyphicon glyphicon-tags"></span>&nbsp;
    <span class="glyphicon glyphicon-list-alt"></span>
    </td>
    <td>{{row.from}}</td>
    <td>{{niceDate(row.timestamp)}}</td>
    <td>{{row.subject}}</td>
    <td>{{row.to}}</td>
    </tr>

</table>
</div>

<div class="well" style="margin:10px">
<p>Total of <%=count%> messages.<br/>
Message files are stored for <%= MailListener.storageDays %> days before discarding.</p>
</div>

</body>
</html>
