import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_plus/shelf_plus.dart';

/// handles header related functions,
/// and allows client to connect to server
Middleware corsHeaderMiddleware() {
  // only allow these header keys
  final List<String> accessControl = [
    'Origin',
    'Content-Type',
    'Accept',
    'Authorization',
  ];

  final String allowedHeaders = accessControl.join(', ');

  final Map<String, String> headerConfig = {
    ACCESS_CONTROL_ALLOW_HEADERS: allowedHeaders,
  };

  // corsHeaders is from shelf_cors_headers package
  return corsHeaders(headers: headerConfig);
}
