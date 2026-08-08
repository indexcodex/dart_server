import 'dart:convert';

import 'package:shelf_server/_core/core.dart';

String _plaintextEncryptor({
  required String clientPrvkey,
  required String clientPubkey,
  required String serverPubkey,
  required String plainText,
}) {
  String encryptedMessage = Core.service.ecc.encrypt(
    theirPubkey: Core.service.ecc.stringToPublicKey(serverPubkey),
    myPubkey: Core.service.ecc.stringToPublicKey(clientPubkey),
    myPvkey: Core.service.ecc.stringToPrivateKey(clientPrvkey),
    plainTextData: plainText,
  );

  return encryptedMessage;
}

void main() {
  String clientPubkey =
      'BDod1Jf5iF1wYsEd0xtrbrRqfCc+jotj4d6f8Bpx7a9gy7WsnfmuYg+EI0XCdxoAPZNCtZeyktAwUghGh+wKdJE=';
  String clientPrvkey = 'MGf2kQ00u7QcKyHE+5neicxDHRLqPo0t1muvatNoz2s=';
  String serverPubkey = '';

  String encryptedMessage = _plaintextEncryptor(
    clientPrvkey: clientPrvkey,
    clientPubkey: clientPubkey,
    serverPubkey: serverPubkey,
    plainText: jsonEncode({'otp': 123123, 'userName': 'JohnDoe'}),
  );

  Core.util.log.devPrint('encrypted payload');
  Core.util.log.devPrint(encryptedMessage);
}
