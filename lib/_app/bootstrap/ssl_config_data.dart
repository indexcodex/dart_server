import 'dart:io';
import 'package:shelf_server/_core/core.dart';

/// enables SSL in the server
SecurityContext? sslConfigData() {
  // if server environment is not prod, return null
  if (!Core.config.requireSsl) {
    return null;
  }

  /// the path where to find the SSL .pem files
  const String certPath = '/etc/letsencrypt/live/<YOUR_DOMAIN>';

  /// load the certificate
  final File certFile = File('$certPath/fullchain.pem');

  /// load the private key
  final File keyFile = File('$certPath/privkey.pem');

  /// the part where the server enables the SSL
  final sslContext = SecurityContext()
    ..useCertificateChain(certFile.path)
    ..usePrivateKey(keyFile.path);

  return sslContext;
}
