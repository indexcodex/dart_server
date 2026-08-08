import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';

void handlername(RouterPlus app) {
  app.post('/handlerendpoint', (Request req) async {
    try {
      final Map<String, dynamic> requestJson = await req.body.asJson;
      String firstName = requestJson['firstName'];
      String middleName = requestJson['middleName'];
      String lastName = requestJson['lastName'];

      return Response(
        200,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': 'Hello $firstName',
          'detail':
              'It says here that your middle name is $middleName and your last name is $lastName. Is this correct?',
        }),
      );
    } catch (e) {
      return Response(
        500,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': 'Request Error',
          'detail': 'Data processing failed',
        }),
      );
    }
  });
}
