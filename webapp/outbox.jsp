<%@page errorPage="error.jsp"
%><%@page import="java.io.File"
%><%@page import="java.util.Vector"
%><%@page import="java.util.List"
%><%@page import="java.util.Date"
%><%@page import="com.purplehillsbooks.posthoc.EmailModel"
%><%@page import="com.purplehillsbooks.posthoc.SendMailListener"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="java.text.SimpleDateFormat"
%><%

    List<EmailModel> msgs = SendMailListener.listAllOutboxMessages();

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
        var dest = "msgHtml.jsp?msg="+row.name+"&mailType=outbox";
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
<a href="outbox.jsp">
    <button class="iconbutton"><span class="glyphicon glyphicon-refresh"></span>
    <span>Outbox</span>
    </button></a>
<a href="list.jsp">
    <button class="iconbutton"><span class="fa fa-sign-in" style="font-size:24px"></span>
    <span>Inbox</span>
    </button></a>
<span style="margin:20px"></span>
<a href="newMail.jsp">
    <button class="iconbutton"><span class="fa fa-newspaper-o" style="font-size:24px"></span>
    <span>New Mail</span>
    </button></a>
</div>



<div style="margin:20px">
<table class="table" style="width:1050px">
<col width="100">
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

    <tr ng-repeat="row in allMail">
    <td>
    <span class="glyphicon glyphicon-font"  ng-click="go(row)"></span>&nbsp;
    <span class="glyphicon glyphicon-tags"  ng-click="go(row)"></span>&nbsp;
    <span class="glyphicon glyphicon-list-alt"  ng-click="go(row)"></span>
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
Message files are stored for <%= SendMailListener.storageDays %> days before discarding.</p>
</div>

</body>
</html>

