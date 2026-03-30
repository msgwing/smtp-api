#!/usr/bin/env ruby
# ruby-zerosmtp.rb
# Ruby 3.4+ Net::SMTP - ZeroSMTP mx.msgwing.com:465 SSL/TLS
# Production-ready | Let's Encrypt | Pattern matching, frozen strings

frozen_string_literal: true

require 'net/smtp'
require 'openssl'
require 'mail'

class ZeroSMTPMailer
  CONFIG = {
    username: ENV.fetch('USERNAME', 'your-username').freeze,
    password: ENV.fetch('PASSWORD', 'your-password').freeze,
    from:     ENV.fetch('FROM', 'sender@example.com').freeze,
    to:       ENV.fetch('TO', 'recipient@example.com').freeze,
    subject:  ENV.fetch('SUBJECT', 'Test Email from ZeroSMTP').freeze,
  }.freeze

  def self.send_email
    new.send_email
  end

  def send_email
    context = OpenSSL::SSL::SSLContext.new
    context.verify_mode = OpenSSL::SSL::VERIFY_PEER

    Net::SMTP.start(
      'mx.msgwing.com',
      465,
      ssl_context: context,
    ) do |smtp|
      smtp.auth_login(CONFIG[:username], CONFIG[:password])

      boundary = "boundary_zerosmtp_#{Time.now.to_i}"
      body = build_multipart_body(boundary)

      smtp.send_message(body, CONFIG[:from], CONFIG[:to])
    end

    true
  rescue => e
    case e
    in StandardError => err if err.message.include?('authentication')
      warn "Authentication failed: #{err.message}"
      false
    in StandardError => err if err.message.include?('certificate')
      warn "Certificate verification failed: #{err.message}"
      false
    in StandardError => err
      warn "SMTP error: #{err.message}"
      false
    end
  end

  private

  def build_multipart_body(boundary)
    <<~MAIL
      From: #{CONFIG[:from]}
      To: #{CONFIG[:to]}
      Subject: #{CONFIG[:subject]}
      MIME-Version: 1.0
      Content-Type: multipart/alternative; boundary="#{boundary}"

      --#{boundary}
      Content-Type: text/plain; charset="UTF-8"

      Hello from ZeroSMTP! This is plain text.

      --#{boundary}
      Content-Type: text/html; charset="UTF-8"

      <html><body><h1>Hello from ZeroSMTP!</h1><p>This is an HTML email sent via mx.msgwing.com:465</p></body></html>

      --#{boundary}--
    MAIL
  end
end

exit ZeroSMTPMailer.send_email ? 0 : 1
