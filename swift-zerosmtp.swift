// swift-zerosmtp.swift
/**
 * Swift 6.0+ Swift-SMTP 7.0 - ZeroSMTP mx.msgwing.com:465 SSL/TLS
 * Production-ready | Let's Encrypt | Actors, macros, async/await
 * NO allowUnsafeCertificates
 */

import Foundation
import SMTP

@main
struct ZeroSMTPMailer {
    static func main() async {
        let config = EmailConfig(
            username: ProcessInfo.processInfo.environment["USERNAME"] ?? "your-username",
            password: ProcessInfo.processInfo.environment["PASSWORD"] ?? "your-password",
            from: ProcessInfo.processInfo.environment["FROM"] ?? "sender@example.com",
            to: ProcessInfo.processInfo.environment["TO"] ?? "recipient@example.com",
            subject: ProcessInfo.processInfo.environment["SUBJECT"] ?? "Test Email from ZeroSMTP"
        )

        let mailer = MailerActor(config: config)
        let result = await mailer.sendEmail()

        switch result {
        case .success:
            print("Email sent successfully")
            exit(0)
        case .failure(let error):
            fputs("Error: \(error)\n", stderr)
            exit(1)
        }
    }
}

struct EmailConfig {
    let username: String
    let password: String
    let from: String
    let to: String
    let subject: String
}

enum MailResult {
    case success
    case failure(String)
}

actor MailerActor {
    private let config: EmailConfig

    init(config: EmailConfig) {
        self.config = config
    }

    func sendEmail() async -> MailResult {
        do {
            let smtp = SMTP(
                hostname: "mx.msgwing.com",
                email: config.username,
                password: config.password,
                port: 465,
                tlsMode: .requireTLS,
                tlsConfiguration: nil  // uses system trust store
            )

            let from = Mail.User(name: "ZeroSMTP", email: config.from)
            let to = Mail.User(email: config.to)

            let mail = Mail(
                from: from,
                to: [to],
                subject: config.subject,
                text: "Hello from ZeroSMTP! This is plain text.",
                additionalHeaders: [
                    "Content-Type": "text/plain; charset=UTF-8"
                ]
            )

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                smtp.send(mail) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }

            return .success
        } catch {
            return .failure("SMTP error: \(error)")
        }
    }
}
