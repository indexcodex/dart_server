import 'dart:convert';

import 'package:pointycastle/pointycastle.dart';

import 'ecc_manager.dart';
import 'ecc_password.dart';
import 'receiver_ecc_service.dart';
import 'sender_ecc_service.dart';
import 'model/ecc_keys.dart';

class EccFacade {
  final EccManager _eccManager = EccManager();
  final SenderEccService _senderEcc = SenderEccService();
  final ReceiverEccService _receiverEcc = ReceiverEccService();
  final EccPassword _password = EccPassword();

  String maskPassword(String password) {
    return _password.maskPassword(password);
  }

  EccKeys generateKeyPair() {
    return _eccManager.generateECCKeyPair();
  }

  ECPrivateKey stringToPrivateKey(String base64String) {
    return _eccManager.stringToPrivateKey(base64String);
  }

  ECPublicKey stringToPublicKey(String base64String) {
    return _eccManager.stringToPublicKey(base64String);
  }

  String encrypt({
    required ECPublicKey theirPubkey,
    required ECPublicKey myPubkey,
    required ECPrivateKey myPvkey,
    required String plainTextData,
  }) {
    return _senderEcc.senderPayload(
      theirPublicKey: theirPubkey,
      myPublicKey: myPubkey,
      myPrivateKey: myPvkey,
      plainTextData: plainTextData,
    );
  }

  String decrypt({
    required String encryptedPayload,
    required String myPrivateKeyBase64,
  }) {
    String decodedPayload = _eccManager.base64toString(encryptedPayload);

    Map<String, dynamic> mapData = jsonDecode(decodedPayload);

    String clientPubkey64 = mapData['clientPubkey64'];
    String signature = mapData['signature'];
    String cipherText = mapData['cipherText'];
    String nonce = mapData['nonce'];

    String decryptedData = _receiverEcc.receiverPayload(
      theirSignatureBase64: signature,
      theirCipherTextBase64: cipherText,
      theirPublicKeyBase64: clientPubkey64,
      theirNonceBase64: nonce,
      myPrivatekeyBase64: myPrivateKeyBase64,
    );

    return decryptedData;
  }
}
