import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';

void handlername(RouterPlus app) {
  app.get('/handlerendpoint', (Request req) async {
    try {
      // Get all query params
      final query = req.requestedUri.queryParameters;

      // Access specific params
      final String? firstName = query['firstName'];
      final String? middleName = query['middleName'];
      final String? lastName = query['lastName'];

      // if there's a missing data
      // return generic response
      if (firstName == null ||
          firstName.isEmpty ||
          middleName == null ||
          middleName.isEmpty ||
          lastName == null ||
          lastName.isEmpty) {
        return Response(
          200,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Hello World',
            'detail': 'My first GET endpoint response',
          }),
        );
      }

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
