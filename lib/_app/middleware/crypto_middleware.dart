import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_core/core.dart';
import 'package:shelf_server/_core/enum/shelf_server_type.dart';
import 'package:shelf_server/_core/service/memcache/ecc/model/ecc_user_key_data.dart';

// CMWMDC: crypto middle ware missing device context
const _missingDeviceContext = 'CMWMDC';
// CMWDNR: crypto middle ware device not registered
const _deviceNotRegistered = 'CMWDNR';
// CMWDKVF: crypto middle ware device keys validation failed
const _deviceKeysValidationFailed = 'CMWDKVF';
// CMWDCE: crypto middle ware database connection error
const _databaseConnectionError = 'CMWDCE';
// CMWDKE: crypto middle ware device keys expired
const _deviceKeysExpired = 'CMWDKE';
// CMWMSK: crypto middle ware missing security key
const _missingSecurityKey = 'CMWMSK';
// CMWPTL: crypto middle ware payload too large
const _payloadTooLarge = 'CMWPTL';
// CMWDPE: crypto middle ware decrypt processing exception
const _decryptException = 'CMWDPE';
// CMWRTL: crypto middle ware response too large
const _responseTooLarge = 'CMWRTL';
// CMWEPE: crypto middle ware encrypt processing exception
const _encryptException = 'CMWEPE';

/// Crypto middleware (ECC-based)
///
/// Responsibilities:
/// 1. Fetch device-specific keypair (cache -> DB fallback)
/// 2. Decrypt incoming request body
/// 3. Pass decrypted payload downstream
/// 4. Encrypt outgoing response body
///
/// Important:
/// - Only applies when Core.config.enableSecurity == true
/// - Certain endpoints can bypass encryption entirely
Middleware cryptoMiddleware() {
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
      // Global kill-switch for encryption
      if (!Core.config.enableSecurity) {
        return innerHandler(request);
      }
      // Allow specific endpoints to bypass crypto (e.g. login, health checks)
      if (Core.service.config.cryptoEndpointPassthrough(request.url.path)) {
        return innerHandler(request);
      }

      // =====================
      // MARK: PREPARE KEYS
      // =====================

      // Device ID is injected earlier in middleware chain
      final deviceIdRaw = request.context['deviceId'];

      // Defensive validation:
      // - Must exist
      // - Must be a non-empty string
      if (deviceIdRaw is! String || deviceIdRaw.isEmpty) {
        // CMWMDC: crypto middle ware missing device context
        return Core.util.response.error(401, errorCode: _missingDeviceContext);
      }

      // Safe to use after validation
      final String deviceId = deviceIdRaw;

      // These will be populated from cache OR DB
      String serverPrvkey = '';
      String serverPubkey = '';
      String clientPubkey = '';
      int expires = 0;

      // ---------------------
      // CACHE FIRST STRATEGY
      // ---------------------
      // Avoid DB hit if keys already cached
      final userKeys = Core.service.memcache.ecc.get(deviceId);

      if (userKeys != null) {
        // Fast path (no DB call)
        Core.util.log.devPrint('memcache hit');

        serverPrvkey = userKeys.serverPrvkey;
        serverPubkey = userKeys.serverPubkey;
        clientPubkey = userKeys.clientPubkey;
      } else {
        // Slow path (DB lookup)
        Core.util.log.devPrint('memcache miss, querying DB');

        try {
          final queryResult = await Core.service.sql.query(
            '''
              SELECT * FROM keystore
              WHERE device_id=?
            ''',
            [deviceId],
          );

          // Convert DB row to Map
          final Map<String, dynamic>? dataMap = Core.service.sql
              .getSingleRecord(queryResult);

          // No record = invalid/unregistered device
          if (dataMap == null) {
            // CMWDNR: crypto middle ware device not registered
            return Core.util.response.error(
              401,
              errorCode: _deviceNotRegistered,
            );
          }

          // Validate required fields BEFORE assigning
          // Prevents null -> runtime crash later
          if (dataMap['server_prvkey'] == null ||
              dataMap['server_pubkey'] == null ||
              dataMap['client_pubkey'] == null ||
              dataMap['expires'] == null) {
            // CMWDKVF: crypto middle ware device keys validation failed
            return Core.util.response.error(
              500,
              errorCode: _deviceKeysValidationFailed,
            );
          }

          // Safe assignment after validation
          serverPrvkey = dataMap['server_prvkey'];
          serverPubkey = dataMap['server_pubkey'];
          clientPubkey = dataMap['client_pubkey'];

          // NOTE:
          // Assumes DB always returns int (BIGINT recommended).
          // If schema changes -> this is a potential crash point.
          expires = dataMap['expires'] as int;
        } catch (e) {
          // Any DB-related failure is handled here
          // CMWDCE: crypto middle ware database connection error
          return Core.util.response.error(
            500,
            errorCode: _databaseConnectionError,
          );
        }

        // Validate expiration AFTER fetching
        // Prevents using stale/compromised keys
        final now = DateTime.now().millisecondsSinceEpoch;
        if (expires < now) {
          // CMWDKE: crypto middle ware device keys expired
          return Core.util.response.error(401, errorCode: _deviceKeysExpired);
        }

        // Cache result to avoid repeated DB hits
        Core.service.memcache.ecc.set(
          EccUserKeyData(
            deviceId: deviceId,
            clientPubkey: clientPubkey,
            serverPubkey: serverPubkey,
            serverPrvkey: serverPrvkey,
            expires: expires,
          ),
        );
      }

      // Final safety check before crypto operations
      if (serverPrvkey.isEmpty ||
          serverPubkey.isEmpty ||
          clientPubkey.isEmpty) {
        // CMWMSK: crypto middle ware missing security key
        return Core.util.response.error(500, errorCode: _missingSecurityKey);
      }

      // =====================
      // MARK: HANDLE REQUEST
      // =====================

      String cipherText = '';
      String decryptedMessage = '';
      Request updatedRequest;

      final isMultiPartRequest = Core.util.request.isMultipartFormdata(request);

      try {
        if (!isMultiPartRequest) {
          // IMPORTANT:
          // Request body is a stream -> can only be read ONCE
          cipherText = await request.readAsString();
        }

        // Protect against large payload attacks (DoS / memory pressure)
        if (cipherText.length > Core.config.maxPayloadSize) {
          // CMWPTL: crypto middle ware payload too large
          return Core.util.response.error(413, errorCode: _payloadTooLarge);
        }

        // Only decrypt if payload exists
        if (cipherText.isNotEmpty) {
          decryptedMessage = Core.service.ecc.decrypt(
            encryptedPayload: cipherText,
            myPrivateKeyBase64: serverPrvkey,
          );
        }

        // ---------------------
        // DECRYPT REPLAY GUARD
        // ---------------------
        final guardHeader = request.headers['x-guard'];

        final decryptedHeader = Core.service.ecc.decrypt(
          encryptedPayload: guardHeader ?? '',
          myPrivateKeyBase64: serverPrvkey,
        );

        final Map<String, dynamic> guardHeaderData = jsonDecode(
          decryptedHeader,
        );

        final String nonce = guardHeaderData['nonce'];
        final int clientTimestamp = guardHeaderData['timestamp'];

        Map<String, Object?>? updatedContext = {
          ...request.context,
          'nonce': nonce,
          'timestamp': clientTimestamp,
        };

        // IMPORTANT:
        // Must replace request after reading body
        updatedRequest = cipherText.isEmpty
            ? request.change(context: updatedContext)
            : request.change(body: decryptedMessage, context: updatedContext);
      } catch (e) {
        // CMWDPE: crypto middle ware decrypt processing exception
        return Core.util.response.error(400, errorCode: _decryptException);
      }

      // =====================
      // MARK: HANDLE RESPONSE
      // =====================

      final response = await innerHandler(updatedRequest);

      // Do NOT encrypt error responses
      // Keeps debugging + client handling simpler
      //
      // Do NOT encrypt empty success responses (response code 204)
      // Prevents encryption overhead
      if (response.statusCode >= 400 || response.statusCode == 204) {
        return response;
      }

      String plainText = '';
      String encryptedMessage = '';
      Response updatedResponse;

      try {
        // Same rule: response body can only be read once
        plainText = await response.readAsString();

        // Prevent large response payload issues
        if (plainText.length > Core.config.maxPayloadSize) {
          // CMWRTL: crypto middle ware response too large
          return Core.util.response.error(500, errorCode: _responseTooLarge);
        }

        // Remove headers invalidated by body transformation
        final baseHeaders = Map<String, String>.from(response.headers)
          ..remove('content-encoding')
          ..remove('content-length');

        // Handle empty response separately
        if (plainText.isEmpty) {
          return response.change(
            body: '',
            headers: {
              ...baseHeaders,
              'content-type': 'application/octet-stream',
            },
          );
        }

        // Encrypt response payload
        encryptedMessage = Core.service.ecc.encrypt(
          theirPubkey: Core.service.ecc.stringToPublicKey(clientPubkey),
          myPubkey: Core.service.ecc.stringToPublicKey(serverPubkey),
          myPvkey: Core.service.ecc.stringToPrivateKey(serverPrvkey),
          plainTextData: plainText,
        );

        // Return transformed response
        updatedResponse = response.change(
          body: encryptedMessage,
          headers: {...baseHeaders, 'content-type': 'application/octet-stream'},
        );
      } catch (e) {
        // CMWEPE: crypto middle ware encrypt processing exception
        return Core.util.response.error(500, errorCode: _encryptException);
      }

      return updatedResponse;
    };
  };
}

Middleware _redisHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Global kill-switch for encryption
      if (!Core.config.enableSecurity) {
        return innerHandler(request);
      }
      // Allow specific endpoints to bypass crypto (e.g. login, health checks)
      if (Core.service.config.cryptoEndpointPassthrough(request.url.path)) {
        return innerHandler(request);
      }

      // =====================
      // MARK: PREPARE KEYS
      // =====================

      // Device ID is injected earlier in middleware chain
      final deviceIdRaw = request.context['deviceId'];

      // Defensive validation:
      // - Must exist
      // - Must be a non-empty string
      if (deviceIdRaw is! String || deviceIdRaw.isEmpty) {
        // CMWMDC: crypto middle ware missing device context
        return Core.util.response.error(401, errorCode: _missingDeviceContext);
      }

      // Safe to use after validation
      final String deviceId = deviceIdRaw;

      // These will be populated from cache OR DB
      String serverPrvkey = '';
      String serverPubkey = '';
      String clientPubkey = '';
      int expires = 0;

      // ---------------------
      // CACHE FIRST STRATEGY
      // ---------------------
      // Avoid DB hit if keys already cached
      final redis = Core.service.redis;
      final String nsEccUserKeys = redis.nsEccUserKeys(deviceId);
      final userEccKeysRaw = await redis.getJson(nsEccUserKeys);

      if (userEccKeysRaw != null) {
        // Fast path (no DB call)
        Core.util.log.devPrint('redis hit');
        final EccUserKeyData userKeys = EccUserKeyData.fromJson(userEccKeysRaw);

        serverPrvkey = userKeys.serverPrvkey;
        serverPubkey = userKeys.serverPubkey;
        clientPubkey = userKeys.clientPubkey;
      } else {
        // Slow path (DB lookup)
        Core.util.log.devPrint('redis miss, querying DB');

        try {
          final queryResult = await Core.service.sql.query(
            '''
              SELECT * FROM keystore
              WHERE device_id=?
            ''',
            [deviceId],
          );

          // Convert DB row to Map
          final Map<String, dynamic>? dataMap = Core.service.sql
              .getSingleRecord(queryResult);

          // No record = invalid/unregistered device
          if (dataMap == null) {
            // CMWDNR: crypto middle ware device not registered
            return Core.util.response.error(
              401,
              errorCode: _deviceNotRegistered,
            );
          }

          // Validate required fields BEFORE assigning
          // Prevents null -> runtime crash later
          if (dataMap['server_prvkey'] == null ||
              dataMap['server_pubkey'] == null ||
              dataMap['client_pubkey'] == null ||
              dataMap['expires'] == null) {
            // CMWDKVF: crypto middle ware device keys validation failed
            return Core.util.response.error(
              500,
              errorCode: _deviceKeysValidationFailed,
            );
          }

          // Safe assignment after validation
          serverPrvkey = dataMap['server_prvkey'];
          serverPubkey = dataMap['server_pubkey'];
          clientPubkey = dataMap['client_pubkey'];

          // NOTE:
          // Assumes DB always returns int (BIGINT recommended).
          // If schema changes -> this is a potential crash point.
          expires = dataMap['expires'] as int;
        } catch (e) {
          // Any DB-related failure is handled here
          // CMWDCE: crypto middle ware database connection error
          return Core.util.response.error(
            500,
            errorCode: _databaseConnectionError,
          );
        }

        // Validate expiration AFTER fetching
        // Prevents using stale/compromised keys
        final now = DateTime.now().millisecondsSinceEpoch;
        if (expires < now) {
          // CMWDKE: crypto middle ware device keys expired
          return Core.util.response.error(401, errorCode: _deviceKeysExpired);
        }

        // Cache result to avoid repeated DB hits
        // Cache keys
        await redis.setJson(
          redis.nsEccUserKeys(deviceId),
          EccUserKeyData(
            deviceId: deviceId,
            clientPubkey: clientPubkey,
            serverPubkey: serverPubkey,
            serverPrvkey: serverPrvkey,
            expires: expires,
          ).toJson(),
          expiresAtMs: expires,
        );
      }

      // Final safety check before crypto operations
      if (serverPrvkey.isEmpty ||
          serverPubkey.isEmpty ||
          clientPubkey.isEmpty) {
        // CMWMSK: crypto middle ware missing security key
        return Core.util.response.error(500, errorCode: _missingSecurityKey);
      }

      // =====================
      // MARK: HANDLE REQUEST
      // =====================

      String cipherText = '';
      String decryptedMessage = '';
      Request updatedRequest;

      try {
        // IMPORTANT:
        // Request body is a stream -> can only be read ONCE
        cipherText = await request.readAsString();

        // Protect against large payload attacks (DoS / memory pressure)
        if (cipherText.length > Core.config.maxPayloadSize) {
          // CMWPTL: crypto middle ware payload too large
          return Core.util.response.error(413, errorCode: _payloadTooLarge);
        }

        // Only decrypt if payload exists
        if (cipherText.isNotEmpty) {
          decryptedMessage = Core.service.ecc.decrypt(
            encryptedPayload: cipherText,
            myPrivateKeyBase64: serverPrvkey,
          );
        }

        // ---------------------
        // DECRYPT REPLAY GUARD
        // ---------------------
        final guardHeader = request.headers['x-guard'];

        final decryptedHeader = Core.service.ecc.decrypt(
          encryptedPayload: guardHeader ?? '',
          myPrivateKeyBase64: serverPrvkey,
        );

        final Map<String, dynamic> guardHeaderData = jsonDecode(
          decryptedHeader,
        );

        final String nonce = guardHeaderData['nonce'];
        final int clientTimestamp = guardHeaderData['timestamp'];

        Map<String, Object?>? updatedContext = {
          ...request.context,
          'nonce': nonce,
          'timestamp': clientTimestamp,
        };

        // IMPORTANT:
        // Must replace request after reading body
        updatedRequest = cipherText.isEmpty
            ? request.change(context: updatedContext)
            : request.change(body: decryptedMessage, context: updatedContext);
      } catch (e) {
        // CMWDPE: crypto middle ware decrypt processing exception
        return Core.util.response.error(400, errorCode: _decryptException);
      }

      // =====================
      // MARK: HANDLE RESPONSE
      // =====================

      final response = await innerHandler(updatedRequest);

      // Do NOT encrypt error responses
      // Keeps debugging + client handling simpler
      //
      // Do NOT encrypt empty success responses (response code 204)
      // Prevents encryption overhead
      if (response.statusCode >= 400 || response.statusCode == 204) {
        return response;
      }

      String plainText = '';
      String encryptedMessage = '';
      Response updatedResponse;

      try {
        // Same rule: response body can only be read once
        plainText = await response.readAsString();

        // Prevent large response payload issues
        if (plainText.length > Core.config.maxPayloadSize) {
          // CMWRTL: crypto middle ware response too large
          return Core.util.response.error(500, errorCode: _responseTooLarge);
        }

        // Remove headers invalidated by body transformation
        final baseHeaders = Map<String, String>.from(response.headers)
          ..remove('content-encoding')
          ..remove('content-length');

        // Handle empty response separately
        if (plainText.isEmpty) {
          return response.change(
            body: '',
            headers: {
              ...baseHeaders,
              'content-type': 'application/octet-stream',
            },
          );
        }

        // Encrypt response payload
        encryptedMessage = Core.service.ecc.encrypt(
          theirPubkey: Core.service.ecc.stringToPublicKey(clientPubkey),
          myPubkey: Core.service.ecc.stringToPublicKey(serverPubkey),
          myPvkey: Core.service.ecc.stringToPrivateKey(serverPrvkey),
          plainTextData: plainText,
        );

        // Return transformed response
        updatedResponse = response.change(
          body: encryptedMessage,
          headers: {...baseHeaders, 'content-type': 'application/octet-stream'},
        );
      } catch (e) {
        // CMWEPE: crypto middle ware encrypt processing exception
        return Core.util.response.error(500, errorCode: _encryptException);
      }

      return updatedResponse;
    };
  };
}
