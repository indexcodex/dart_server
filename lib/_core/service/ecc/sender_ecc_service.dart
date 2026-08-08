import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

import 'ecc_manager.dart';

/// The ECC Functions that the sender will need
///
/// 1. deriveAesKey
/// 2. signData
/// 3. aesEncrypt
class SenderEccService {
  final EccManager _eccManager = EccManager();

  /// constructs the base64 payload to send to the server
  String senderPayload({
    required ECPublicKey theirPublicKey,
    required ECPublicKey myPublicKey,
    required ECPrivateKey myPrivateKey,
    required String plainTextData,
  }) {
    // the aes key used for encryption/decryption
    final Uint8List aesKey = step1(myPrivateKey, theirPublicKey);

    // the nonce randomizes the ciphertext to prevent pattern based attacks
    final Uint8List nonce = _eccManager.generateRandomNonce();

    // the signature to prove the validity of the data
    final Uint8List signature = step2(myPrivateKey, plainTextData);

    // the encrypted data
    final Uint8List cipherText = step3(plainTextData, aesKey, nonce);

    // construct the payload and json encode it
    final String jsonPayload = jsonEncode({
      'clientPubkey64': _eccManager.publicKeyToString(myPublicKey),
      'signature': _eccManager.uint8ListToBase64(signature),
      'cipherText': _eccManager.uint8ListToBase64(cipherText),
      'nonce': _eccManager.uint8ListToBase64(nonce),
    });

    // finalize the payload by encoding it in base64
    final String base64Payload = _eccManager.stringToBase64(jsonPayload);

    // send the payload to the server
    return base64Payload;
  }

  /// Derive shared secret to come up with the AES decryption key
  Uint8List step1(ECPrivateKey privateKey, ECPublicKey publicKey) {
    return _eccManager.deriveAesKey(privateKey, publicKey);
  }

  /// Sign the data
  Uint8List step2(PrivateKey privateKey, String data) {
    return _eccManager.signData(
      privateKey,
      _eccManager.stringToUint8List(data),
    );
  }

  /// Aes Encrypt the data
  Uint8List step3(String plainTextData, Uint8List aesKey, Uint8List nonce) {
    return _eccManager.aesEncrypt(
      _eccManager.stringToUint8List(plainTextData),
      aesKey,
      nonce,
    );
  }
}
