// ignore_for_file: avoid_redundant_argument_values

import 'package:shelf_server/_core/core.dart';

Future<String> getData() async {
  /// the api to connect to
  const String requestUrl = 'https://indexcodex.com/api/v1/remote_data';

  /// the request method to use [GET, POST]
  final requestMethod = Core.service.api.get;

  /// the header to send to the API
  const Map<String, String> requestHeader = {'CLIENT_ID': 'rgbexam'};

  /// prepare the data to return
  String responseJson = '';

  try {
    await Core.service.api.sendRequest(
      url: requestUrl,
      method: requestMethod,
      headers: requestHeader,
      onRequestSuccess: (jsonBody) {
        // return response as json string
        responseJson = jsonBody;
      },
      onRequestFail: (jsonBody) {
        // throw error response as json string
        throw jsonBody;
      },
      onException: (exception) {
        // throw exception response as string
        throw exception;
      },
      onTimeout: (exception) {
        // throw exception response as string
        throw exception;
      },
    );
  } catch (e) {
    // rethrow any exceptions received
    rethrow;
  }

  // return response json
  return responseJson;
}
