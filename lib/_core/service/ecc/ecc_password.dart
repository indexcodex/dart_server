import 'dart:convert';
import 'package:pointycastle/export.dart';

class EccPassword {
  /// Hashes a password using SHA-256 (not salted, just for masking)
  String maskPassword(String password) {
    final digest = SHA256Digest();
    final hash = digest.process(utf8.encode(password));
    return base64.encode(hash); // Encode in base64 for storage
  }
}
