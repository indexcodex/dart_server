import 'dart:io';

import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_app/bootstrap/startup_logs.dart';
import 'package:shelf_server/_app/interface/server_handlers.dart';
import 'package:shelf_server/_core/core.dart';
import 'package:shelf_server/_app/bootstrap/ssl_config_data.dart';

class ShelfServer {
  /// the server's currently running port
  static int port = Core.config.port;

  /// redis currently running port
  static int redisPort = Core.config.redisPort;

  /// returns the ip address based on the given env
  static String ipAddress = Core.config.ipAddress;

  /// returns the redis ip address based on the given env
  static String redisIpAddress = Core.config.redisIpAddress;

  /// outputs the logs on successful shelf run
  static void runShelfSuccess(Object object, int i) {
    runShelfSuccessLog(object, i);
  }

  /// outputs the logs on failed shelf run
  static void runShelfFailed(Object e) {
    runShelfFailedLog(e);
  }

  /// the server's SSL configuration
  static SecurityContext? sslConfig() {
    return sslConfigData();
  }

  /// run the server
  static Handler init() {
    return serverHandlers();
  }

  /// prepares the what the server needs before running
  static Future<void> bootstrap({String? redisAddress, int? redisPort}) async {
    await Core.service.redis.init(
      redisAddress: redisAddress,
      redisPort: redisPort,
    );
    await Core.service.memcache.jwt.preloadJwtKeys();
  }
}
