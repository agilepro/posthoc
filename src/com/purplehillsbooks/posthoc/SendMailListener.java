package com.purplehillsbooks.posthoc;

import java.io.File;
import java.io.FileOutputStream;
import java.util.Date;
import java.util.List;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.activation.FileDataSource;
import javax.mail.Message;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;

import org.apache.commons.fileupload.FileItem;

import com.purplehillsbooks.json.JSONException;

/**
 * Listens to outgoing emails .
 */
public class SendMailListener {

    //used to generate unique ids for the messages as they come in
    private static long lastUnique = System.currentTimeMillis();
    public static int storageDays = 5;

    public SendMailListener() {

    }

    /**
     * Saves outgoing email in file system and notifies observers.
     *
     * @param from the user who send the email.
     * @param to the recipient of the email.
     * @param data an InputStream object containing the email.
     * @see com.nilhcem.fakesmtp.gui.MainPanel#addObservers to see which observers will be notified
     */
    public static void saveEmail(String from, String to, String subject, String mailBody, List<FileItem> attachments, String mailType) throws Exception {

        synchronized (SendMailListener.class) {
            createMessage(from, to, subject, mailBody, attachments, mailType);
        }
    }


    public static void createMessage(String from, String to, String subject, String mailBody, List<FileItem> attachments, String mailType) throws Exception {
        File newMessageName = getMailName();
        try {
            Message message = new MimeMessage(Session.getInstance(System.getProperties()));
            int anglePos = from.indexOf("<");
            int angleEnd = from.indexOf(">");
            InternetAddress iAdd;
            if (anglePos>0 && angleEnd>anglePos) {
                iAdd = new InternetAddress(from.substring(anglePos+1, angleEnd).trim(),
                             from.substring(0,anglePos).trim(), "UTF-8");
            }
            else {
                iAdd = new InternetAddress(from.trim());
            }
            message.setFrom(getEncodedAddress(from));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSentDate(new Date());
            message.setSubject(subject);

            // create the message part
            Multipart multipart = new MimeMultipart();
            MimeBodyPart bodyPart = getMailBody(mailBody);
            bodyPart.setHeader("Content-Type", "text/html; charset=utf-8");
            bodyPart.setHeader("Content-Transfer-Encoding", "8BIT");
            multipart.addBodyPart(bodyPart);

            // add attachments
            multipart = getAttachement(multipart, attachments);
            // integration
            message.setContent(multipart);

            //This is a strange magic call that must be made in order
            //for the content type to be correct
            message.saveChanges();

            // write to file
            FileOutputStream fos = new FileOutputStream(newMessageName);
            message.writeTo(fos);
            fos.flush();
            fos.close();
        }catch (Exception ex) {
            throw new JSONException("Unable to createMessage (subject={0}) (file={1})", ex, subject, newMessageName.getCanonicalPath());
        }
    }

    private static InternetAddress getEncodedAddress(String source) throws Exception {
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

    private static MimeBodyPart getMailBody(String body) throws Exception{
        MimeBodyPart content = new MimeBodyPart();
        content.setContent(body, "text/html; charset=utf-8");
        return content;
    }

    private static Multipart getAttachement(Multipart multipart, List<FileItem> attachments) throws Exception{
        File tempFolder = PostHocServlet.getTempFolder();
        for(FileItem fileContent : attachments) {
            File tempFile = new File(tempFolder, fileContent.getName()+System.currentTimeMillis());
            fileContent.write(tempFile);
            MimeBodyPart attachment = new MimeBodyPart();
            DataSource source = new FileDataSource(tempFile);
            attachment.setDataHandler(new DataHandler(source));
            attachment.setFileName(fileContent.getName());
            multipart.addBodyPart(attachment);
            tempFile.delete();

            //TODO: can probably rewrite this to keep it all in memory with MemFile
        }
        cleanupTemp(tempFolder);
        return multipart;
    }


    private static void cleanupTemp(File filePath){
        long earliestMailLimit = System.currentTimeMillis()-(60L*60*1000);
        File[] tempAttachments = filePath.listFiles();
        if (tempAttachments!=null) {
            for (File attachment : tempAttachments) {
                if (attachment.lastModified()<earliestMailLimit) {
                    System.out.println("POP Attachment Deleted: "+attachment.getAbsolutePath());
                    attachment.delete();
                }
            }
        }
    }

    private static File getMailName() throws Exception{
        long thisUnique = System.currentTimeMillis();

        if (thisUnique<=lastUnique) {
            thisUnique = ++lastUnique;
        }
        return new File(PostHocServlet.getOutBoxFolder(), "email"+thisUnique+".msg");
    }


    /**
     * scans for and returns all the files that represent email messages.
     */
    public static List<EmailModel> listAllOutboxMessages() throws Exception {

        //scan for and eliminate any OLD messages hanging around
        long earliestMailLimit = System.currentTimeMillis()-(24L*60*60*1000*storageDays);
        File[] children = PostHocServlet.getOutBoxFolder().listFiles();
        if (children!=null) {
            //if the folder is empty, a null is returned.  So only iterate if non null.
            for (File child : children) {

                //while scanning the folder, we simply check the timeout.
                //any file older than the timeout is simply deleted, and
                //go on to the next file
                if (child.lastModified()<earliestMailLimit) {
                    if (EmailModel.properFilename(child.getName())) {
                        System.out.println("OUTBOX Email Deleted: "+child.getAbsolutePath());
                        child.delete();
                    }
                }
            }
        }

        List<EmailModel> theList =  EmailModel.getAllMessages(PostHocServlet.getOutBoxFolder());
        MailListener.sortEmail(theList);
        return theList;
    }


    /**
     * Deletes all sent emails from file system.
     */
    public static void deleteOutboxEmails() throws Exception {
        File[] children = PostHocServlet.getOutBoxFolder().listFiles();
        for (File child : children) {
            String name = child.getName();
            if (name.startsWith("email") && name.endsWith(".msg")) {
                System.out.println("OUTBOX Email Deleted: "+child.getAbsolutePath());
                child.delete();
            }
        }
    }

}
