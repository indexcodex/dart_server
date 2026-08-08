// ignore_for_file: cascade_invocations

import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_app/middleware/auth_middleware.dart';
import 'package:shelf_server/_app/middleware/cors_header_middleware.dart';
import 'package:shelf_server/_app/middleware/crypto_middleware.dart';
import 'package:shelf_server/_app/middleware/rate_limit_middleware.dart';
import 'package:shelf_server/_app/middleware/replay_guard_middleware.dart';
import 'package:shelf_server/_test/test_facade.dart';
import 'package:shelf_server/_handshake/handshake_facade.dart';
import 'package:shelf_server/_upload/upload_facade.dart';

/// run the server
Handler serverHandlers() {
  var app = Router().plus;

  // -------------------------------------
  // middleware
  // -------------------------------------
  app.use(corsHeaderMiddleware());
  app.use(rateLimitMiddleware());
  app.use(authMiddleware());
  app.use(cryptoMiddleware());
  app.use(replayGuardMiddleware());

  // -------------------------------------
  // Serve files from "public/asset" when URL starts with "/public/"
  // e.g. "/public/dart.png" will pull from "public/asset/dart.png"
  //
  // http://0.0.0.0:1001/public/dart.png
  // -------------------------------------
  final staticHandler = createStaticHandler('public/asset');
  app.mount('/public/', staticHandler);

  // -------------------------------------
  // system handlers
  // handlers that are part of shelfserver
  // -------------------------------------
  UploadFacade.handlers(app);
  HandshakeFacade.handlers(app);

  // -------------------------------------
  // project handlers
  // handlers that is custom to this proj
  // -------------------------------------

  // -------------------------------------
  // test handlers
  // do not add anything beyond this point
  // -------------------------------------
  TestFacade.handlers(app);

  // -------------------------------------
  // invalid url handler
  // do not add anything beyond this point
  // -------------------------------------
  app.all('/<ignored|.*>', (Request request) async {
    return Response(
      404,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Not Found',
        'detail': 'The requested resource does not exist.',
      }),
    );
  });

  return app.call;
}
