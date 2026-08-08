import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_core/core.dart';
import 'package:shelf_server/_core/enum/shelf_server_type.dart';

// RGMWRRD: replay guard middle ware replay request detected
const _replayRequestDetected = 'RGMWRRD';
// RGMWGR: replay guard middle ware generic response
const _genericResponse = 'RGMWGR';

Middleware replayGuardMiddleware() {
  switch (Core.config.serverType) {
    case ShelfServerType.monolith:
      return _memoryHandler();
    case ShelfServerType.microservice:
      return _redisHandler();
  }
}

Middleware _memoryHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Global kill-switch for replay guard
      if (!Core.config.enableSecurity) {
        return innerHandler(request);
      }
      // Allow specific endpoints to bypass replay guard
      if (Core.service.config.replayGuardEndpointPassthrough(
        request.url.path,
      )) {
        return innerHandler(request);
      }

      Map<String, dynamic> replayGuardData;

      // if encryption is enabled, use context passed by crypto middleware
      try {
        replayGuardData = request.context;
      } catch (_) {
        return _invalid();
      }

      final nonce = replayGuardData['nonce'];

      // =====================
      // PARSE TIMESTAMP
      // =====================
      //
      // Accept both:
      // - int (preferred)
      // - string (fallback)
      //
      // This prevents subtle client inconsistencies from breaking validation.
      final rawTimestamp = replayGuardData['timestamp'];
      final int? clientTimestamp = rawTimestamp is int
          ? rawTimestamp
          : int.tryParse(rawTimestamp?.toString() ?? '');

      // Server time (source of truth)
      final requestTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Allowed request lifetime (5 minutes)
      // value is milliseconds
      final replayGuardValidityWindow = Core.config.replayGuardValidityWindow;

      final cache = Core.service.memcache.replayGuard;
      final int memcacheRecordLimit = Core.config.memcacheRecordLimit;

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
      if (cache.size > memcacheRecordLimit) {
        cache.cleanup(requestTimestamp);
      }

      // =====================
      // VALIDATE NONCE
      // =====================
      //
      // Nonce must:
      // - exist
      // - be a string
      // - not be empty
      //
      // This ensures each request can be uniquely identified.
      if (nonce is! String || nonce.isEmpty) {
        return _invalid();
      }

      // =====================
      // VALIDATE TIMESTAMP
      // =====================
      //
      // Protects against:
      // - replaying old requests (expired)
      // - preplay attacks (future timestamps)
      //
      // Conditions:
      // - must be valid integer
      // - must not be in the future
      // - must be within allowed window
      if (clientTimestamp == null ||
          clientTimestamp > requestTimestamp || // prevent future replay
          (requestTimestamp - clientTimestamp) > replayGuardValidityWindow) {
        return _invalid();
      }

      // =====================
      // REPLAY CHECK
      // =====================
      //
      // If nonce already exists and hasn't expired:
      // -> request has already been processed
      // -> this is a replay attack
      final isCacheValid = cache.isValid(
        nonce: nonce,
        requestTimestamp: requestTimestamp,
        validityWindow: replayGuardValidityWindow,
      );

      if (!isCacheValid) {
        // RGMWRRD: replay guard middle ware replay request detected
        return Core.util.response.error(400, errorCode: _replayRequestDetected);
      }

      // Continue request pipeline
      return innerHandler(request);
    };
  };
}

Middleware _redisHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Global kill-switch for replay guard
      if (!Core.config.enableSecurity) {
        return innerHandler(request);
      }
      // Allow specific endpoints to bypass replay guard
      if (Core.service.config.replayGuardEndpointPassthrough(
        request.url.path,
      )) {
        return innerHandler(request);
      }

      Map<String, dynamic> replayGuardData;

      // if encryption is enabled, use context passed by crypto middleware
      try {
        // Use decrypted context if encryption is enabled
        replayGuardData = request.context;
      } catch (_) {
        return _invalid();
      }

      final nonce = replayGuardData['nonce'];
      final isUuid = Core.util.uuid.isValidUuidV4(nonce);

      // validate if nonce is correct format
      if (!isUuid) {
        return _invalid();
      }

      // =====================
      // PARSE TIMESTAMP
      // =====================
      //
      // Accept both:
      // - int (preferred)
      // - string (fallback)
      //
      // This prevents subtle client inconsistencies from breaking validation.
      final rawTimestamp = replayGuardData['timestamp'];
      final int? clientTimestamp = rawTimestamp is int
          ? rawTimestamp
          : int.tryParse(rawTimestamp?.toString() ?? '');

      // Server time (source of truth)
      final requestTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Allowed request lifetime (5 minutes)
      // value is milliseconds
      final replayGuardValidityWindow = Core.config.replayGuardValidityWindow;

      final redis = Core.service.redis;

      // =====================
      // VALIDATE NONCE
      // =====================
      //
      // Nonce must:
      // - exist
      // - be a string
      // - not be empty
      //
      // This ensures each request can be uniquely identified.
      if (nonce is! String || nonce.isEmpty) {
        return _invalid();
      }

      // =====================
      // VALIDATE TIMESTAMP
      // =====================
      //
      // Protects against:
      // - replaying old requests (expired)
      // - preplay attacks (future timestamps)
      //
      // Conditions:
      // - must be valid integer
      // - must not be in the future
      // - must be within allowed window
      if (clientTimestamp == null ||
          clientTimestamp > requestTimestamp || // prevent future replay
          (requestTimestamp - clientTimestamp) > replayGuardValidityWindow) {
        return _invalid();
      }

      // =====================
      // ATOMIC REPLAY PROTECTION
      // =====================
      //
      // SET NX ensures:
      // - only ONE request can store this nonce
      // - others are rejected immediately
      // - no race condition
      //
      // TTL = replay window -> nonce lives exactly as long as needed
      try {
        final success = await redis.setnx(
          redis.nsReplayGuard(nonce),
          clientTimestamp.toString(),
          expiresAtMs: Core.util.unix.setExpiry(minutes: 5),
        );

        if (!success) {
          // RGMWRRD: replay guard middle ware replay request detected
          return Core.util.response.error(
            400,
            errorCode: _replayRequestDetected,
          );
        }
      } catch (e) {
        // =====================
        // FAIL-OPEN (OPTIONAL)
        // =====================
        //
        // If Redis fails, allow request instead of breaking system.
        // Change this to fail-closed if you want strict security.
        return innerHandler(request);
      }

      // Continue request pipeline
      return innerHandler(request);
    };
  };
}

// =====================
// SHARED INVALID RESPONSE
// =====================
//
// Generic error response to avoid leaking validation details.
// Prevents attackers from probing which field failed.
Response _invalid() {
  // RGMWGR: replay guard middle ware generic response
  return Core.util.response.error(400, errorCode: _genericResponse);
}
