<%@page errorPage="error.jsp"
%><%@page import="java.io.File"
%><%@page import="java.util.List"
%><%@page import="com.purplehillsbooks.posthoc.MailListener"
%><%@page import="com.purplehillsbooks.posthoc.SendMailListener"
%><%

    String check = request.getParameter("check");

    if (check!=null && "yes".equals(check)) {
         MailListener.deleteEmails();
         SendMailListener.deleteOutboxEmails();
         response.sendRedirect("list.jsp");
         return;
     }
%>
<p>Something went wrong if you are seeing this...</p>