package com.purplehillsbooks.posthoc;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Date;
import java.util.List;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.activation.FileDataSource;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Multipart;
import javax.mail.Session;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;

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
    public static void saveEmail(String from, String to, String subject, String mailBody, List<File> attachments, String mailType) throws Exception {

        synchronized (SendMailListener.class) {
        	createMessage(from, to, subject, mailBody, attachments, mailType);
        }
    }

    
    public static void createMessage(String from, String to, String subject, String mailBody, List<File> attachments, String mailType) throws Exception {
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
        } catch (MessagingException ex) {
        	throw new Exception("Send Mail Servlet: createMessage(): MessagingException ",ex);
        } catch (IOException ex) {
        	throw new Exception("Send Mail Servlet: createMessage(): IOException ",ex);
        } catch (Exception ex) {
        	throw new Exception("Send Mail Servlet: createMessage() ",ex);
		}
    }
    
    private static MimeBodyPart getMailBody(String body) throws Exception{
    	MimeBodyPart content = new MimeBodyPart();        
        content.setText(body);
        return content;
    }
    
    private static Multipart getAttachement(Multipart multipart, List<File> attachments) throws MessagingException{
    	for(File file : attachments) {
            MimeBodyPart attachment = new MimeBodyPart();
            DataSource source = new FileDataSource(file);
            attachment.setDataHandler(new DataHandler(source));
            attachment.setFileName(file.getName());
            multipart.addBodyPart(attachment);
        }
    	return multipart;
    }
    
    
    private static File getMailName() throws Exception{
    	long thisUnique = System.currentTimeMillis();

        if (thisUnique<=lastUnique) {
            thisUnique = ++lastUnique;
        }        
        return new File(SendMailServlet.getOutBoxFolder(), "email"+thisUnique+".msg");
    }
   
    /**
     * scans for and returns all the files that represent email messages.
     * @deprecated - use listAllMessages  instead
     *
    public static List<File> listAllEmails() throws Exception {
        List<File> res = new ArrayList<File> ();
        for (EmailModel em : listAllMessages()) {
			res.add(em.filePath);
		}
        return res;
    }
    */

    /**
     * scans for and returns all the files that represent email messages.
     */
    public static List<EmailModel> listAllOutboxMessages() throws Exception {

        //scan for and eliminate any OLD messages hanging around
        long earliestMailLimit = System.currentTimeMillis()-(24L*60*60*1000*storageDays);
		File[] children = SendMailServlet.getOutBoxFolder().listFiles();
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

        List<EmailModel> theList =  EmailModel.getAllMessages(SendMailServlet.getOutBoxFolder());
        MailListener.sortEmail(theList);
        return theList;
    }
	

}
