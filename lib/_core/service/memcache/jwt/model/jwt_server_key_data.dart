// =====================
// JWT KEY PAIR
// =====================

/// Holds JWT public/private key pair
/// Immutable after initialization
class JwtServerKeyData {
  JwtServerKeyData({required this.pubkey, required this.prvkey});

  /// Public key used to verify JWT signatures
  final String pubkey;

  /// Private key used to sign JWTs
  final String prvkey;
}
