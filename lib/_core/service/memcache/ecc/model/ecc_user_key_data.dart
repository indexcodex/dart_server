// =====================
// USER KEY PAIR MODEL
// =====================

/// Represents ECC key material for a device
class EccUserKeyData {
  /// Convert JSON map -> model
  factory EccUserKeyData.fromJson(Map<String, dynamic> json) {
    return EccUserKeyData(
      deviceId: json['deviceId'] as String,
      clientPubkey: json['clientPubkey'] as String,
      serverPubkey: json['serverPubkey'] as String,
      serverPrvkey: json['serverPrvkey'] as String,
      expires: json['expires'] is int
          ? json['expires'] as int
          : int.parse(json['expires'].toString()),
    );
  }
  EccUserKeyData({
    required this.deviceId,
    required this.clientPubkey,
    required this.serverPubkey,
    required this.serverPrvkey,
    required this.expires,
  });

  /// Unique device identifier (cache key)
  final String deviceId;

  /// Client's public key (used for encryption)
  final String clientPubkey;

  /// Server's public key (shared with client)
  final String serverPubkey;

  /// Server's private key (used for decryption)
  final String serverPrvkey;

  /// Expiration timestamp (epoch milliseconds)
  ///
  /// After this time, keys are considered invalid
  final int expires;

  /// Convert model -> JSON map
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'clientPubkey': clientPubkey,
      'serverPubkey': serverPubkey,
      'serverPrvkey': serverPrvkey,
      'expires': expires,
    };
  }
}
