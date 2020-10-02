package com.purplehillsbooks.posthoc;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.Hashtable;
import java.util.List;
import java.util.Properties;
import java.util.Vector;

import javax.activation.DataHandler;
import javax.mail.Address;
import javax.mail.BodyPart;
import javax.mail.Message;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.HTMLWriter;

/**
 * A structure representing an email message file
 * This holds everything in memory
 * Attachments are loaded from the file on demand
 */
public final class EmailModel {

    public long timeStamp;
    public String from;
    public String to;
    public String subject;
    public String body;
    public File filePath;

    private static Hashtable<File, EmailModel> cache = new Hashtable<File, EmailModel>();

    public static synchronized EmailModel findMessage(File sFile) throws Exception {
        if (!sFile.exists()) {
            throw new JSONException("Unable to read an email message, file does not exist: {0}",sFile);
        }
        EmailModel em = cache.get(sFile);
        if (em!=null) {
            return em;
        }
        em = newMessage();
        em.filePath = sFile;
        String fileName = sFile.getName();
        em.timeStamp = Long.parseLong(fileName.substring(5, fileName.length()-4));
        em.loadFromFile();
        cache.put(sFile, em);
        return em;
    }

    public static synchronized EmailModel newMessage() {
        EmailModel em = new EmailModel();
        em.timeStamp = System.currentTimeMillis();
        em.from    = "";
        em.to      = "";
        em.subject = "";
        em.body    = "";
        return em;
    }


    public static Vector<EmailModel> getAllMessages(File containingFolder) throws Exception {
        if (containingFolder==null) {
            throw new JSONException("getAllMessages needs a containing folder parameter, got null");
        }
        if (!containingFolder.exists()) {
            throw new JSONException("getAllMessages containing folder does not exist at {0}", containingFolder);
        }
        Vector<EmailModel> ret = new Vector<EmailModel>();
        for (File existingFile : containingFolder.listFiles()) {
            if (properFilename(existingFile.getName())) {
                EmailModel em = findMessage(existingFile);
                ret.add(em);
            }
        }

        Collections.sort(ret, new EmailModelComparator());
        return ret;
    }

    public static Vector<EmailModel> getInbox() throws Exception {
        return getAllMessages(PostHocServlet.getDataFolder());
    }
    public static Vector<EmailModel> getOutbox() throws Exception {
        return getAllMessages(PostHocServlet.getOutBoxFolder());
    }
    public static EmailModel getInboxMessage(String name) throws Exception {
        for (File existingFile : PostHocServlet.getDataFolder().listFiles()) {
            if (name.equalsIgnoreCase(existingFile.getName())) {
                return findMessage(existingFile);
            }
        }
        return null;
    }
    public static EmailModel getOutboxMessage(String name) throws Exception {
        for (File existingFile : PostHocServlet.getOutBoxFolder().listFiles()) {
            if (name.equalsIgnoreCase(existingFile.getName())) {
                return findMessage(existingFile);
            }
        }
        return null;
    }


    private MimeMessage loadMimeMessage() throws Exception {
        if (filePath==null) {
            throw new JSONException("Cannot load message.  File member of EmailModel has not been set.");
        }
        if (!filePath.exists()) {
            throw new JSONException("Cannot load message.  File does not exist: {0}", filePath.getCanonicalPath());
        }
        Properties props = new Properties();
        Session mSession = Session.getDefaultInstance(props);
        FileInputStream fis = new FileInputStream(filePath);
        MimeMessage mm = new MimeMessage(mSession, fis);
        fis.close();
        return mm;
    }

    private void loadFromFile() throws Exception {
        MimeMessage mm = loadMimeMessage();
        from = convertFirstAddress(mm.getFrom());
        to = convertToCommaList(mm.getAllRecipients());
        subject = mm.getSubject();
        if (subject.length()>80) {
            subject = subject.substring(0,80);
        }
        body = "";  //in case it is not found

        Object content = mm.getContent();
        if (content instanceof String) {
            //in this case there is NO multipart, it is just
            //an email without any attachments
            body = (String)content;
            return;
        }
        if (!(content instanceof Multipart)) {
            throw new Exception("Don't understand object type ("+content.getClass().getCanonicalName()+") in file: "+filePath.getCanonicalPath());
        }
        Multipart mult = (Multipart)content;

        for (int i=0; i<mult.getCount(); i++) {
            BodyPart part = mult.getBodyPart(i);
            String disposition = part.getDisposition();
            boolean isAttachment = (disposition!=null && disposition.startsWith("attachment"));
            if (isAttachment) {
                //ignore the attachments at this time
                continue;
            }

            content = part.getContent();
            if (content instanceof String) {
                //in this case part is either text or html
                //not sure which.  We will choose the LAST that occurs in the file
                body = (String)content;
            }
        }
    }

    public EmailAttachment getAttachmentByName(String name) throws Exception{
        MimeMessage mm = loadMimeMessage();

        Object content = mm.getContent();
        if (content instanceof String) {
            //in this case there is NO multipart, it is just
            //an email without any attachments
            return null;
        }
        if (!(content instanceof Multipart)) {
            throw new Exception("Don't understand mail file because it is neither a String nor a Multipart: "+filePath.getCanonicalPath());
        }
        Multipart mult = (Multipart)content;

        for (int i=0; i<mult.getCount(); i++) {
            BodyPart part = mult.getBodyPart(i);
            String disposition = part.getDisposition();

            boolean isAttachment = (disposition!=null && disposition.startsWith("attachment"));
            if (!isAttachment) {
                continue;
            }
            String fileName = part.getFileName();
            if (!name.equalsIgnoreCase(fileName)) {
                continue;
            }

            EmailAttachment att = new EmailAttachment();
            att.name = fileName;
            att.debug = disposition;
            InputStream attStream = part.getInputStream();
            att.contents.fillWithInputStream(attStream);
            return att;
        }

        return null;
    }

    public List<EmailAttachment> loadAttachments() throws Exception{
        MimeMessage mm = loadMimeMessage();
        List<EmailAttachment> atts = new ArrayList<EmailAttachment>();

        Object content = mm.getContent();
        if (content instanceof String) {
            //in this case there is NO multipart, it is just
            //an email without any attachments
            return atts;
        }
        if (!(content instanceof Multipart)) {
            throw new Exception("Don't understand mail file because it is neither a String nor a Multipart: "+filePath.getCanonicalPath());
        }
        Multipart mult = (Multipart)content;

        for (int i=0; i<mult.getCount(); i++) {
            BodyPart part = mult.getBodyPart(i);
            String disposition = part.getDisposition();

            boolean isAttachment = (disposition!=null && disposition.startsWith("attachment"));
            if (!isAttachment) {
                continue;
            }
            String fileName = part.getFileName();
            /*
            int fileStart = disposition.indexOf("filename=\"")+10;
            if (fileStart>12) {
                int fileEnd = disposition.indexOf("\"", fileStart);
                if (fileEnd>fileStart) {
                    fileName = disposition.substring(fileStart, fileEnd);
                }
                else {
                    //should we complain?  Or go with a default?
                    fileName = "att"+System.currentTimeMillis()+".file";
                }
            }
            else {
                fileName = "att"+System.currentTimeMillis()+".file";
            }
            */

            EmailAttachment att = new EmailAttachment();
            att.name = fileName;
            att.debug = disposition;
            InputStream attStream = part.getInputStream();
            att.contents.fillWithInputStream(attStream);
            atts.add(att);
        }

        return atts;
    }


    public void writeToFile(List<EmailAttachment> attachments) throws Exception {
        try {
            Message message = new MimeMessage(Session.getInstance(System.getProperties()));

            message.setFrom(encodeAddress(from));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSentDate(new Date(timeStamp));
            message.setSubject(subject);

            // create the message part
            Multipart multipart = new MimeMultipart();

            MimeBodyPart bodyPart = new MimeBodyPart();
            bodyPart.setContent(body, "text/html; charset=utf-8");
            bodyPart.setHeader("Content-Type", "text/html; charset=utf-8");
            bodyPart.setHeader("Content-Transfer-Encoding", "8BIT");
            multipart.addBodyPart(bodyPart);

            // add attachments
            for(EmailAttachment att : attachments) {

                //The EmailAttachment object implements DataSource
                //so that it can be used directly below
                MimeBodyPart attachment = new MimeBodyPart();
                attachment.setDataHandler(new DataHandler(att));
                attachment.setFileName(att.getName());
                multipart.addBodyPart(attachment);
            }

            // integration
            message.setContent(multipart);

            //This is a strange magic call that must be made in order
            //for the content type to be correct
            message.saveChanges();

            // write to file
            FileOutputStream fos = new FileOutputStream(filePath);
            message.writeTo(fos);
            fos.flush();
            fos.close();
        }
        catch (Exception ex) {
            throw new JSONException("Unable to writeMessage (subject={0}) (file={1})", ex, subject, filePath.getCanonicalPath());
        }
    }

    private static InternetAddress encodeAddress(String source) throws Exception {
        //just in case someone typed multiple addresses in
        //only use the forst one
        int commaPos = source.indexOf(",");
        if (commaPos>0) {
            source = source.substring(0,commaPos);
        }
        commaPos = source.indexOf(";");
        if (commaPos>0) {
            source = source.substring(0,commaPos);
        }
        int anglePos = source.indexOf("<");
        int angleEnd = source.indexOf(">");
        InternetAddress iAdd;
        if (anglePos>0 && angleEnd>anglePos) {
            iAdd = new InternetAddress(source.substring(anglePos+1, angleEnd).trim(),
                    source.substring(0,anglePos).trim(), "UTF-8");
        }
        else {
            iAdd = new InternetAddress(source.trim());
        }
        return iAdd;
    }

    private static String convertFirstAddress(Address[] array) {
        for (Address oneAddress : array) {
            if (oneAddress instanceof InternetAddress) {
                return(((InternetAddress)oneAddress).toUnicodeString());
            }
            else {
                return(oneAddress.toString());
            }
        }
        return "";
    }
    private static String convertToCommaList(Address[] array) {
        StringBuffer res = new StringBuffer();
        for (Address oneAddress : array) {
            if (res.length()>0) {
                res.append(", ");
            }
            if (oneAddress instanceof InternetAddress) {
                res.append(((InternetAddress)oneAddress).toUnicodeString());
            }
            else {
                res.append(oneAddress.toString());
            }
        }
        return res.toString();
    }


    /**
     * The file must have a particular kind of name to be used as an email message file
     * Files with non-conforming names should be ignored ... they might be junk.
     * Pass just the file name in.
     */
    public static boolean properFilename(String fileName) {
        return fileName.startsWith("email") && fileName.endsWith(".msg");
    }

    /**
     * Call this method immediately after any files are deleted from the folder.
     *
     * We assume that the files do not change.  However, they do get deleted.
     * This does a garbage collect on the memory cache so that it does not
     * grow forever.  It scans the folder passed in for files with the proper
     * names, and creates a new cache with all the EmailModels for those files.
     * Will create new cache entries for new files found.  Files that have been
     * deleted will not be present in the new cache.  We don't reread the files
     * that are already cached, because the file contents should never change.
     */
    public static synchronized void refreshCache(File containingFolder) throws Exception {
        Hashtable<File, EmailModel> newCache = new Hashtable<File, EmailModel>();
        for (File existingFile : containingFolder.listFiles()) {
            if (properFilename(existingFile.getName())) {
                EmailModel em = findMessage(existingFile);
                newCache.put(existingFile,  em);
            }
        }
        cache = newCache;
    }

    private static class EmailModelComparator implements Comparator<EmailModel> {
        @Override
        public int compare(EmailModel arg0, EmailModel arg1) {
            //return Long.compare(arg0.received, arg1.received);
            if (arg0.timeStamp<arg1.timeStamp) {
                return -1;
            }
            else {
                return 1;
            }
        }
    }


    public JSONObject getJSON() throws Exception {
        JSONObject mailHeader = new JSONObject();
        mailHeader.put("from",    from);
        mailHeader.put("to",      to);
        mailHeader.put("subject", subject);
        mailHeader.put("body",    body);
        mailHeader.put("timeStamp", timeStamp);
        return mailHeader;
    }

    private String removeTagAt(String input, int pos) {
        int imgEnd = input.indexOf(">", pos);
        if (imgEnd>pos) {
            return input.substring(0, pos)+input.substring(imgEnd+1);
        }
        else {
            return input.substring(0, pos);
        }
    }

    public EmailModel createReply() throws Exception {

        //there is a problem with the text editor in that it can not handle
        //image tags, probably because they have to be loaded from a remote
        //site.   Since the editor does not really allow editing anything
        //with images in it, this action strips all the images out that
        //happen to be in the message.  This allows reply to work.
        String cleanedBody = body;
        int imgPos = cleanedBody.indexOf("<img");
        while (imgPos>=0) {
            cleanedBody = removeTagAt(cleanedBody, imgPos);
            imgPos = cleanedBody.indexOf("<img");
        }
        imgPos = cleanedBody.indexOf("<IMG");
        while (imgPos>=0) {
            cleanedBody = removeTagAt(cleanedBody, imgPos);
            imgPos = cleanedBody.indexOf("<IMG");
        }


        EmailModel reply = newMessage();
        reply.to = from;
        reply.subject = "RE: "+subject;

        StringWriter sw = new StringWriter();
        sw.write("\n<br/>\n<br/>\n-----------------------------------------------");
        sw.write("\n<div><b>From:</b>");
        HTMLWriter.writeHtml(sw, from);
        sw.write("</div>");
        sw.write("\n<div><b>To:</b>");
        HTMLWriter.writeHtml(sw, to);
        sw.write("</div>");
        sw.write("\n<div><b>Date:</b>");
        HTMLWriter.writeHtml(sw, new Date(timeStamp).toString());
        sw.write("</div>");
        sw.write("\n<div><b>Subject:</b>");
        HTMLWriter.writeHtml(sw, subject);
        sw.write("</div>");

        sw.write("\n<br/>\n<br/>");
        sw.write(cleanedBody);

        reply.body = sw.toString();

        return reply;
    }

    private static long lastUnique = System.currentTimeMillis();
    public static File generateOutboxName() throws Exception{
        long thisUnique = System.currentTimeMillis();

        if (thisUnique<=lastUnique) {
            thisUnique = ++lastUnique;
        }
        return new File(PostHocServlet.getOutBoxFolder(), "email"+thisUnique+".msg");
    }

}
