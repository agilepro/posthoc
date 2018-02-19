<%@page errorPage="error.jsp"
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
%><%@page import="javax.mail.Address"
%><%@page import="javax.mail.BodyPart"
%><%@page import="javax.mail.Multipart"
%><%@page import="javax.mail.Session"
%><%@page import="javax.mail.internet.MimeMessage"
%><%@page import="com.purplehillsbooks.posthoc.MailListener"
%><%@page import="com.purplehillsbooks.posthoc.EmailModel"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.MemFile"
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


    Properties props = new Properties();
    Session mSession = Session.getDefaultInstance(props);
    HTMLWriter hw = new HTMLWriter(out);
    FileInputStream fis = new FileInputStream(foundMsg);

    MimeMessage mm = new MimeMessage(mSession, fis);
    String stringBody = null;
    Multipart mult = null;

    Object content = mm.getContent();
    if (content instanceof String) {
        stringBody = (String)content;
    }
    else if (content instanceof Multipart) {
        mult = (Multipart)content;
    }

    Date mmSentDate = mm.getSentDate();


%><!DOCTYPE html>
<html>
<head>
<%@include file="Includes.jsp" %>

<script type="text/javascript">

var app = angular.module('myApp', ['textAngular']);
app.controller('myCtrl', ['$scope', '$http', '$window', 'textAngularManager', function myCtrl($scope, $http, $window, textAngularManager) {
    $scope.msg = {};
    $scope.mode = "Message";

    $scope.showError = false;
    $scope.errorMsg = "";
    $scope.errorTrace = "";
    $scope.showTrace = false;
    $scope.reportError = function(serverErr) {
        errorPanelHandler($scope, serverErr);
    };
    
    $scope.mailHeader = {
    		'from' : '<%writeArray(out, "", mm.getAllRecipients(), "");%>',
            'to' :  '<%writeArray(out, "", mm.getFrom(), "");%>',
            'subject' :  'RE: <%HTMLWriter.writeHtml(out, mm.getSubject());%>',
            'mailType': 'RE'
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
            	var url = "http://" + $window.location.host + "/" + res[1] + "/list.jsp";
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
<%
    if (stringBody!=null) {
        HTMLWriter.writeHtmlWithLines(out,stringBody);
    }
    else if (mult!=null) {

        %>

        <table class="table">
        <tr><td><b>From:</b> </td><td><input type="text" ng-model="mailHeader.from" /></td></tr>
        <tr><td><b>To:</b> </td><td><input type="text" ng-model="mailHeader.to" /></td></tr>       
        <tr><td><b>Subject:</b> </td><td><input type="text" ng-model="mailHeader.subject" /></td></tr>
        </table>
        <%
        for (int i=0; i<mult.getCount(); i++) {
            BodyPart p = mult.getBodyPart(i);
            Object content2 = p.getContent();
            %>           
            <div class="msgmain" text-angular="text-angular" name="htmlcontent" ng-model="mailContent">            
            __________________________________________________________________________________________________         
            <%writeArray(out, "<b>From:</b>", mm.getFrom(), "<br>");%>
            <%writeArray(out, "<b>To:</b>", mm.getAllRecipients(), "<br>");%>
            <%HTMLWriter.writeHtml(out, "<b>Date:</b> "+mmSentDate.toString()+"<br>");%>
            <%HTMLWriter.writeHtml(out, "<b>Subject:</b> "+mm.getSubject()+"<br><br>");%><%
            if (content2 instanceof String) {
                out.write((String)content2); 
            }
            else {
                out.write("Attachment: <a href=\"attachRaw.jsp?msg="+URLEncoder.encode(selectedName)+"&attach="+i+"\">");
                HTMLWriter.writeHtml(out, p.getFileName());
                out.write("</a>");
                if (p.getDescription()!=null) {
                    out.write("\n<br/>Description: ");
                    HTMLWriter.writeHtml(out, p.getDescription());
                }
                out.write("\n<br/>Size: "+p.getSize());
            }
            %></div><%
        }
    }
%>

</div>

        
<div style="height:100px"></div>
</body>
</html>

<%!

public void writeArray(Writer out, String lable, Address[] array, String newline) throws Exception  {
    for (int i=0; i<array.length; i++) {
        HTMLWriter.writeHtml(out, lable+" "+array[i].toString()+newline);
        out.write(" ");
    }
}

%>