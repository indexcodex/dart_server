import 'dart:io';

import 'package:shelf_server/_core/core.dart';

class JwtServerKeyCache {
  /// JWT signing/verification keys
  /// Loaded once during bootstrap and never changed
  late final String pubkey;
  late final String prvkey;

  final _log = Core.util.log;

  /// preload jwt keys and save to memcache
  Future<void> preloadJwtKeys() async {
    if (!Core.config.enableSecurity) {
      _log.devPrint('JWT disabled');
      return;
    }

    final privateKeyFile = File('jwt_private.pem');
    final publicKeyFile = File('jwt_public.pem');

    // =====================
    // GENERATE KEYS IF MISSING
    // =====================
    if (!privateKeyFile.existsSync() || !publicKeyFile.existsSync()) {
      _log.devPrint('JWT keys not found. Generating...');
      // generate private key
      await Process.run('openssl', [
        'ecparam',
        '-genkey',
        '-name',
        'prime256v1',
        '-noout',
        '-out',
        'jwt_private.pem',
      ]);

      // generate public key
      await Process.run('openssl', [
        'ec',
        '-in',
        'jwt_private.pem',
        '-pubout',
        '-out',
        'jwt_public.pem',
      ]);

      _log.devPrint('JWT keys generated');
    }

    // =====================
    // LOAD INTO MEMORY
    // =====================
    pubkey = publicKeyFile.readAsStringSync();
    prvkey = privateKeyFile.readAsStringSync();

    _log.devPrint('JWT keys loaded into memory');
  }
}
