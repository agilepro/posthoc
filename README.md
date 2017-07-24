# Post Hoc Email Testing Server

Post Hoc is an email testing server.  It acts like an email server with unlimited inboxes, but it also presents a web-mail style UI to view and the email it has received.  For some background visit <https://agiletribe.wordpress.com/2017/07/24/posthoc-testing-apps-that-send-email/>.  It is a small lightweight mail server, that captures all the email sent to it, and provides a way to inspect all the email sent, without a lot of fuss.

It was designed to meet this set of requirements:

* **Looks like SMTP**:  the application sends email exactly as it would to an SMTP server with exactly the same kind of settings.  The application does not know it is different.
* **Captures All Email**: the server must never allow an email message to escape out into the real email system.  It must be fool proof: impossible to accidentally configure it to actually forward email.
* **No database**: No need for separate DB server, and not need to configure all the complicated aspects of a real scalable server.  While testing, I will probably have dozens to hundreds of email messages.  These can be stored in a simple file system as files.  There is no need to scale to thousands or millions of messages, because my testing will never go there.
* **No mailbox setup**:  Any email message to any mailbox will be accepted without having to tell the server ahead of time to allow email for that email address.
* **No restriction on addresses**: Allow testing of email to any email address without regard to domain or anything.
* **No user setup**: No need to set up passwords for the different recipients of the email.  Just save every message that is sent.
* **No need to log in**:  It is all just test data, so just display without the need for any password entry.
* **No change user**: just display all the messages to all the users in a single list.  Having to logout/login to change the user is unnecessary overhead.
* **Render HTML**: most email is rich text so display the individual email message  HTML as it would be formatted in an email client.
* **Show HTML source**: show the source HTML for messages so it is easy to see what the cause of formatting problems is.
* **Show RAW message**: show the SMTP message as raw text without interpreting any of the MIME boundaries.  Some email libraries do unpredictable things when constructing the actual SMTP message, and there needs to be a mode to show the lowest level format when it is not working right.
* **Automatic Cleanup**: discard messages after 5 days because either you saw it the first day or so, or you don’t care to see it.  Keeping these test messages for more than 5 days is a waste.
* **Manually Clean all Users**: For a demo, you want to be able to start with an empty inbox to avoid distracting prior messages.  A button to clear the inbox for all users will do.
* **Trivial Install**: as simple as a WAR file that you drop in TomCat and it is instantly ready to go.  The only thing you need to configure is the host name and the port number.
* **Resilient and Stable**: Avoid having lots of interdependent running things.  Either it is up, or it is not.  If not, it should have a clear error message stating what the problem is.  When starting, it should test every thing, and if anything is not shown to be working, it should fail and report a clear error.


Post Hoc does all this.  The only requirement is a TomCat server (or other servlet engine).  Drop the WAR file in there, and usually that is all you need to be up and running immediately.  You might have to set host name and port number, but that is all.

The messages are stored in a simple data folder.  No database, no confliguration, no connection problems, no data user to set up or maintain, no conflicts with other databases you application might be using.  Just a simple file system folder.  It automatically cleans up that data folder by deleting an email message when it gets 5 days old.  It does this without any background processing!  Every time the user lists all the existing email, it looks for and deletes any out-of-date messages.  This simplicity assures that the server runs without fail, and cleans up after itself.

The application can send any number of messages, to any address, and with any format.  There is no need to log in.  Just point your browser at the application, and it shows all the email messages that your application sent, with the most recent at the top.  Click on the message and it is displayed as rich text. Links are active.  Attachments can be accessed and viewed.

If the message looks wrong for any reason, it is easy to get to the underlying source.  Click a button and display the HTML code for the message.  It is easy to click back and forth to find the cause of a formatting problem.  If the attachments are not working, maybe it is a problem in the MIME encoding.  The RAW display shows the actual bytes exactly as they are sent to the server so that MIME encoding errors can be identified.  The bytes of attachments are shown as well in case that is the problem.  Generally, if there is a problem in the construction of the email message, you can identify it in a few seconds and get back to making a fix.

Using this saves so much time when working with applications that send email.  I have absolutely no worry that the email might accidentally get delivered.  No matter what email address is entered.  It is a simple list of all email sent.   When the application send to 10 people, it is easy to count the 10 emails received and see they all were correctly sent.  It looks quite a bit like a regular web-mail client, however notice that along with the date and subject, it is showing both the “from” and the “to” addresses.   you can easily inspect any one of the five recipients by clicking on the line.

That is pretty much all there is.  There is no clutter.  There is no way to forward a message.  No way to compose a message (Post Hoc receives and displays messages only).  No options for saving the message in folders, or preserving them in any way.  (If you need more than five days it is easy to find and save the .msg file some place else — the name of the file is displayed — but I have never needed that capability.)   It does that one thing:  it looks exactly like an SMTP server, and it displays the messages received.




