package com.purplehillsbooks.posthoc;

import java.net.InetAddress;

import org.subethamail.smtp.helper.SimpleMessageListenerAdapter;
import org.subethamail.smtp.server.SMTPServer;

/**
 * Starts and stops the SMTP server.
 */
public class SMTPServerHandler {

    private static SMTPServer smtpServer = new SMTPServer(new SimpleMessageListenerAdapter(new MailListener()), new SMTPAuthHandlerFactory());

    private SMTPServerHandler() {
    }

    /**
     * Starts the server on the port and address specified in parameters.
     *
     * @param port the SMTP port to be opened.
     * @param bindAddress the address to bind to. null means bind to all.
     * @throws BindPortException when the port can't be opened.
     * @throws OutOfRangePortException when port is out of range.
     * @throws IllegalArgumentException when port is out of range.
     */
    public static void startServer(int port, InetAddress bindAddress) throws Exception {
        System.out.println("Starting server on port "+port);
        try {
            smtpServer.setBindAddress(bindAddress);
            smtpServer.setPort(port);
            smtpServer.start();
        } catch (Exception e) {
            throw new Exception("Server is unable to start", e);
        }
    }

    /**
     * Stops the server.
     * <p>
     * If the server is not started, does nothing special.
     * </p>
     */
    public static void stopServer() {
        if (smtpServer.isRunning()) {
            System.out.println("Stopping server");
            smtpServer.stop();
        }
    }

    /**
     * Returns the {@code SMTPServer} object.
     *
     * @return the {@code SMTPServer} object.
     */
    public static SMTPServer getSmtpServer() {
        return smtpServer;
    }
}
