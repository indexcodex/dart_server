// ignore_for_file: cascade_invocations

import 'dart:math';
import 'package:pointycastle/export.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'model/ecc_keys.dart';

// local import
// means they belong in the same feature

// The ChatGPT refactored version

/// A class to perform Elliptic Curve Cryptography (ECC) operations.
class EccManager {
  /// the Curve used for generating the keypair
  final ECCurve_secp256r1 _generationDomain = ECCurve_secp256r1();

  /// the Curve used for converting base64 to ECC pubkey/prvkey
  final ECDomainParameters _conversionDomain = ECDomainParameters('secp256r1');

  // ---------------
  // MARK: ENCRYPTION
  // ---------------

  /// Decrypts data using AES with a provided key and nonce.
  ///
  /// This method takes the encrypted data, the AES key, and the IV to return
  /// the decrypted plaintext.
  ///
  /// Parameters:
  /// - [cipherTextByteData]: The encrypted data as a [Uint8List].
  /// - [aesKey]: The AES key used for decryption, must be 16, 24, or 32 bytes long.
  /// - [nonce]: The nonce, must be 12 bytes long.
  Uint8List aesDecrypt(
    Uint8List cipherTextByteData,
    Uint8List aesKey,
    Uint8List nonce,
  ) {
    final cipher = GCMBlockCipher(AESEngine());

    cipher.init(
      false,
      AEADParameters(KeyParameter(aesKey), 128, nonce, Uint8List(0)),
    );

    return cipher.process(cipherTextByteData);
  }

  /// Encrypts data using AES with a provided key and nonce.
  ///
  /// This method takes the plaintext data, the AES key, and the IV to return
  /// the encrypted ciphertext.
  ///
  /// Parameters:
  /// - [plainTextByteData]: The plaintext data as a [Uint8List].
  /// - [aesKey]: The AES key used for encryption, must be 16, 24, or 32 bytes long.
  /// - [nonce]: The nonce, must be 12 bytes long.
  Uint8List aesEncrypt(
    Uint8List plainTextByteData,
    Uint8List aesKey,
    Uint8List nonce,
  ) {
    final cipher = GCMBlockCipher(AESEngine());

    cipher.init(
      true,
      AEADParameters(KeyParameter(aesKey), 128, nonce, Uint8List(0)),
    );

    return cipher.process(plainTextByteData);
  }

  /// Generates a random nonce for use in AES encryption/decryption.
  ///
  /// The IV is critical for ensuring the security of the encrypted data.
  /// It is randomly generated and must be 12 bytes long for AES.
  Uint8List generateRandomNonce() {
    final nonce = Uint8List(12);

    final random = Random.secure();

    for (int i = 0; i < nonce.length; i++) {
      nonce[i] = random.nextInt(256);
    }

    return nonce;
  }

  // ---------------
  // MARK: KEY GENERATION
  // ---------------

  /// Generates a pair of ECC keys (public and private).
  ///
  /// Returns an [EccKeys] containing:
  /// - Public Key
  /// - Private Key
  /// - Base64 encoded Public Key
  /// - Base64 encoded Private Key
  EccKeys generateECCKeyPair() {
    AsymmetricKeyPair<PublicKey, PrivateKey> keyPair = _generateECCKeyPair();

    ECPublicKey publicKey = keyPair.publicKey as ECPublicKey;
    ECPrivateKey privateKey = keyPair.privateKey as ECPrivateKey;

    return EccKeys(
      publicKey: publicKey,
      privateKey: privateKey,
      publicKeyBase64: publicKeyToString(publicKey),
      privateKeyBase64: privateKeyToString(privateKey),
    );
  }

  /// Signs the provided data using the specified private key.
  ///
  /// The signing process ensures data integrity and authenticity.
  /// The signature can later be verified with the corresponding public key.
  ///
  /// Workflow:
  /// 1. Initialize the signer with the private key and a secure random instance.
  /// 2. Generate the signature, which consists of two values (r and s).
  /// 3. Return the concatenated r and s values as a byte array.
  ///
  /// Parameters:
  /// - [privateKey]: The private key used to sign the data, must be an instance of [ECPrivateKey].
  /// - [data]: The data to be signed as a [Uint8List].
  Uint8List signData(PrivateKey privateKey, Uint8List data) {
    final signer = Signer('SHA-256/ECDSA');
    final secureRandom = _getSecureRandom();

    // Initialize signer with the private key and a SecureRandom instance
    signer.init(
      true,
      ParametersWithRandom(
        PrivateKeyParameter<ECPrivateKey>(privateKey),
        secureRandom,
      ),
    );

    final ECSignature signature = signer.generateSignature(data) as ECSignature;

    // Convert the r and s values of the signature into Uint8List
    final rBytes = _bigIntToBytes(signature.r);
    final sBytes = _bigIntToBytes(signature.s);

    // Combine both r and s into one Uint8List
    return Uint8List.fromList(rBytes + sBytes);
  }

  /// Verifies the validity of signed data using the specified public key.
  ///
  /// This method checks whether the provided signature corresponds to the original data.
  /// It returns true if the signature is valid; otherwise, it returns false.
  ///
  /// Workflow:
  /// 1. Convert the signature bytes back to an ECSignature object.
  /// 2. Initialize the signer with the public key.
  /// 3. Verify the signature against the original data.
  ///
  /// Parameters:
  /// - [publicKey]: The public key used for verification, must be an instance of [ECPublicKey].
  /// - [data]: The original data that was signed, as a [Uint8List].
  /// - [signatureBytes]: The signature bytes, which should be a concatenation of r and s values.
  bool verifySignature(
    PublicKey publicKey,
    Uint8List data,
    Uint8List signatureBytes,
  ) {
    // Convert signatureBytes back to ECSignature
    final ECSignature signature = _bytesToSignature(signatureBytes);

    final signer = Signer('SHA-256/ECDSA')
      ..init(false, PublicKeyParameter<ECPublicKey>(publicKey));

    return signer.verifySignature(data, signature);
  }

  /// Derives a shared secret using Elliptic Curve Diffie-Hellman (ECDH).
  ///
  /// This method allows two parties to securely compute a shared secret over an insecure
  /// channel. Both parties use their own private keys and the other party’s public key
  /// to compute the shared secret, which can then be used as a key for symmetric encryption.
  ///
  /// Workflow:
  /// 1. Initialize the ECDH agreement with the private key.
  /// 2. Calculate the shared secret using the other party’s public key.
  /// 3. Convert the shared secret from BigInt to Uint8List.
  ///
  /// Parameters:
  /// - [privateKey]: The private key of the calling party, must be an instance of [ECPrivateKey].
  /// - [publicKey]: The public key of the other party, must be an instance of [ECPublicKey].
  Uint8List deriveSharedSecret(ECPrivateKey privateKey, ECPublicKey publicKey) {
    final agreement = ECDHBasicAgreement()..init(privateKey);

    // Calculate the shared secret using the private key and the other party’s public key
    final sharedSecret = agreement.calculateAgreement(publicKey);

    // Convert the shared secret (BigInt) to Uint8List for further use like AES encryption
    return _bigIntToBytes(sharedSecret);
  }

  // ----------------------
  // MARK: UTILITY EXTERNAL
  // ----------------------

  /// quick conversion from string to base64
  ///
  /// flow: string -> bytedata -> base64
  String stringToBase64(String data) {
    Uint8List byteData = stringToUint8List(data);
    String base64 = uint8ListToBase64(byteData);
    return base64;
  }

  /// quick conversion from base64 to string
  ///
  /// flow: base64 -> bytedata -> string
  String base64toString(String base64) {
    Uint8List byteData = base64ToUint8List(base64);
    String data = uint8ListToString(byteData);
    return data;
  }

  /// Converts a Base64 encoded string to a Uint8List.
  ///
  /// This method can be used to decode Base64 strings into byte arrays for further processing.
  ///
  /// Parameters:
  /// - [base64String]: The Base64 encoded string to decode.
  Uint8List base64ToUint8List(String base64String) {
    return base64Decode(base64String);
  }

  /// Converts a Uint8List to a Base64 encoded string.
  ///
  /// This method is useful for encoding byte arrays as Base64 for storage or transmission.
  ///
  /// Parameters:
  /// - [data]: The byte array to encode as Base64.
  String uint8ListToBase64(Uint8List data) {
    return base64Encode(data);
  }

  /// Converts a Uint8List back to a String.
  ///
  /// This method decodes the Uint8List from UTF-8 and returns it as a String.
  ///
  /// Parameters:
  /// - [input]: The byte array to decode.
  String uint8ListToString(Uint8List input) {
    return utf8.decode(input);
  }

  /// Converts a [String] to a [Uint8List].
  ///
  /// This method encodes the string to UTF-8 and returns it as a Uint8List.
  ///
  /// Parameters:
  /// - [input]: The string to encode as a byte array.
  Uint8List stringToUint8List(String input) {
    return utf8.encode(input); // Encode the string to UTF-8
  }

  /// Converts an ECPublicKey to a Base64 encoded String.
  ///
  /// This method is useful for serializing public keys for storage or transmission.
  ///
  /// Parameters:
  /// - [publicKey]: The public key to serialize, must be an instance of [ECPublicKey].
  String publicKeyToString(ECPublicKey publicKey) {
    return base64Encode(publicKey.Q!.getEncoded(false));
  }

  /// Converts a Base64 encoded String to an ECPublicKey.
  ///
  /// This method is useful for deserializing public keys from Base64 strings.
  ///
  /// Parameters:
  /// - [base64String]: The Base64 encoded string representing the public key.
  /// - [domainParams]: The domain parameters used for the key, must be an instance of [ECDomainParameters].
  ECPublicKey stringToPublicKey(String base64String) {
    final publicKeyBytes = base64Decode(base64String);
    final point = _conversionDomain.curve.decodePoint(publicKeyBytes);
    return ECPublicKey(point, _conversionDomain);
  }

  /// Converts an ECPrivateKey to a Base64 encoded String.
  ///
  /// This method is useful for serializing private keys for storage or transmission.
  ///
  /// Parameters:
  /// - [privateKey]: The private key to serialize, must be an instance of [ECPrivateKey].
  String privateKeyToString(ECPrivateKey privateKey) {
    return base64Encode(_bigIntToBytes(privateKey.d!));
  }

  /// Converts a Base64 encoded String to an ECPrivateKey.
  ///
  /// This method is useful for deserializing private keys from Base64 strings.
  ///
  /// Parameters:
  /// - [base64String]: The Base64 encoded string representing the private key.
  /// - [domainParams]: The domain parameters used for the key, must be an instance of [ECDomainParameters].
  ECPrivateKey stringToPrivateKey(String base64String) {
    // Decode the Base64 string to bytes
    final privateKeyBytes = base64Decode(base64String);

    // Convert the byte array to a BigInt
    BigInt d = _bytesToBigInt(privateKeyBytes);

    // Create and return the ECPrivateKey object
    return ECPrivateKey(d, _conversionDomain);
  }

  // ----------------------
  // MARK: UTILITY INTERNAL
  // ----------------------

  /// Converts a Uint8List to a BigInt.
  ///
  /// This method is useful for converting byte arrays to numerical representations for cryptographic operations.
  ///
  /// Parameters:
  /// - [bytes]: The byte array to convert to BigInt.
  BigInt _bytesToBigInt(Uint8List bytes) {
    return BigInt.parse(
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
  }

  /// Converts the signature bytes (r and s) back to an ECSignature object.
  ///
  /// This method is used during signature verification to reconstruct the signature from its byte representation.
  ///
  /// Parameters:
  /// - [signatureBytes]: The concatenated byte array of r and s values.
  ECSignature _bytesToSignature(Uint8List signatureBytes) {
    final len = signatureBytes.length ~/ 2;
    final BigInt r = _bytesToBigInt(signatureBytes.sublist(0, len));
    final BigInt s = _bytesToBigInt(signatureBytes.sublist(len));

    return ECSignature(r, s);
  }

  /// Returns a Fortuna-based SecureRandom instance.
  ///
  /// This method initializes a secure random number generator for cryptographic use.
  SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final seed = Uint8List(32);
    Random.secure().nextBytes(seed);
    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }

  // Utility methods for BigInt <-> Uint8List conversions.

  /// Converts a BigInt to a Uint8List.
  ///
  /// This method is useful for converting numerical representations into byte arrays for cryptographic operations.
  ///
  /// Parameters:
  /// - [number]: The BigInt to convert to a byte array.
  Uint8List _bigIntToBytes(BigInt number) {
    final bytes = number
        .toRadixString(16)
        .padLeft((number.bitLength + 7) >> 3 << 1, '0');
    return Uint8List.fromList(
      List<int>.generate(
        bytes.length ~/ 2,
        (i) => int.parse(bytes.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  /// Generates ECC Private and Public Keys.
  ///
  /// This internal method uses the specified curve and a secure random number generator
  /// to create a new ECC key pair.
  AsymmetricKeyPair<PublicKey, PrivateKey> _generateECCKeyPair() {
    final keyParams = ECKeyGeneratorParameters(_generationDomain);
    final secureRandom = _getSecureRandom();

    final keyGenerator = ECKeyGenerator()
      ..init(ParametersWithRandom(keyParams, secureRandom));
    final keyPair = keyGenerator.generateKeyPair();

    return AsymmetricKeyPair<PublicKey, PrivateKey>(
      keyPair.publicKey,
      keyPair.privateKey,
    );
  }

  // MARK: 2026 updates
  Uint8List deriveAesKey(ECPrivateKey privateKey, ECPublicKey publicKey) {
    final sharedSecret = deriveSharedSecret(privateKey, publicKey);

    final digest = SHA256Digest();

    return digest.process(sharedSecret);
  }
}

/// Extension to enable processing of random seed for generating secure random bytes.
extension RandomBytes on Random {
  /// Fills a [Uint8List] with random bytes.
  ///
  /// This method iterates through the provided list and populates it with
  /// random values between 0 and 255.
  ///
  /// Parameters:
  /// - [list]: The Uint8List to fill with random bytes.
  void nextBytes(Uint8List list) {
    for (int i = 0; i < list.length; i++) {
      list[i] = nextInt(256);
    }
  }
}
