import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf_server/_core/core.dart';

class JwtFacade {
  /// Verify JWT using ECC public key
  ///
  /// - `checkExpiresIn: true` ensures expired tokens throw automatically
  /// - Any failure here should be caught by caller
  Map<String, dynamic> verifyToken(String token) {
    final jwtPubkey = ECPublicKey(Core.service.memcache.jwt.pubkey);

    final jwt = JWT.verify(
      token,
      jwtPubkey,
      // ignore: avoid_redundant_argument_values
      checkExpiresIn: true, // Enforces expiration validation
    );

    // Ensure payload is strongly typed Map
    return Map<String, dynamic>.from(jwt.payload);
  }

  /// Generate JWT using ECC public key
  ///
  /// - expiresIn: attaches an expiration to the token
  /// which is then verified during verifyToken
  ///
  /// - Any failure here should be caught by caller
  String? generateToken(dynamic payload) {
    return JWT(payload).sign(
      ECPrivateKey(Core.service.memcache.jwt.prvkey),
      algorithm: JWTAlgorithm.ES256,
      expiresIn: const Duration(hours: 24),
    );
  }
}
