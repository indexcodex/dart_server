import 'package:shelf_server/_core/service/memcache/ecc/ecc_user_key_cache.dart';
import 'package:shelf_server/_core/service/memcache/jwt/jwt_server_key_cache.dart';
import 'package:shelf_server/_core/service/memcache/rate_limit/rate_limit_cache.dart';
import 'package:shelf_server/_core/service/memcache/replay_guard/replay_guard_cache.dart';

/// Central in-memory cache container
/// Lives for the lifetime of the server process
class Memcache {
  /// JWT signing/verification keys
  /// Loaded once during bootstrap and never changed
  final JwtServerKeyCache jwt = JwtServerKeyCache();

  /// Per-device ECC key cache
  final EccUserKeyCache ecc = EccUserKeyCache();

  /// rate limit data cache
  final RateLimitCache rateLimit = RateLimitCache();

  /// replay guard data cache
  final ReplayGuardCache replayGuard = ReplayGuardCache();
}
