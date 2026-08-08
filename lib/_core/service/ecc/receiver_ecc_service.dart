import 'dart:typed_data';
import 'package:pointycastle/export.dart';

import 'ecc_manager.dart';

/// The ECC Functions that the receiver will need
///
/// 4. deriveAesKey
/// 5. aesDecrypt
/// 6. verifySignature
class ReceiverEccService {
  final EccManager _eccManager = EccManager();

  /// deconstructs the base64 payload received from the client
  String receiverPayload({
    required String theirSignatureBase64,
    required String theirCipherTextBase64,
    required String theirPublicKeyBase64,
    required String theirNonceBase64,
    required String myPrivatekeyBase64,
  }) {
    // convert the base64 strings to the correct data type
    Uint8List signature = _eccManager.base64ToUint8List(theirSignatureBase64);
    Uint8List cipherText = _eccManager.base64ToUint8List(theirCipherTextBase64);
    Uint8List nonce = _eccManager.base64ToUint8List(theirNonceBase64);
    ECPublicKey clientPubkey = _eccManager.stringToPublicKey(
      theirPublicKeyBase64,
    );
    ECPrivateKey serverPvkey = _eccManager.stringToPrivateKey(
      myPrivatekeyBase64,
    );

    // decrypt data
    Uint8List aesKey = step4(serverPvkey, clientPubkey);
    Uint8List decryptedData = step5(cipherText, aesKey, nonce);

    // verify signature
    bool isSignatureValid = step6(clientPubkey, decryptedData, signature);

    // if signature verification fails, throw an exception
    // it means that verification failed due to invalid integrity
    if (!isSignatureValid) {
      throw 'ecc_signature_verification_failed';
    }

    final String jsonPayload = _eccManager.uint8ListToString(decryptedData);

    return jsonPayload;
  }

  /// Derive shared secret to come up with the AES encryption key
  Uint8List step4(ECPrivateKey privateKey, ECPublicKey publicKey) {
    return _eccManager.deriveAesKey(privateKey, publicKey);
  }

  /// decrypt the received payload
  Uint8List step5(
    Uint8List cipherTextByteData,
    Uint8List aesKey,
    Uint8List nonce,
  ) {
    return _eccManager.aesDecrypt(cipherTextByteData, aesKey, nonce);
  }

  /// Verify the data
  bool step6(PublicKey publicKey, Uint8List data, Uint8List signatureBytes) {
    return _eccManager.verifySignature(publicKey, data, signatureBytes);
  }
}
