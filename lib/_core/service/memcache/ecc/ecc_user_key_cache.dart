// =====================
// ECC USER KEY CACHE
// =====================

import 'package:shelf_server/_core/service/memcache/ecc/model/ecc_user_key_data.dart';

/// In-memory cache of ECC key pairs per device
/// Keyed by deviceId
class EccUserKeyCache {
  /// Internal storage (deviceId -> key pair)
  final Map<String, EccUserKeyData> _keystore = {};

  /// Retrieve key pair for a device
  ///
  /// - Returns null if not found
  /// - Automatically removes and returns null if expired
  EccUserKeyData? get(String deviceId) {
    final entry = _keystore[deviceId];
    if (entry == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Enforce expiration (lazy cleanup)
    if (entry.expires < now) {
      _keystore.remove(deviceId);
      return null;
    }

    return entry;
  }

  /// Check if a valid (non-expired) key exists for device
  bool exists(String deviceId) {
    return get(deviceId) != null;
  }

  /// Store or overwrite key pair for a device
  ///
  /// If device already exists, old keys are replaced
  void set(EccUserKeyData pair) {
    _keystore[pair.deviceId] = pair;
  }

  /// Remove a device's key pair from cache
  void remove(String deviceId) {
    _keystore.remove(deviceId);
  }

  // =====================
  // CLEANUP (lazy eviction)
  // =====================
  //
  // Prevent unbounded memory growth.
  // Only runs when cache grows beyond threshold to avoid CPU overhead.
  //
  // timestamp is a parameter to avoid timedrift
  // when having different source of time
  //
  // Don’t ask the clock multiple times -> ask once and pass it around
  void cleanup(int now) {
    _keystore.removeWhere((_, v) => v.expires < now);
  }

  /// Current number of cached devices
  int get size => _keystore.length;
}
