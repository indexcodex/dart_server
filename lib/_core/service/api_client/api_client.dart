// ignore_for_file: cascade_invocations

import 'dart:async';
import 'package:http/http.dart' as http;

class ApiClient {
  final HttpMethod get = HttpMethod.get;
  final HttpMethod post = HttpMethod.post;
  final HttpMethod put = HttpMethod.put;
  final HttpMethod patch = HttpMethod.patch;
  final HttpMethod delete = HttpMethod.delete;

  /// Helper function to handle timeout and request execution
  Future<http.Response> _sendRequestWithTimeout(
    Future<http.Response> Function() requestFunction, {
    required Duration timeoutDuration,
  }) async {
    try {
      return await requestFunction().timeout(
        timeoutDuration,
        onTimeout: () {
          // Throw a timeout exception to be caught by the main catch block
          throw TimeoutException('The connection has timed out.');
        },
      );
    } catch (_) {
      // Rethrow the exception to the main catch block for further handling
      rethrow;
    }
  }

  Future<void> sendRequest({
    required String url,
    HttpMethod method = HttpMethod.get,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    Object? body,
    Duration timeoutDuration = const Duration(seconds: 60),
    Function(String responseJson)? onRequestSuccess,
    Function(String responseJson)? onRequestFail,
    Function(Object exception)? onException,
    Function(Object exception)? onTimeout, // Timeout callback
  }) async {
    try {
      // Validate timeout duration
      if (timeoutDuration <= Duration.zero) {
        throw ArgumentError('Timeout duration must be greater than zero.');
      }

      // Build the URI from the provided URL
      final Uri uri = Uri.parse(url).replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      // Set the default Content-Type header
      Map<String, String> requestHeaders = {'Content-Type': 'application/json'};

      // Attach additional headers if provided
      requestHeaders.addAll(headers);

      http.Response httpResponse;

      // Choose the appropriate request based on the method
      switch (method) {
        case HttpMethod.get:
          httpResponse = await _sendRequestWithTimeout(
            () => http.get(uri, headers: requestHeaders),
            timeoutDuration: timeoutDuration,
          );
          break;

        case HttpMethod.post:
          httpResponse = await _sendRequestWithTimeout(
            () => http.post(uri, headers: requestHeaders, body: body),
            timeoutDuration: timeoutDuration,
          );
          break;

        case HttpMethod.put:
          httpResponse = await _sendRequestWithTimeout(
            () => http.put(uri, headers: requestHeaders, body: body),
            timeoutDuration: timeoutDuration,
          );
          break;

        case HttpMethod.patch:
          httpResponse = await _sendRequestWithTimeout(
            () => http.patch(uri, headers: requestHeaders, body: body),
            timeoutDuration: timeoutDuration,
          );
          break;

        case HttpMethod.delete:
          httpResponse = await _sendRequestWithTimeout(
            () => http.delete(uri, headers: requestHeaders, body: body),
            timeoutDuration: timeoutDuration,
          );
          break;
      }

      // Handle the HTTP response based on status code
      // 200 OK
      // 201 Created
      // 202 Accepted
      // 204 No Content
      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        // Call success callback if provided
        onRequestSuccess?.call(httpResponse.body);
      } else if (httpResponse.statusCode >= 400) {
        // Call fail callback if provided
        onRequestFail?.call(httpResponse.body);
      }
    } catch (e) {
      // Handle specific exceptions for more clarity
      if (e is TimeoutException) {
        // If a timeout occurred, use the timeout callback
        onTimeout?.call(e);
      } else {
        // Handle any other types of exceptions
        onException?.call(e);
      }
    }
  }

  Future<void> upload({
    required String url,
    required List<http.MultipartFile> files,
    Map<String, String> headers = const {},
    Map<String, String> queryParameters = const {},
    Map<String, String> fields = const {},
    Duration timeoutDuration = const Duration(seconds: 60),
    Function(String responseJson)? onRequestSuccess,
    Function(String responseJson)? onRequestFail,
    Function(Object exception)? onException,
    Function(Object exception)? onTimeout,
  }) async {
    try {
      // Ensure a valid timeout has been configured.
      if (timeoutDuration <= Duration.zero) {
        throw ArgumentError('Timeout duration must be greater than zero.');
      }

      // Build the request URI and append any query parameters.
      final uri = Uri.parse(url).replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      // Multipart uploads are always sent using HTTP POST.
      final request = http.MultipartRequest('POST', uri);

      // Attach any additional request headers.
      request.headers.addAll(headers);

      // Attach regular form fields.
      request.fields.addAll(fields);

      // Attach all files to the multipart request.
      // MultipartFile streams the file contents, avoiding loading
      // the entire file into memory.
      request.files.addAll(files);

      // Send the multipart request with a timeout.
      final streamedResponse = await request.send().timeout(
        timeoutDuration,
        onTimeout: () {
          throw TimeoutException('The connection has timed out.');
        },
      );

      // Convert the streamed response into a regular HTTP response.
      final response = await http.Response.fromStream(streamedResponse);

      // Invoke the appropriate callback based on the HTTP status code.
      if (response.statusCode >= 200 && response.statusCode < 300) {
        onRequestSuccess?.call(response.body);
      } else if (response.statusCode >= 400) {
        onRequestFail?.call(response.body);
      }
    } catch (e) {
      // Distinguish timeout failures from all other exceptions.
      if (e is TimeoutException) {
        onTimeout?.call(e);
      } else {
        onException?.call(e);
      }
    }
  }
}

enum HttpMethod { get, post, put, patch, delete }
