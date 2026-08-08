import 'package:shelf_plus/shelf_plus.dart';

Middleware baseMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // =====================
      // BEFORE HANDLER (request phase)
      // =====================

      // e.g. inspect headers, validate auth, etc.

      final response = await innerHandler(request);

      // =====================
      // AFTER HANDLER (response phase)
      // =====================

      // e.g. modify response, add headers, logging, etc.

      return response;
    };
  };
}
