package com.purplehillsbooks.posthoc;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.activation.DataSource;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.MemFile;

public class EmailAttachment implements DataSource {

    public String contentType = "application/octet-stream";
    public String name;
    public MemFile contents;
    public String debug;

    public EmailAttachment() throws Exception {
        contents = new MemFile();
    }

    @Override
    public String getContentType() {
        return contentType;
    }

    @Override
    public InputStream getInputStream() throws IOException {
        return contents.getInputStream();
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public OutputStream getOutputStream() throws IOException {
        return contents.getOutputStream();
    }

    public JSONObject listingJSON() throws Exception {
        JSONObject res = new JSONObject();
        res.put("name",  name);
        res.put("debug",  debug);
        res.put("size",  contents.totalBytes());
        return res;
    }

}
