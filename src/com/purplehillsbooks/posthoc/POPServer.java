package com.purplehillsbooks.posthoc;

import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.streams.StreamHelper;
import com.purplehillsbooks.xml.Mel;

public class POPServer extends Thread {

    public static POPServer theOneBigPopServer;
    public static int popPort = 110;
    public static File outBoxFolder = null;

    List<File> messagesForThisSession;

    public static void startListening(PostHocConfig phConfig) throws Exception {
        popPort = phConfig.popPort;
        outBoxFolder = new File(phConfig.dataFolder, "outbox");
        System.out.println("PostHoc POP: starting, port="+popPort+", folder="+outBoxFolder);
        theOneBigPopServer = new POPServer();
        new Thread(theOneBigPopServer).start();
    }

    public void run() {
        int count = 50;  //if we get a lot of exceptions, stop after 50
        while (--count > 0) {
            try {
                Thread.sleep(10000);  //wait 10 seconds before starting
                handleRequests();
            }
            catch (Exception e) {
                JSONException.traceException(e,"POP SERVER: -- EXCEPTION --");
            }
        }
    }

    private void handleRequests() throws Exception {
        ServerSocket mySS = new ServerSocket(popPort);
        try {
            while(mySS.isBound()) {

                Socket SS_accept = mySS.accept();
                //System.out.println("POP Server: socket accepted "+popPort);

                OutputStream os = SS_accept.getOutputStream();
                OutputStreamWriter w = new OutputStreamWriter(os, "UTF-8");

                //System.out.println("POP Server: sending +OK POP3 server ready");
                w.write("+OK POP3 server ready\n");
                w.flush();

                //These are read once so that the numbering stays constant
                //over the duration of the session.
                messagesForThisSession = this.getMessageList();

                InputStream is = SS_accept.getInputStream();
                InputStreamReader r = new InputStreamReader(is, "UTF-8");

                String inputLine = readLine(r);
                //System.out.println("POP Server input: "+inputLine);
                while (inputLine.length()>0) {
                    handleCommand(inputLine, w);
                    inputLine = readLine(r);
                    //System.out.println("POP Server input: "+inputLine);
                }
                w.close();
                r.close();
                //System.out.println("POP Server: closing port");
                SS_accept.close();
            }
        }
        finally {
            mySS.close();
        }
    }


    private void handleCommand(String cmd, Writer w) throws Exception {
        try {
            String fourLetters = cmd.substring(0,4).toUpperCase();
            StringBuilder retVal = new StringBuilder();
            System.out.println("POP: command: "+cmd);
            if ("CAPA".equals(fourLetters)) {
                retVal.append("+OK Capability list follows\r\n");
                retVal.append("RESP-CODES\r\n");
                retVal.append("USER\r\n");
                retVal.append(".\r\n");
            }
            else if ("USER".equals(fourLetters)) {
                //we don't really care which user since there is only one box
                retVal.append("+OK\r\n");
            }
            else if ("PASS".equals(fourLetters)) {
                //there are no users or passwords on PostHoc
                retVal.append("+OK\r\n");
            }
            else if ("QUIT".equals(fourLetters)) {
                //nothing really to shut down
                retVal.append("+OK\r\n");
            }
            else if ("NOOP".equals(fourLetters)) {
                //nothing really to shut down
                retVal.append("+OK\r\n");
            }
            else if ("STAT".equals(fourLetters)) {
                generateStatResults(retVal);
            }
            else if ("LIST".equals(fourLetters)) {
                generateListResults(retVal);
            }
            else if ("RETR".equals(fourLetters)) {
                int msgNo = getParamInt(cmd);
                sendFile(msgNo, w);
            }
            else if ("DELE".equals(fourLetters)) {
                int msgNo = getParamInt(cmd);
                deleteFile(msgNo, w);
            }
            else {
                retVal.append("-Don't understand: "+cmd+"\r\n");
            }
            String sret = retVal.toString();
            System.out.println("POP: response: \n"+sret+"\n");
            w.write(sret);
            w.flush();
        }
        catch (Exception e) {
            w.write("-ERR "+e.toString()+"\r\n");
            System.out.println("POP: -ERR "+e.toString()+"\r\n");
            w.flush();
        }
    }


    private String readLine(Reader r) throws Exception {
        StringBuilder line = new StringBuilder();
        int ch = r.read();
        while (ch==10 || ch==13) {
            //burn any left over CR or LF chars from last line
            ch = r.read();
        }
        while (ch!=10 && ch>=0) {
            if (ch>=32 && ch<128) {
                line.append((char)ch);
            }
            ch = r.read();
        }
        String s = line.toString();
        //System.out.println("PostHoc POP: read: "+s);
        return s;
    }

    private int getParamInt(String cmd) {
        int spacePos = cmd.indexOf(" ");
        if (spacePos<0) {
            return 0;
        }
        if (spacePos>=cmd.length()) {
            return 0;
        }
        int val = Mel.safeConvertInt(cmd.substring(spacePos+1));
        return val;
    }

    private List<File> getMessageList() {
        List<File> res = new ArrayList<File>();
        File[] children = outBoxFolder.listFiles();
        for(File child : children) {
            if (!child.isDirectory() && child.getName().endsWith(".msg")) {
                res.add(child);
            }
        }
        return res;
    }

    private void generateStatResults(StringBuilder sb) {
        //refresh the message list numbering every time this is called
        messagesForThisSession = this.getMessageList();

        int count=0;
        long size=0;
        for(File child : messagesForThisSession) {
            count++;
            size += child.length();
        }
        sb.append("+OK "+count+" "+size+"\r\n");
    }

    private void generateListResults(StringBuilder sb) {
        //refresh the message list numbering every time this is called
        messagesForThisSession = this.getMessageList();

        int count=0;
        sb.append("+OK "+messagesForThisSession.size()+" messages\r\n");
        count=0;
        for(File child : messagesForThisSession) {
            count++;
            sb.append(count+" "+child.length()+"\r\n");
        }
        sb.append(".\r\n");
    }

    private void sendFile(int msgNo, Writer w) throws Exception {
        if (msgNo>messagesForThisSession.size()) {
            w.write("-ERR bad message number "+msgNo+"\r\n");
            return;
        }
        File child = messagesForThisSession.get(msgNo-1);
        w.write("+OK "+child.length()+" octets\r\n");
        StreamHelper.copyFileToWriter(child, w, "UTF-8");
        w.write(".\r\n");
        System.out.println("POP SENT: "+child.getCanonicalPath());
    }
    private void deleteFile(int msgNo, Writer w) throws Exception {
        if (msgNo>messagesForThisSession.size()) {
            w.write("-ERR bad message number "+msgNo+"\r\n");
            return;
        }
        File child = messagesForThisSession.get(msgNo-1);
        child.delete();
        w.write("+OK message deleted\r\n");
        if (child.exists()) {
            throw new Exception("Tried but did not succeed in deleting file: "+child.getAbsolutePath());
        }
        System.out.println("POP DELETED: "+child.getCanonicalPath());
    }

}
