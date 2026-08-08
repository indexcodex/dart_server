// =====================
// RATE LIMIT CACHE
// =====================

/// In-memory rate limit tracker
/// Keyed by identifier (e.g. IP address)
class RateLimitCache {
  /// Internal storage (key -> rate limit data)
  final Map<String, _RateLimitData> _store = {};

  /// Check if a request is valid
  ///
  /// - [identifier]: unique identifier of the request (in this case, ip address)
  /// - [requestLimit]: max requests allowed per validityWindow
  /// - [requestTimestamp]: current timestamp (ms)
  /// - [validityWindow]: the window where the request is valid (ms)
  ///
  /// Returns:
  /// - true: request allowed
  /// - false: rate limit exceeded
  bool isValid({
    required String identifier,
    required int requestLimit,
    required int requestTimestamp,
    required int validityWindow,
  }) {
    final record = _store[identifier];

    // =====================
    // FIRST REQUEST
    // =====================
    if (record == null) {
      _store[identifier] = _RateLimitData(
        count: 1,
        expires: requestTimestamp + validityWindow,
      );
      return true;
    }

    // =====================
    // WITHIN WINDOW
    // =====================
    // if request is not expired yet
    if (requestTimestamp < record.expires) {
      // if request count exceeds or equal the limit
      if (record.count >= requestLimit) {
        return false;
      }

      // if request count is still valid
      record.count++;
      return true;
    }

    // =====================
    // WINDOW EXPIRED (RESET)
    // =====================
    record
      ..count = 1
      ..expires = requestTimestamp + validityWindow;

    return true;
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
    _store.removeWhere((_, v) => v.expires < now);
  }

  /// Check if a valid (non-expired) entry exists for the given key.
  ///
  /// Returns:
  /// - true  -> an entry exists AND is still within its valid time window
  /// - false -> no entry exists OR the entry has expired (and is removed)
  ///
  /// Notes:
  /// - This is a read-only check (does not create or update entries)
  /// - Expired entries are lazily removed during this check
  /// - Use for inspection/metrics, not enforcement (use `isAllowed` instead)
  bool exists(String key) {
    final record = _store[key];
    if (record == null) return false;

    if (record.expires < DateTime.now().millisecondsSinceEpoch) {
      _store.remove(key);
      return false;
    }

    return true;
  }

  /// Remove a specific key
  void remove(String key) {
    _store.remove(key);
  }

  /// Clear all entries
  void clear() {
    _store.clear();
  }

  /// Current number of tracked keys
  int get size => _store.length;
}

// =====================
// INTERNAL DATA MODEL
// =====================

class _RateLimitData {
  _RateLimitData({required this.count, required this.expires});
  int count;
  int expires;
}
