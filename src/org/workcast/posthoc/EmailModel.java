package org.workcast.posthoc;

import java.io.File;
import java.io.FileInputStream;
import java.util.Collections;
import java.util.Hashtable;
import java.util.Properties;
import java.util.Vector;

import javax.mail.Address;
import javax.mail.Session;
import javax.mail.internet.MimeMessage;

import java.util.Comparator;

/**
 * A structure representing metadata about an email message file
 */
public final class EmailModel {

    public long received;
    public String from;
    public String to;
    public String subject;
    public File filePath;

    private static Hashtable<File, EmailModel> cache = new Hashtable<File, EmailModel>();

    public static synchronized EmailModel findMessage(File sFile) throws Exception {
        EmailModel em = cache.get(sFile);
        if (em!=null) {
            return em;
        }
        if (!sFile.exists()) {
            throw new Exception("Unable to read an email message from a file that does not exist: "+sFile);
        }
        em = new EmailModel();
        em.filePath = sFile;
        String fileName = sFile.getName();
        em.received = Long.parseLong(fileName.substring(5, fileName.length()-4));

        MimeMessage mm = em.readMimeMessage();
        em.from = getFortyCharactersOfList(mm.getFrom());
        em.to = getFortyCharactersOfList(mm.getAllRecipients());
        em.subject = mm.getSubject();
        if (em.subject.length()>80) {
            em.subject = em.subject.substring(0,80);
        }
        cache.put(sFile, em);
        return em;
    }

    public static Vector<EmailModel> getAllMessages(File containingFolder) throws Exception {
        Vector<EmailModel> ret = new Vector<EmailModel>();
        for (File existingFile : containingFolder.listFiles()) {
            if (properFilename(existingFile.getName())) {
                EmailModel em = findMessage(existingFile);
                ret.add(em);
            }
        }
        //ret.sort(new EmailModelComparator());
        Collections.sort(ret, new EmailModelComparator());
        return ret;
    }

    public MimeMessage readMimeMessage() throws Exception {
        Properties props = new Properties();
        Session mSession = Session.getDefaultInstance(props);
        FileInputStream fis = new FileInputStream(filePath);
        MimeMessage mm = new MimeMessage(mSession, fis);
        fis.close();
        return mm;
    }

    private static String getFortyCharactersOfList(Address[] array) {
        StringBuffer sb = new StringBuffer();
        for (int i=0; i<array.length; i++) {
            sb.append(array[i].toString());
            sb.append(" ");
        }
        //if (sb.length()>40) {
        //    return sb.substring(0,40);
        //}
        //else {
            return sb.toString();
        //}
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
            if (arg0.received<arg1.received) {
                return -1;
            }
            else {
                return 1;
            }
        }
    }
}
