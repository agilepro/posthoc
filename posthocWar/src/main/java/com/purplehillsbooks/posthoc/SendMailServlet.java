package com.purplehillsbooks.posthoc;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.nio.charset.StandardCharsets;

import jakarta.servlet.ServletException;
import org.apache.commons.fileupload2.core.FileItem;
import org.apache.commons.fileupload2.core.DiskFileItemFactory;
import org.apache.commons.fileupload2.jakarta.servlet6.JakartaServletFileUpload;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;

public class SendMailServlet extends jakarta.servlet.http.HttpServlet {

    private static final long serialVersionUID = 1L;
    public static Exception fatalServerError;
    int counter;

    @Override
    public void init() {
        System.out.println("START POSTHOC - HttpService.init called");
    }
    @Override
    public void destroy() {
        System.out.println("STOP POSTHOC - HttpService.destroy called");
    }

    @Override
    public void doGet(jakarta.servlet.http.HttpServletRequest req, jakarta.servlet.http.HttpServletResponse resp) {
        //do nothing
    }

    @Override
    public void doPost(jakarta.servlet.http.HttpServletRequest request, jakarta.servlet.http.HttpServletResponse response) throws IOException, ServletException {
        request.setCharacterEncoding("UTF-8");

        String sendStatus = "";
        String fieldValue = null;
        List<EmailAttachment> attList = new ArrayList<EmailAttachment>();
        try {
            List<FileItem> fileItemList = new JakartaServletFileUpload(DiskFileItemFactory.builder().get()).parseRequest(request);
            for(FileItem item : fileItemList){
                if(item.isFormField()){
                    String hexEncodedValue = item.getString(StandardCharsets.UTF_8);
                    fieldValue = hexDecode(hexEncodedValue);
                }
                else {
                    EmailAttachment eatt = new EmailAttachment();
                    eatt.name = item.getName();
                    eatt.contentType = item.getContentType();
                    eatt.contents.fillWithInputStream(item.getInputStream());
                    attList.add(eatt);
                }
            }
            if (fieldValue==null) {
                throw new Exception("Was not able to find the Email Message JSON structure");
            }
            JSONObject jObj = new JSONObject(new JSONTokener(fieldValue));

            EmailModel em = EmailModel.newMessage();
            em.from = jObj.getString("from");
            em.to   = jObj.getString("to");
            em.subject = jObj.getString("subject");
            em.body = jObj.getString("body");
            em.filePath = EmailModel.generateOutboxName();

            em.writeToFile(attList);

            sendStatus = "email message stored in outbox: "+em.filePath;
            System.out.println("POSTHOC SEND MAIL: email message stored in outbox: "+em.filePath);
        }
        catch (Exception e) {
            sendStatus = "Mail not saved in outbox: " + e.getMessage();
            e.printStackTrace(System.out);
        }

        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("Status : " + sendStatus);
    }

    /**
     * Expecting data in this form:
     *
     * AACCAADOAADMAACPAAGBAADOAACGAAGOAAGCAAHDAAHAAADLAADMAACPAAHEAAGEAADO
     * AADMAAHEAAGEAADOAADMAAGBAACAAAGIAAHCAAGFAAGGAADNAAFMAACCAAGIAAHEAAHE
     * AAHAAADKAACPAACPAAGCAAGPAAGCAAGDAAGBAAHEAADKAADIAADAAADIAADAAACPAAGD
     * AAGHAADCAACPAAHEAACPAAGNAAGBAAHIAAGJAAHHAAGPAAHCAAGMAAGEAACPAAGNAAGG
     * AAGHAAGFAAGBAAHDAAHEAACPAAHEAAGBAAHDAAGLAADAAADEAADCAADIAACOAAGIAAHE
     *
     * Every four hex digits (e.g. AACC) is a character.   Not compact,
     * but at least we will get on the server the exact string that was in the browser.
     */
    private String hexDecode(String input) {
        StringBuilder sb = new StringBuilder();
        OnlyCaps oc = new OnlyCaps(input);
        while (oc.hasMore) {
            int val = oc.readNext();
            val = (val*16) + oc.readNext();
            val = (val*16) + oc.readNext();
            val = (val*16) + oc.readNext();
            sb.append((char) val);
        }
        return sb.toString();
    }

    private class OnlyCaps {
        String input;
        int pos = 0;
        boolean hasMore = true;
        char next;

        public OnlyCaps(String _input) {
            input = _input;
            fetch();
        }

        public int readNext() {
            if (!hasMore) {
                return -1;
            }
            int val = next-'A';
            fetch();
            return val;
        }

        private void fetch() {
            if (pos<input.length()) {
                next = input.charAt(pos++);
                while (pos<input.length() && (next<'A' || next>'P')) {
                    next = input.charAt(pos++);
                }
            }
            hasMore = pos<input.length();
        }
    }
}
