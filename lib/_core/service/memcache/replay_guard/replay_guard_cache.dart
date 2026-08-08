// =====================
// REPLAY GUARD CACHE
// =====================

/// In-memory cache for replay protection
/// Keyed by nonce
class ReplayGuardCache {
  /// In-memory cache for replay protection
  ///
  /// key   = nonce (unique per request)
  /// value = expiry timestamp (ms since epoch)
  ///
  /// A nonce is accepted only once within a time window.
  /// If reused before expiry -> considered a replay attack.
  final Map<String, int> _store = {};

  /// Check if nonce is valid and store it
  ///
  /// - key: identifier (e.g. IP)
  /// - [nonce]: unique identifier of the request
  /// - [requestTimestamp]: current timestamp (ms)
  /// - [validityWindow]: the window where the request is valid (ms)
  ///
  /// Returns:
  /// - true: request allowed (not replay)
  /// - false: replay detected
  bool isValid({
    required String nonce,
    required int requestTimestamp,
    required int validityWindow,
  }) {
    final expiry = _store[nonce];

    // =====================
    // REPLAY DETECTED
    // =====================
    //
    // If nonce already exists and hasn't expired:
    // -> request has already been processed
    // -> this is a replay attack
    if (expiry != null && expiry > requestTimestamp) {
      return false;
    }

    // =====================
    // STORE NONCE
    // =====================
    //
    // Store nonce with expiry equal to allowed request window.
    //
    // Guarantees:
    // - nonce cannot be reused within valid window
    // - entries naturally expire and get cleaned up later
    _store[nonce] = requestTimestamp + validityWindow;

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
    _store.removeWhere((_, expiry) => expiry < now);
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
  bool exists(String nonce) {
    final expiry = _store[nonce];
    if (expiry == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;

    if (expiry < now) {
      _store.remove(nonce);
      return false;
    }

    return true;
  }

  /// Remove a specific nonce
  void remove(String nonce) {
    _store.remove(nonce);
  }

  /// Clear all entries
  void clear() {
    _store.clear();
  }

  /// Current cache size
  int get size => _store.length;
}
