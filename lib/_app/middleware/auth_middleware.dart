import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_core/core.dart';

// AMWICC: auth middle ware invalid client credentials
const _invalidClientCredentails = 'AMWICC';
// AMWMAT: auth middle ware missing access token
const _missingAccessToken = 'AMWMAT';
// AMWITS: auth middle ware invalid token scope
const _invalidTokenScope = 'AMWITS';
// AMWITP: auth middle ware invalid token provided
const _invalidTokenProvided = 'AMWITP';
// AMWTPE: auth middle ware token processing exception
const _tokenException = 'AMWTPE';

Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Global kill-switch for authentication
      if (!Core.config.enableSecurity) {
        return innerHandler(request);
      }

      // =====================
      // MANAGE CLIENT ID
      // =====================

      final requestHeader = request.headers;

      final appId = requestHeader['x-app-id'];
      final accessToken = requestHeader['x-access-token'];

      String deviceId = '';

      // Validate client identity (acts like API key / client gate)
      //
      // This is NOT user authentication — just client validation
      if (!Core.config.appId.contains(appId)) {
        // AMWICC: auth middle ware invalid client credentials
        return Core.util.response.error(
          401,
          errorCode: _invalidClientCredentails,
        );
      }

      // =====================
      // BYPASS ACCESS TOKEN
      // =====================

      // Allow endpoints that do not yet have a token
      // (e.g. login, handshake, token issuance)
      //
      // These endpoints must be VERY limited and carefully controlled
      if (Core.service.config.accessTokenEndpointPassthrough(
        request.url.path,
      )) {
        return innerHandler(request);
      }

      // =====================
      // MANAGE ACCESS TOKEN
      // =====================

      // Require token for all protected endpoints
      if (accessToken == null) {
        // AMWMAT: auth middle ware missing access token
        return Core.util.response.error(401, errorCode: _missingAccessToken);
      }

      try {
        // Verify signature + expiration
        final tokenMap = Core.service.jwt.verifyToken(accessToken);

        // =====================
        // SCOPE VALIDATION
        // =====================

        // Assumes JWT always contains `scope` as List
        // If schema changes, this can throw
        final int role = tokenMap['role'] as int;

        // Check if request is allowed by scope
        final bool isTokenWithinScope = Core.service.config.isTokenWithinScope(
          role: role,
          requestUrlPath: request.url.path,
        );

        if (!isTokenWithinScope) {
          // AMWITS: auth middle ware invalid token scope
          return Core.util.response.error(403, errorCode: _invalidTokenScope);
        }

        // =====================
        // EXTRACT DEVICE ID
        // =====================
        // Identifies the user and their keys via deviceId
        deviceId = tokenMap['deviceId'];

        if (tokenMap['deviceId'] is! String || tokenMap['deviceId'].isEmpty) {
          // AMWITP: auth middle ware invalid token provided
          return Core.util.response.error(
            401,
            errorCode: _invalidTokenProvided,
          );
        }
      } catch (e) {
        // Covers:
        // - Invalid signature
        // - Expired token
        // - Malformed token

        // AMWTPE: auth middle ware token processing exception
        return Core.util.response.error(401, errorCode: _tokenException);
      }

      // =====================
      // CONTEXT PROPAGATION
      // =====================

      // Attach deviceId for downstream middleware (e.g. cryptoMiddleware)
      //
      // cryptoMiddleware EXPECTS `deviceId` to exist
      final updatedRequest = request.change(
        context: {...request.context, 'deviceId': deviceId},
      );

      return innerHandler(updatedRequest);
    };
  };
}
