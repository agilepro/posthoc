package com.purplehillsbooks.posthoc;

import java.io.File;
import java.io.FileInputStream;
import java.util.Properties;

import com.purplehillsbooks.streams.StreamHelper;

/**
 * reads the config file into variables
 */
public final class PostHocConfig {

    public String hostName;
    public int    hostPort;
    public File   dataFolder;
    public String buildNumber;

    public PostHocConfig(File appFolder)  throws Exception {
        try {
            File webInfFolder = new File(appFolder, "WEB-INF");
            if (!webInfFolder.exists()) {
                throw new Exception("The WEB-INF folder does not exist, "
                        +"something must be wrong with the servlet configuration: "+webInfFolder.toString());
            }
            
            //READ the build number from the file
            File buildNumFile = new File(webInfFolder, "BuildInfo.properties");
            if (!buildNumFile.exists()) {
                throw new Exception("The BuildInfo.properties file does not exist, "
                        +"something must be wrong with the servlet configuration: "+buildNumFile.toString());
            }
            Properties buildInfo = readProperties(buildNumFile);
            buildNumber = buildInfo.getProperty("BuildNumber");
            
            //READ the data location
            File dataLocFile = new File(webInfFolder, "DataLocation.properties");
            if (!dataLocFile.exists()) {
                throw new Exception("The DataLocation.properties file does not exist, "
                        +"something must be wrong with the servlet configuration: "+dataLocFile.toString());
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
                    throw new Exception("The PostHoc data folder does not exist, "
                            +"and the server is unable to create it: "+dataFolder);                    
                }
                System.out.println("PostHoc server created the data folder as: "+dataFolder.toString());
            }
            if (!dataFolder.isDirectory()) {
                throw new Exception("The PostHoc data folder appears to be a file, and not a directory/folder: "
                       +dataFolder.toString());                    
            }
            
            File realConfigFile = new File(dataFolder, "Config.properties");
            if (!realConfigFile.exists()) {
                File protoConfigFile = new File(webInfFolder, "Config.properties");
                StreamHelper.copyFileToFile(protoConfigFile, realConfigFile);
            }
            if (!realConfigFile.exists()) {
                throw new Exception("Unable to create PostHoc config file from WEB-INF to the data folder: "
                        +realConfigFile);                    
            }
            
            props = readProperties(realConfigFile);
            
            hostName = props.getProperty("hostName");
            if (hostName==null) {
                hostName="127.0.0.1";
            }
            String hostPortStr = props.getProperty("hostPort");
            if (hostPortStr==null) {
                hostPortStr="2525";
            }
            hostPort = Integer.parseInt(hostPortStr);
            System.out.println("PostHoc CONFIGURATION: "+hostName+":"+hostPort+"  -- Data folder: "+dataFolder);
        }
        catch (Exception e) {
            throw new Exception("PostHoc CONFIGURATION: Unable to configure PostHoc at initialization time",e);
        }
    }
    
    private static Properties readProperties(File filePath) throws Exception {
        if (!filePath.exists()) {
            throw new Exception("The properties file does not exist: "+filePath);
        }
        Properties props = new Properties();
        FileInputStream fis = new FileInputStream(filePath);
        props.load(fis);
        fis.close();
        return props;
    }
    
}
