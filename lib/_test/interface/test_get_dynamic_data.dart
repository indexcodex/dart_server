import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';

/// GET request debugger
void getDynamicDataTestHandler(RouterPlus app) {
  // /<fname>/<mname>/<lname> are called fragments
  app.get('/get-dynamic-data/<fname>/<mname>/<lname>', (
    Request req,
    String fName,
    String mName,
    String lName,
  ) {
    Map<String, dynamic> jsonResponse = {
      'isSuccess': true,
      'fName': fName,
      'mName': mName,
      'lName': lName,
    };

    return Response(
      200,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(jsonResponse),
    );
  });
}

// =======================
// SAMPLE REQUEST
// =======================
//
// GET
//
// http://0.0.0.0:1001/get-dynamic-data/john/doe/alpaca
