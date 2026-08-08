import 'dart:async';
import 'dart:convert';

import 'package:redis/redis.dart';
import 'package:shelf_server/_core/core.dart';

/// A lightweight Redis wrapper for basic caching, counters, and key-value storage.
///
/// Features:
/// - Safe fallback if Redis is unavailable
/// - TTL support
/// - JSON serialization helpers
/// - Basic fault tolerance (auto-disable on failure)
class RedisFacade {
  late Command _redis;

  final _log = Core.util.log;

  // Indicates whether Redis is currently usable.
  // If false, all operations become no-ops or safe fallbacks.
  bool _enabled = false;

  // the execution timeout
  final Duration _timeout = const Duration(seconds: 4);

  // return -3 if Redis is unavailable (wrapper fallback)
  static const int _redisUnavailable = -3;

  // mechanism to reconnect redis when it disconnects
  bool _reconnecting = false;
  DateTime? _lastReconnectAttempt;

  Future<void> _reconnect() async {
    if (_enabled || _reconnecting) return;

    final now = DateTime.now();

    if (_lastReconnectAttempt != null &&
        now.difference(_lastReconnectAttempt!) < const Duration(seconds: 5)) {
      return;
    }

    _lastReconnectAttempt = now;
    _reconnecting = true;

    try {
      final conn = RedisConnection();
      _redis = await conn.connect(
        Core.config.redisIpAddress,
        Core.config.redisPort,
      );
      _enabled = true;
      _log.devPrint('Redis reconnected');
    } catch (_) {
      // still down
    } finally {
      _reconnecting = false;
    }
  }

  Future<bool> get _ensureConnection async {
    if (_enabled) return true;
    await _reconnect();
    return _enabled;
  }

  /// Initializes connection to Redis server.
  ///
  /// Defaults:
  /// - address: 127.0.0.1
  /// - port: 6379
  ///
  /// If connection fails, Redis will be disabled silently.
  Future<void> init({String? redisAddress, int? redisPort}) async {
    String? address = redisAddress ?? '127.0.0.1';
    int? port = redisPort ?? 6379;

    try {
      final conn = RedisConnection();
      _redis = await conn.connect(address, port);
      _enabled = true;

      _log.devPrintList([
        'Redis initialized',
        '- address: $address',
        '- port: $port',
      ]);
    } catch (_) {
      _enabled = false;
      _log.devPrint('Redis disabled');
    }
  }

  /// Sets a value in Redis.
  ///
  /// If [expiresAtMs] is provided, the key will expire at an absolute Unix timestamp in milliseconds.
  ///
  /// Equivalent Redis commands:
  /// - SET key value
  /// - SET key value PXAT expires
  Future<void> set(String key, String value, {int? expiresAtMs}) async {
    if (!await _ensureConnection) return; // if reconnect fails

    try {
      if (expiresAtMs == null) {
        await _redis.send_object(['SET', key, value]).timeout(_timeout);
      } else {
        await _redis
            .send_object(['SET', key, value, 'PXAT', expiresAtMs])
            .timeout(_timeout);
      }
    } catch (e) {
      _log.devPrint('Redis SET error: $e');
      if (e is! TimeoutException) {
        _enabled = false; // disable Redis on failure
      }
    }
  }

  /// Sets a value in Redis if it doesn't exist yet
  ///
  /// If [expiresAtMs] is provided, the key will expire at an absolute Unix timestamp in milliseconds.
  ///
  /// Equivalent Redis commands:
  /// - SETNX key value
  /// - SETNX key value PX expires
  Future<bool> setnx(String key, String value, {int? expiresAtMs}) async {
    if (!await _ensureConnection) return false; // if reconnect fails

    try {
      late final dynamic result;

      if (expiresAtMs == null) {
        // SETNX key value
        result = await _redis
            .send_object(['SETNX', key, value])
            .timeout(_timeout);
      } else {
        // Modern Redis way: SET key value NX PX expires
        result = await _redis
            .send_object(['SET', key, value, 'NX', 'PXAT', expiresAtMs])
            .timeout(_timeout);
      }

      // SETNX returns:
      // 1 -> success (lock acquired)
      // 0 -> failed (already exists)

      // SET NX returns:
      // "OK" -> success
      // null -> failed
      if (expiresAtMs == null) {
        return result == 1;
      } else {
        return result == 'OK';
      }
    } catch (e) {
      _log.devPrint('Redis SETNX error: $e');
      if (e is! TimeoutException) {
        _enabled = false; // disable Redis on failure
      }
      return false;
    }
  }

  /// Retrieves a value from Redis.
  ///
  /// Returns:
  /// - String value if key exists
  /// - null if key does not exist or Redis is unavailable
  ///
  /// Includes a timeout to prevent hanging requests.
  /// Automatically disables Redis on failure.
  Future<String?> get(String key) async {
    if (!await _ensureConnection) return null; // if reconnect fails

    try {
      return await _redis.send_object(['GET', key]).timeout(_timeout);
    } catch (e) {
      _log.devPrint('Redis GET error: $e');
      if (e is! TimeoutException) {
        _enabled = false; // disable Redis on failure
      }
      return null;
    }
  }

  /// returns an int from a redis get
  Future<int?> getInt(String key) async {
    if (!await _ensureConnection) return null;

    try {
      final rawData = await _redis.send_object(['GET', key]).timeout(_timeout);

      if (rawData == null) return null;

      if (rawData is int) {
        return rawData; // just in case client returns int
      }

      if (rawData is String) {
        return int.tryParse(rawData);
      }

      return null;
    } catch (e) {
      _log.devPrint('Redis GET error: $e');
      if (e is! TimeoutException) {
        _enabled = false;
      }
      return null;
    }
  }

  /// Deletes a key from Redis.
  ///
  /// Equivalent to: DEL key
  Future<void> del(String key) async {
    if (!await _ensureConnection) return; // if reconnect fails

    try {
      await _redis.send_object(['DEL', key]).timeout(_timeout);
    } catch (e) {
      _log.devPrint('Redis DEL error: $e');
      if (e is! TimeoutException) {
        _enabled = false; // disable Redis on failure
      }
    }
  }

  Future<void> expire(String key, int milliseconds) async {
    if (!await _ensureConnection) return; // if reconnect fails

    try {
      await _redis
          .send_object(['PEXPIRE', key, milliseconds])
          .timeout(_timeout);
    } catch (e) {
      _log.devPrint('Redis EXPIRE error: $e');
      if (e is! TimeoutException) {
        _enabled = false; // disable Redis on failure
      }
    }
  }

  /// Checks whether a key exists.
  ///
  /// Returns:
  /// - true if key exists
  /// - false otherwise or if Redis is unavailable
  Future<bool> exists(String key) async {
    if (!await _ensureConnection) return false; // if reconnect fails

    try {
      final result = await _redis
          .send_object(['EXISTS', key])
          .timeout(_timeout);
      return result == 1;
    } catch (e) {
      _log.devPrint('Redis EXISTS error: $e');
      if (e is! TimeoutException) {
        _enabled = false; // disable Redis on failure
      }
      return false;
    }
  }

  /// Returns the remaining TTL (time-to-live) in seconds.
  ///
  /// Returns:
  /// - TTL in seconds
  /// - -1 if key exists but has no expiration
  /// - -2 if key does not exist (Redis behavior)
  Future<int> ttl(String key) async {
    if (!await _ensureConnection) {
      return _redisUnavailable; // if reconnect fails
    }

    try {
      return await _redis.send_object(['TTL', key]).timeout(_timeout);
    } catch (e) {
      _log.devPrint('Redis TTL error: $e');
      if (e is! TimeoutException) {
        _enabled = false; // disable Redis on failure
      }
      return _redisUnavailable;
    }
  }

  /// Increments a numeric value stored at [key].
  ///
  /// Returns:
  /// - New incremented value
  /// - -3 if Redis is unavailable
  ///
  /// Note:
  /// Value must be an integer or Redis will throw an error.
  Future<int> incr(String key) async {
    if (!await _ensureConnection) {
      return _redisUnavailable; // if reconnect fails
    }

    try {
      return await _redis.send_object(['INCR', key]).timeout(_timeout);
    } catch (e) {
      _log.devPrint('Redis INCR error: $e');
      if (e is! TimeoutException) {
        _enabled = false; // disable Redis on failure
      }
      return _redisUnavailable;
    }
  }

  /// Stores a JSON-encoded object.
  ///
  /// Automatically serializes [value] into a JSON string.
  ///
  /// If [expiresAtMs] is provided, the key will expire at an absolute Unix timestamp in milliseconds.
  Future<void> setJson(String key, Object value, {int? expiresAtMs}) async {
    final json = jsonEncode(value);
    await set(key, json, expiresAtMs: expiresAtMs);
  }

  /// Retrieves and decodes a JSON value.
  ///
  /// Returns:
  /// - Decoded object if valid JSON
  /// - null if key does not exist, Redis is unavailable, or decoding fails
  ///
  /// Automatically disables Redis on decode failure (data corruption case).
  Future<dynamic> getJson(String key) async {
    final data = await get(key);
    if (data == null) return null;

    try {
      return jsonDecode(data);
    } catch (e) {
      _log.devPrint('Redis GETJSON error: $e');
      return null;
    }
  }

  /// Cache helper: retrieves value if cached, otherwise fetches and stores it.
  ///
  /// Pattern:
  /// 1. Try Redis
  /// 2. If miss -> call [fetch]
  /// 3. Store result in Redis
  /// 4. Return result
  ///
  /// This is the core pattern for API response caching.
  ///
  /// If [expiresAtMs] is provided, the key will expire at an absolute Unix timestamp in milliseconds.
  Future<String> getOrSet(
    String key,
    Future<String> Function() fetch, {
    int? expiresAtMs,
  }) async {
    final cached = await get(key);
    if (cached != null) return cached;

    final fresh = await fetch();

    try {
      await set(key, fresh, expiresAtMs: expiresAtMs);
    } catch (_) {
      // ignore cache failure
    }

    return fresh;
  }

  /// Utility helper for consistent key naming.
  ///
  /// Example:
  /// key('user', '1') -> "user:1"
  ///
  /// Helps enforce namespace conventions across the app.
  String key(String namespace, String id) => '$namespace:$id';

  /// generates the namespace for ecc user keys
  String nsEccUserKeys(String identifier) {
    return 'ecc:userKeys:$identifier';
  }

  /// generates the namespace for rate limit keys
  String nsRateLimit(String identifier) {
    return 'ratelimit:$identifier';
  }

  /// generates the namespace for replayguard keys
  String nsReplayGuard(String identifier) {
    return 'replayguard:$identifier';
  }

  /// generates the namespace for jwt server public key
  String get nsJwtServerPubkey {
    return 'jwt:serverKey:public';
  }

  /// generates the namespace for jwt server private key
  String get nsJwtServerPrvkey {
    return 'jwt:serverKey:private';
  }
}
