<?php
/**
 * ZeroSMTP - SwiftMailer Example
 * 
 * Production example demonstrating how to use ZeroSMTP with SwiftMailer
 * for sending emails via SMTP relay.
 * 
 * Requirements:
 * - SwiftMailer library installed via Composer
 * - Valid ZeroSMTP credentials (free account at https://msgwing.com)
 * 
 * Installation:
 * composer require swiftmailer/swiftmailer
 */

require_once __DIR__ . '/vendor/autoload.php';

// ZeroSMTP Configuration
$smtpConfig = [
    'host'     => 'mx.msgwing.com',
    'port'     => 465,
    'username' => 'xyz@msgwing.com',      // Your ZeroSMTP email address
    'password' => 'xyz',                  // Your ZeroSMTP password
    'from'     => 'xyz@msgwing.com',      // Sender email address
    'fromName' => 'xyz',                  // Sender name
];

try {
    // Create SMTP Transport with SSL/TLS encryption
    $transport = (new Swift_SmtpTransport($smtpConfig['host'], $smtpConfig['port'], 'ssl'))
        ->setUsername($smtpConfig['username'])
        ->setPassword($smtpConfig['password']);

    // Create Mailer instance
    $mailer = new Swift_Mailer($transport);

    // Create Message
    $message = (new Swift_Message('Hello from ZeroSMTP!'))
        ->setFrom([$smtpConfig['from'] => $smtpConfig['fromName']])
        ->setTo([
            'recipient@example.com' => 'Recipient Name',
        ])
        ->setReplyTo(['test1@example.com'])
        ->setBody(
            '<html><body>' .
            '<h1>Welcome!</h1>' .
            '<p>This email was sent using ZeroSMTP with SwiftMailer.</p>' .
            '<p>No cost. No limits. Free SMTP relay for developers.</p>' .
            '</body></html>',
            'text/html'
        );

    // Add alternative text version
    $message->addPart(
        'This email was sent using ZeroSMTP with SwiftMailer. No cost. No limits.',
        'text/plain'
    );

    // Send the message
    $result = $mailer->send($message);

    if ($result) {
        echo "✓ Email sent successfully via ZeroSMTP!\n";
        echo "Recipients: " . $result . "\n";
    } else {
        echo "✗ Failed to send email.\n";
    }

} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
    exit(1);
}