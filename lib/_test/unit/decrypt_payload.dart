import 'package:shelf_server/_core/core.dart';

String _ciphertextDecryptor({
  required String encryptedMessage,
  required String clientPrvkey,
}) {
  String decryptedMessage = Core.service.ecc.decrypt(
    encryptedPayload: encryptedMessage,
    myPrivateKeyBase64: clientPrvkey,
  );

  return decryptedMessage;
}

void main() {
  String clientPrvkey = 'MGf2kQ00u7QcKyHE+5neicxDHRLqPo0t1muvatNoz2s=';

  String decryptedMessage = _ciphertextDecryptor(
    encryptedMessage: '',
    clientPrvkey: clientPrvkey,
  );

  Core.util.log.devPrint('decryptedMessage');
  Core.util.log.devPrint(decryptedMessage);
}
