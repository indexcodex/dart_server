import 'dart:convert';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_core/core.dart';
import 'package:shelf_server/_core/enum/shelf_server_type.dart';
import 'package:shelf_server/_core/service/ecc/model/ecc_keys.dart';
import 'package:shelf_server/_core/service/memcache/ecc/model/ecc_user_key_data.dart';

void handshakeInit(RouterPlus app) {
  app.post('/handshake/init', (Request req) async {
    if (!Core.config.enableSecurity) {
      return Core.util.response.success({
        'securityEnabled': false,
        'serverPubkey': null,
        'accessToken': null,
        'expires': null,
      });
    }

    switch (Core.config.serverType) {
      case ShelfServerType.monolith:
        return _memoryHandler(req);
      case ShelfServerType.microservice:
        return _redisHandler(req);
    }
  });
}

Future<Response> _memoryHandler(Request req) async {
  Map<String, dynamic> requestJson = {};
  String deviceId = '';
  String clientPubkey = '';
  String? serverPubkey;
  String? serverPrvkey;
  String? accessToken;
  int expires = Core.util.unix.setExpiry(hours: 24);
  bool securityEnabled = Core.config.enableSecurity;
  final cache = Core.service.memcache.ecc;
  final int memcacheRecordLimit = Core.config.memcacheRecordLimit;
  final int requestTimestamp = DateTime.now().millisecondsSinceEpoch;

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
  // PARSE REQUEST
  // =====================
  try {
    requestJson = await req.body.asJson;

    if (requestJson['deviceId'] is! String ||
        requestJson['clientPubkey'] is! String) {
      // HSIDTM: hand shake init data type mismatch
      return Core.util.response.error(400, errorCode: 'HSIDTM');
    }

    deviceId = requestJson['deviceId'];
    clientPubkey = requestJson['clientPubkey'];

    if (deviceId.trim().isEmpty || clientPubkey.trim().isEmpty) {
      // HSIMRF: hand shake init missing required field
      return Core.util.response.error(400, errorCode: 'HSIMRF');
    }
  } catch (e) {
    // HSIIRF: hand shake init invalid request format
    return Core.util.response.error(400, errorCode: 'HSIIRF');
  }

  // =====================
  // ENCRYPTION FLOW (OPTIONAL)
  // =====================

  // Generate ECC keys
  try {
    EccKeys serverKeyPair = Core.service.ecc.generateKeyPair();
    serverPubkey = serverKeyPair.publicKeyBase64;
    serverPrvkey = serverKeyPair.privateKeyBase64;
  } catch (e) {
    return Response(
      500,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Internal Server Error',
        'detail': 'Failed to generate security keys, please try again',
      }),
    );
  }

  // Store in DB
  try {
    await Core.service.sql.query(
      '''
          INSERT INTO keystore (
            device_id,
            client_pubkey,
            server_pubkey,
            server_prvkey,
            expires
          )
          VALUES (?,?,?,?,?)
          ON DUPLICATE KEY UPDATE
            client_pubkey = VALUES(client_pubkey),
            server_pubkey = VALUES(server_pubkey),
            server_prvkey = VALUES(server_prvkey),
            expires = VALUES(expires);
          ''',
      [deviceId, clientPubkey, serverPubkey, serverPrvkey, expires],
    );
  } catch (e) {
    return Response(
      500,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Internal Server Error',
        'detail': 'Failed to connect to database',
      }),
    );
  }

  // =====================
  // GENERATE ACCESS TOKEN
  // =====================

  try {
    accessToken = Core.service.jwt.generateToken({
      'role': 0, // 0:guest, 1:user, 99:admin
      'deviceId': deviceId,
    });
  } catch (e) {
    // HSITGF: hand shake init token generation failed
    return Core.util.response.error(500, errorCode: 'HSITGF');
  }

  // =====================
  // RESPONSE
  // =====================
  return Response(
    200,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'securityEnabled': securityEnabled,
      'serverPubkey': serverPubkey, // null if encryption OFF
      'accessToken': accessToken,
      'expires': expires,
    }),
  );
}

Future<Response> _redisHandler(Request req) async {
  Map<String, dynamic> requestJson = {};
  String deviceId = '';
  String clientPubkey = '';
  String? serverPubkey;
  String? serverPrvkey;
  String? accessToken;
  int expires = Core.util.unix.setExpiry(hours: 24);
  bool securityEnabled = Core.config.enableSecurity;
  final redis = Core.service.redis;

  // =====================
  // PARSE REQUEST
  // =====================
  try {
    requestJson = await req.body.asJson;

    if (requestJson['deviceId'] is! String ||
        requestJson['clientPubkey'] is! String) {
      // HSIDTM: hand shake init data type mismatch
      return Core.util.response.error(400, errorCode: 'HSIDTM');
    }

    deviceId = requestJson['deviceId'];
    clientPubkey = requestJson['clientPubkey'];

    if (deviceId.trim().isEmpty || clientPubkey.trim().isEmpty) {
      // HSIMRF: hand shake init missing required field
      return Core.util.response.error(400, errorCode: 'HSIMRF');
    }
  } catch (e) {
    // HSIIRF: hand shake init invalid request format
    return Core.util.response.error(400, errorCode: 'HSIIRF');
  }

  // =====================
  // ENCRYPTION FLOW
  // =====================
  // Generate ECC keys
  try {
    EccKeys serverKeyPair = Core.service.ecc.generateKeyPair();
    serverPubkey = serverKeyPair.publicKeyBase64;
    serverPrvkey = serverKeyPair.privateKeyBase64;
  } catch (e) {
    // HSIKGF: hand shake init key generation failed
    return Core.util.response.error(500, errorCode: 'HSIKGF');
  }

  // Store in DB
  try {
    await Core.service.sql.query(
      '''
          INSERT INTO keystore (
            device_id,
            client_pubkey,
            server_pubkey,
            server_prvkey,
            expires
          )
          VALUES (?,?,?,?,?)
          ON DUPLICATE KEY UPDATE
            client_pubkey = VALUES(client_pubkey),
            server_pubkey = VALUES(server_pubkey),
            server_prvkey = VALUES(server_prvkey),
            expires = VALUES(expires);
          ''',
      [deviceId, clientPubkey, serverPubkey, serverPrvkey, expires],
    );
  } catch (e) {
    // HSIDCF: hand shake init database connection failed
    return Core.util.response.error(500, errorCode: 'HSIDCF');
  }

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

  // =====================
  // GENERATE ACCESS TOKEN
  // =====================
  try {
    accessToken = Core.service.jwt.generateToken({
      'role': 0, // 0:guest, 1:user, 99:admin
      'deviceId': deviceId,
    });
  } catch (e) {
    // HSITGF: hand shake init token generation failed
    return Core.util.response.error(500, errorCode: 'HSITGF');
  }

  // =====================
  // RESPONSE
  // =====================
  return Core.util.response.success({
    'securityEnabled': securityEnabled,
    'serverPubkey': serverPubkey,
    'accessToken': accessToken,
    'expires': expires,
  });
}
