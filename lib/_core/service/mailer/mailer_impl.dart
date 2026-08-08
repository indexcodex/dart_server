import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shelf_server/_core/core.dart';

// ===========================================
// CONFIG YOUR SMTP HERE
// ===========================================
// Use the SmtpServer class to configure an SMTP server:
// final smtpServer = SmtpServer('smtp.domain.com');
// See the named arguments of SmtpServer for further configuration
// options.
final SmtpServer _smtpServer = SmtpServer(
  Core.config.smtpHost,
  username: Core.config.smtpUsername,
  password: Core.config.smtpPassword,
);
// ===========================================

/// the core service that executes email sending
class MailerService {
  /// send the email to the recipient
  ///
  /// recipient: email of recipient
  ///
  /// subject: sucject of the email
  ///
  /// textMail: text version of the email
  ///
  /// htmlEmail: html version of the email
  Future<bool> sendEmail({
    required String recipient,
    required String subject,
    required String textEmail,
    required String htmlEmail,
  }) async {
    // Create our message.
    final message = Message()
      ..from = const Address('support@shelfserver.com', 'SheflServer')
      ..recipients.add(recipient)
      // ..ccRecipients.addAll(['destCc1@example.com', 'destCc2@example.com'])
      // ..bccRecipients.add(Address('bccAddress@example.com'))
      ..subject = subject
      ..text = textEmail
      ..html = htmlEmail;

    try {
      await send(message, _smtpServer);
      return true;
    } on MailerException catch (_) {
      return false;
    }
  }
}
