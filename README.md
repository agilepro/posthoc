# posthoc
Post Hoc is an email testing server.  It acts like an email server with unlimited inboxes, but it also presents a web-mail style UI to view and the email it has received.


So this is what I need to test multi-user email-enabled applications:

* Looks like SMTP:  the application sends email exactly as it would to an SMTP server with exactly the same kind of settings.  The application does not know it is different.
* Captures All Email: the server must never allow an email message to escape out into the real email system.  It must be fool proof: impossible to accidentally configure it to actually forward email.
* No database: No need for separate DB server, and not need to configure all the complicated aspects of a real scalable server.  While testing, I will probably have dozens to hundreds of email messages.  These can be stored in a simple file system as files.  There is no need to scale to thousands or millions of messages, because my testing will never go there.
* No mailbox setup:  Any email message to any mailbox will be accepted without having to tell the server ahead of time to allow email for that email address.
* No restriction on addresses: Allow testing of email to any email address without regard to domain or anything.
* No user setup: No need to set up passwords for the different recipients of the email.  Just save every message that is sent.
* No need to log in:  It is all just test data, so just display without the need for any password entry.
* No change user: just display all the messages to all the users in a single list.  Having to logout/login to change the user is unnecessary overhead.
* Render HTML: most email is rich text so display the individual email message  HTML as it would be formatted in an email client.
* Show HTML source: show the source HTML for messages so it is easy to see what the cause of formatting problems is.
* Show RAW message: show the SMTP message as raw text without interpreting any of the MIME boundaries.  Some email libraries do unpredictable things when constructing the actual SMTP message, and there needs to be a mode to show the lowest level format when it is not working right.
* Automatic Cleanup: discard messages after 5 days because either you saw it the first day or so, or you don’t care to see it.  Keeping these test messages for more than 5 days is a waste.
* Manually Clean all Users: For a demo, you want to be able to start with an empty inbox to avoid distracting prior messages.  A button to clear the inbox for all users will do.
* Trivial Install: as simple as a WAR file that you drop in TomCat and it is instantly ready to go.  The only thing you need to configure is the host name and the port number.
* Resilient and Stable: Avoid having lots of interdependent running things.  Either it is up, or it is not.  If not, it should have a clear error message stating what the problem is.  When starting, it should test every thing, and if anything is not shown to be working, it should fail and report a clear error.

