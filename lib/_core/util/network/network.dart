import 'dart:io';

import 'package:shelf_plus/shelf_plus.dart';

class NetworkUtil {
  String? getIpAddress(Request request) {
    // Cloudflare
    final cfIp = request.headers['cf-connecting-ip'];
    if (cfIp != null) return cfIp;

    // Standard proxy header
    final forwarded = request.headers['x-forwarded-for'];
    if (forwarded != null) {
      return forwarded.split(',').first.trim();
    }

    // Fallback
    final connectionInfo =
        request.context['shelf.io.connection_info'] as HttpConnectionInfo?;

    return connectionInfo?.remoteAddress.address;
  }
}
