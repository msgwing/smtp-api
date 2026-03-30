<?php
/**
 * php-zerosmtp.php
 * PHP 8.3+ PHPMailer 6.9.5 - ZeroSMTP mx.msgwing.com:465 SSL/TLS
 * Production-ready | Let's Encrypt | No deprecated APIs
 */

declare(strict_types=1);

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require_once '/path/to/vendor/autoload.php';

readonly class ZeroSMTPConfig {
    public function __construct(
        public string $username,
        public string $password,
        public string $from,
        public string $to,
        public string $subject,
    ) {}
}

function sendEmailViaZeroSMTP(ZeroSMTPConfig $config): bool {
    $mailer = new PHPMailer(exceptions: true);
    try {
        $mailer->isSMTP();
        $mailer->Host = 'mx.msgwing.com';
        $mailer->Port = 465;
        $mailer->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
        $mailer->SMTPAuth = true;
        $mailer->Username = $config->username;
        $mailer->Password = $config->password;
        $mailer->SMTPOptions = [
            'ssl' => [
                'verify_peer' => true,
                'verify_peer_name' => true,
                'allow_self_signed' => false,
            ],
        ];
        $mailer->setFrom($config->from, 'ZeroSMTP User');
        $mailer->addAddress($config->to);
        $mailer->Subject = $config->subject;
        $mailer->isHTML(true);
        $mailer->Body = '<html><body><h1>Hello from ZeroSMTP!</h1><p>This is an HTML email sent via mx.msgwing.com:465</p></body></html>';
        $mailer->AltBody = 'Hello from ZeroSMTP! This is a plain text version.';
        return $mailer->send();
    } catch (Exception $e) {
        fprintf(STDERR, "Email sending failed: %s\n", $e->getMessage());
        return false;
    }
}

$config = new ZeroSMTPConfig(
    username: getenv('USERNAME') ?: 'your-username',
    password: getenv('PASSWORD') ?: 'your-password',
    from: getenv('FROM') ?: 'sender@example.com',
    to: getenv('TO') ?: 'recipient@example.com',
    subject: getenv('SUBJECT') ?: 'Test Email from ZeroSMTP',
);

exit(sendEmailViaZeroSMTP($config) ? 0 : 1);
