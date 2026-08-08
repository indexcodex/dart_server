import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_core/core.dart';
import 'package:shelf_server/_core/enum/shelf_server_type.dart';

// RLMWRLR: rate limit middle ware rate limit reached
const _rateLimitReached = 'RLMWRLR';

Middleware rateLimitMiddleware() {
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
      final int requestPerSecond = Core.config.requestPerSecond;
      final int requestTimestamp = DateTime.now().millisecondsSinceEpoch;
      final int rateLimitValidityWindow = Core.config.rateLimitValidityWindowMs;

      // =====================
      // IDENTIFIER (IP-based)
      // =====================
      final userIpAddress = Core.util.network.getIpAddress(request);
      if (userIpAddress == null) {
        return innerHandler(request); // skip instead of poisoning cache
      }

      final cache = Core.service.memcache.rateLimit;
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
      // RATE LIMIT CHECK
      // =====================
      //
      // check if how many requests have
      // been done within the validityWindow
      final isCacheValid = cache.isValid(
        identifier: userIpAddress,
        requestLimit: requestPerSecond,
        requestTimestamp: requestTimestamp,
        validityWindow: rateLimitValidityWindow,
      );

      if (!isCacheValid) {
        // RLMWRLR: rate limit middle ware rate limit reached
        return Core.util.response.error(429, errorCode: _rateLimitReached);
      }

      return innerHandler(request);
    };
  };
}

Middleware _redisHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Maximum allowed requests per second (per IP)
      final int limit = Core.config.requestPerSecond;
      final int rateLimitValidityWindow = Core.config.rateLimitValidityWindowMs;

      // Redis service (used for distributed rate limiting)
      final redis = Core.service.redis;

      // =====================
      // IDENTIFY CLIENT
      // =====================
      //
      // Uses IP address as rate limit key.
      // If IP cannot be determined, skip rate limiting to avoid
      // blocking legitimate traffic due to misconfiguration.
      final userIpAddress = Core.util.network.getIpAddress(request);
      if (userIpAddress == null) return innerHandler(request);

      // Namespaced Redis key for this client
      final key = redis.nsRateLimit(userIpAddress);

      try {
        // =====================
        // ATOMIC COUNTER
        // =====================
        //
        // INCR guarantees:
        // - atomic increment across all concurrent requests
        // - correct count even under high concurrency
        //
        // If key does not exist:
        // -> Redis initializes it to 1
        final count = await redis.incr(key);

        // =====================
        // INITIALIZE WINDOW
        // =====================
        //
        // Only the FIRST request (count == 1) sets the TTL.
        //
        // This creates a fixed 1-second window:
        // - all subsequent requests share this window
        // - TTL is NOT refreshed (prevents sliding window bugs)
        if (count == 1) {
          await redis.expire(key, rateLimitValidityWindow); // 1 second window
        }

        // =====================
        // ENFORCE LIMIT
        // =====================
        //
        // If request count exceeds allowed limit:
        // -> reject with HTTP 429 (Too Many Requests)
        if (count > limit) {
          // RLMWRLR: rate limit middle ware rate limit reached
          return Core.util.response.error(429, errorCode: _rateLimitReached);
        }

        // Within limit -> continue request pipeline
        return innerHandler(request);
      } catch (e) {
        // =====================
        // FAIL-OPEN STRATEGY
        // =====================
        //
        // If Redis fails:
        // - DO NOT block requests
        // - Avoid turning infrastructure failure into downtime
        //
        // Tradeoff:
        // - temporary loss of rate limiting
        // - but system remains available
        return innerHandler(request);
      }
    };
  };
}
