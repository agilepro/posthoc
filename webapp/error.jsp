<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page isErrorPage="true"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="java.io.PrintWriter"
%><%

    if (exception == null) {
        exception = new Exception("<<Unknown exception arrived at the error page ... this should never happen. The exception variable was null.>>");
    }
    String msg = exception.toString();

    //get rid of pointless name of exception class that appears in 99% of cases
    if (msg.startsWith("java.lang.Exception: "))
    {
        msg = msg.substring(21);
    }
%>

<H1>Oops ... difficulty handling that request</H1>

<p>Something went wrong trying to handle that request.
It might be something simple on the last page that you can
go back and fix.  Or it might be a problem with the server
configuration that needs to be addressed by the administrator.
The following message might contain useful information about the problem</p>

<ul>
<%
    Throwable runner = exception;
    while (runner!=null)
    {
        msg = runner.toString();
        if (msg.startsWith("java.lang.Exception: "))
        {
            msg = msg.substring(21);
        }
        %><li><%
        HTMLWriter.writeHtmlWithLines(out,msg);
        runner = runner.getCause();
        %></li><%
    }
%>
</ul>
<br/>
<pre>
<% out.flush(); %>
<% exception.printStackTrace(new PrintWriter(new HTMLWriter(out))); %>
</pre>
