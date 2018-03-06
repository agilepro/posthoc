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
        try {
            Message message = new MimeMessage(Session.getInstance(System.getProperties()));
            message.setFrom(new InternetAddress(from));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSentDate(new Date());
            message.setSubject(subject);
            
            // create the message part 
            Multipart multipart = new MimeMultipart();
            multipart.addBodyPart(getMailBody(mailBody));
            // add attachments
            multipart = getAttachement(multipart, attachments);
            // integration
            message.setContent(multipart);
            // write to file
            message.writeTo(new FileOutputStream(getMailName()));
        }catch (Exception ex) {
        	throw new Exception("Send Mail Servlet: createMessage() ",ex);
		}
    }
    
    private static MimeBodyPart getMailBody(String body) throws Exception{
    	MimeBodyPart content = new MimeBodyPart();        
        content.setText(body);
        return content;
    }
    
    private static Multipart getAttachement(Multipart multipart, List<FileItem> attachments) throws Exception{
    	for(FileItem file : attachments) {
    		File newfile = new File(createTemp(PostHocServlet.getOutBoxFolder()+"/temp"), file.getName());
    		file.write(newfile);
            MimeBodyPart attachment = new MimeBodyPart();
            DataSource source = new FileDataSource(newfile);
            attachment.setDataHandler(new DataHandler(source));
            attachment.setFileName(file.getName());            
            multipart.addBodyPart(attachment);
        }
    	return multipart;
    }
    
    private static String createTemp(String dirPAth) throws Exception{
    	File theDir = new File(dirPAth);
    	
    	if (!theDir.exists()) {    	    
    	    try{
    	        theDir.mkdir();      	        
    	    } 
    	    catch(SecurityException se){
    	    	throw new Exception("Temp Directory not created ",se);
    	    }
    	}else
    		cleanupTemp(theDir);
    	return dirPAth;
    }
    
    private static void cleanupTemp(File filePath){
    	long earliestMailLimit = System.currentTimeMillis()-(60L*60*1000);
		File[] tempAttachments = filePath.listFiles();
        if (tempAttachments!=null) {
			for (File attachment : tempAttachments) {
				if (attachment.lastModified()<earliestMailLimit) {
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
						child.delete();
					}
				}
			}
		}

        List<EmailModel> theList =  EmailModel.getAllMessages(PostHocServlet.getOutBoxFolder());
        MailListener.sortEmail(theList);
        return theList;
    }
	

}
