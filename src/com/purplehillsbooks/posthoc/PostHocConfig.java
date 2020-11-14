package com.purplehillsbooks.posthoc;

import java.io.File;
import java.io.FileInputStream;
import java.util.Properties;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.streams.StreamHelper;

/**
 * reads the config file into variables
 */
public final class PostHocConfig {

    public String hostName;
    public int    smtpPort  = 25;
    public int    popPort   = 110;
    public File   dataFolder;
    public String buildNumber;

    public PostHocConfig(File appFolder)  throws Exception {
        try {
            File webInfFolder = new File(appFolder, "WEB-INF");
            if (!webInfFolder.exists()) {
                throw new JSONException("The WEB-INF folder does not exist ({0})"
                        +"something must be wrong with the servlet configuration: ", webInfFolder.getAbsolutePath());
            }

            //READ the build number from the file
            File buildNumFile = new File(webInfFolder, "BuildInfo.properties");
            if (!buildNumFile.exists()) {
                throw new JSONException("The BuildInfo.properties file does not exist, "
                        +"something must be wrong with the servlet configuration: {0}", buildNumFile.getAbsolutePath());
            }
            Properties buildInfo = readProperties(buildNumFile);
            buildNumber = buildInfo.getProperty("BuildNumber");

            //READ the data location
            File dataLocFile = new File(webInfFolder, "DataLocation.properties");
            if (!dataLocFile.exists()) {
                throw new JSONException("The DataLocation.properties file does not exist, "
                        +"something must be wrong with the servlet configuration: {0}", dataLocFile.getAbsolutePath());
            }
            Properties props = readProperties(dataLocFile);

            String dataFolderStr = props.getProperty("dataFolder");
            if (dataFolderStr==null) {
                dataFolderStr="/opt/PostHocData/";
            }
            dataFolder = new File(dataFolderStr);
            if (!dataFolder.exists()) {
                dataFolder.mkdirs();
                if (!dataFolder.exists()) {
                    throw new JSONException("The PostHoc data folder does not exist, "
                            +"and the server is unable to create it: {0}",dataFolder.getAbsolutePath());
                }
                System.out.println("PostHoc server created the data folder as: "+dataFolder.toString());
            }
            if (!dataFolder.isDirectory()) {
                throw new JSONException("The PostHoc data folder appears to be a file, must be a directory/folder: {0}",
                       dataFolder.getAbsolutePath());
            }

            File realConfigFile = new File(dataFolder, "Config.properties");
            if (!realConfigFile.exists()) {
                File protoConfigFile = new File(webInfFolder, "Config.properties.prototype");
                StreamHelper.copyFileToFile(protoConfigFile, realConfigFile);
            }
            if (!realConfigFile.exists()) {
                throw new JSONException("Unable to create PostHoc config file from WEB-INF to the data folder: {0}",
                        realConfigFile.getAbsolutePath());
            }

            props = readProperties(realConfigFile);

            hostName = props.getProperty("hostName");
            if (hostName==null) {
                hostName="127.0.0.1";
            }

            String smtpPortStr = props.getProperty("smtpPort");
            if (smtpPortStr==null) {
                //we used to call it this, so check if maybe the old value it there
                smtpPortStr = props.getProperty("hostPort");
            }
            if (smtpPortStr!=null) {
                smtpPort = Integer.parseInt(smtpPortStr);
            }

            String popPortStr = props.getProperty("popPort");
            if (popPortStr!=null) {
                popPort = Integer.parseInt(popPortStr);
            }

            System.out.println("PostHoc CONFIGURATION: "+hostName+":"+smtpPort+":"+popPort+"  -- Data folder: "+dataFolder);
        }
        catch (Exception e) {
            throw new JSONException("PostHoc CONFIGURATION: Unable to configure PostHoc at initialization time",e);
        }
    }

    private static Properties readProperties(File filePath) throws Exception {
        if (!filePath.exists()) {
            throw new JSONException("The properties file does not exist at {0}", filePath.getAbsolutePath());
        }
        Properties props = new Properties();
        FileInputStream fis = new FileInputStream(filePath);
        props.load(fis);
        fis.close();
        return props;
    }

}
