import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';

import '../converter/test_get_data.dart';

/// GET request debugger
void getDataTestHandler(RouterPlus app) {
  app.get('/get-data', (Request req) async {
    var data = await getDataModule();

    return Response(
      200,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data.toJson()),
    );
  });
}

// =======================
// SAMPLE REQUEST
// =======================
//
// GET
//
// http://0.0.0.0:1001/get-data
