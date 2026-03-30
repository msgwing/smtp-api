/**
 * java-zerosmtp.java
 * Java 23+ Jakarta Mail 3.0 - ZeroSMTP mx.msgwing.com:465 SSL/TLS
 * Production-ready | Let's Encrypt | Virtual threads, records, pattern matching
 */

import jakarta.mail.*;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeBodyPart;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.internet.MimeMultipart;
import java.util.Properties;

public final class ZeroSMTPMailer {

    public record EmailConfig(
        String username,
        String password,
        String from,
        String to,
        String subject
    ) {}

    public static void main(String[] args) {
        EmailConfig config = new EmailConfig(
            System.getenv("USERNAME") != null ? System.getenv("USERNAME") : "your-username",
            System.getenv("PASSWORD") != null ? System.getenv("PASSWORD") : "your-password",
            System.getenv("FROM") != null ? System.getenv("FROM") : "sender@example.com",
            System.getenv("TO") != null ? System.getenv("TO") : "recipient@example.com",
            System.getenv("SUBJECT") != null ? System.getenv("SUBJECT") : "Test Email from ZeroSMTP"
        );
        Thread.ofVirtual().start(() -> {
            try {
                if (sendEmailViaZeroSMTP(config)) {
                    System.out.println("Email sent successfully");
                    System.exit(0);
                } else {
                    System.err.println("Email sending failed");
                    System.exit(1);
                }
            } catch (MessagingException e) {
                System.err.println("Messaging error: " + e.getMessage());
                System.exit(1);
            }
        }).join();
    }

    private static boolean sendEmailViaZeroSMTP(EmailConfig config) throws MessagingException {
        Properties props = new Properties();
        props.put("mail.smtp.host", "mx.msgwing.com");
        props.put("mail.smtp.port", "465");
        props.put("mail.smtp.ssl.enable", "true");
        props.put("mail.smtp.ssl.protocols", "TLSv1.2 TLSv1.3");
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.connectiontimeout", "10000");
        props.put("mail.smtp.timeout", "10000");

        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(config.username(), config.password());
            }
        });

        try {
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(config.from(), "ZeroSMTP User"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(config.to()));
            message.setSubject(config.subject());

            MimeMultipart multipart = new MimeMultipart("alternative");
            MimeBodyPart textPart = new MimeBodyPart();
            textPart.setText("Hello from ZeroSMTP! This is plain text.", "utf-8");
            multipart.addBodyPart(textPart);

            MimeBodyPart htmlPart = new MimeBodyPart();
            htmlPart.setContent(
                "<html><body><h1>Hello from ZeroSMTP!</h1><p>This is an HTML email sent via mx.msgwing.com:465</p></body></html>",
                "text/html; charset=utf-8"
            );
            multipart.addBodyPart(htmlPart);
            message.setContent(multipart);
            Transport.send(message);
            return true;
        } catch (MessagingException e) {
            return switch (e) {
                case AuthenticationFailedException afe -> {
                    System.err.println("Authentication failed: " + afe.getMessage());
                    yield false;
                }
                case SendFailedException sfe -> {
                    System.err.println("Send failed: " + sfe.getMessage());
                    yield false;
                }
                default -> {
                    System.err.println("Messaging exception: " + e.getMessage());
                    yield false;
                }
            };
        }
    }
}
