import 'package:shelf_server/_core/core.dart';

/// MasterConfig defines how the server will run
class ConfigService {
  // performs two operations
  //
  // - whether the normalizedPath matches exactly one of values in the userScopeList
  // - whether the normalizedPath matches the start of one of values in the userScopeList
  //
  // this logic accomodates fragmented urls like domain.com/fullname/<fname>/<lname>
  // this also accomodate endpoints with trailing dashes
  bool _isUserInScope(List<String> userScopeList, String normalizedPath) {
    return userScopeList.any((scope) {
      return normalizedPath == scope || normalizedPath.startsWith('$scope/');
    });
  }

  /// Check if request is allowed by scope
  /// - 0: guest
  /// - 1: user
  /// - 99: admin
  bool isTokenWithinScope({required int role, required String requestUrlPath}) {
    final normalizedPath = '/$requestUrlPath';
    final guestScope = Core.config.guestTokenScope;
    final adminScope = Core.config.adminTokenScope;
    final bool isGuestScope = _isUserInScope(guestScope, normalizedPath);
    final bool isAdminScope = _isUserInScope(adminScope, normalizedPath);

    switch (role) {
      case 0:
        // if guest, only allow access to guest endpoints
        return isGuestScope;
      case 1:
        // if user, return true if scope is not guest and not admin
        return !(isGuestScope || isAdminScope);
      case 99:
        // if admin, also allow access to admin endpoints
        return true;
      default:
        return false;
    }
  }

  // ======================
  // Authentication service
  // ======================
  /// endpoints that will bypass access token check
  ///
  /// this is to allow handshake because
  /// initial handshake has no access token yet
  bool accessTokenEndpointPassthrough(String requestUrlPath) {
    final normalizedPath = '/$requestUrlPath';
    final endpointList = Core.config.accessTokenEndpointPassthrough;

    return endpointList.contains(normalizedPath);
  }

  // ====================
  // Cryptography service
  // ====================
  /// endpoints that will ignore encryption/decryption if enableSecurity is true
  bool cryptoEndpointPassthrough(String requestUrlPath) {
    final normalizedPath = '/$requestUrlPath';
    final endpointList = Core.config.cryptoEndpointPassthrough;

    return endpointList.contains(normalizedPath);
  }

  /// endpoints that will ignore replay guard if enableSecurity is true
  bool replayGuardEndpointPassthrough(String requestUrlPath) {
    final normalizedPath = '/$requestUrlPath';
    final endpointList = Core.config.replayGuardEndpointPassthrough;

    return endpointList.contains(normalizedPath);
  }
}
