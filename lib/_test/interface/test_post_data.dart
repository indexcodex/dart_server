import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_test/model/request_model/test_post_data_request.dart';
import 'package:shelf_server/_test/converter/test_post_data.dart';

/// GET request debugger
void postDataTestHandler(RouterPlus app) {
  app.post('/post-data', (Request req) async {
    try {
      final Map<String, dynamic> mapData = await req.body.asJson;
      final int otp = mapData['otp'];
      final String userName = mapData['userName'];

      // prepare the request body
      PostDataRequest jsonRequest = PostDataRequest(
        otp: otp,
        userName: userName,
      );

      // send the api request and wait for the response
      var jsonResponse = await postDataModule(jsonRequest);

      return Response(
        200,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jsonResponse.toJson()),
      );
    } catch (e) {
      return Response(
        401,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': 'Unauthorized',
          'detail': 'Authentication is required or invalid.',
        }),
      );
    }
  });
}

// =======================
// SAMPLE REQUEST
// =======================
//
// POST
//
// http://0.0.0.0:1001/post-data
//
// {
//   "otp": 123123,
//   "userName": "JohnDoe"
// }
