import 'dart:convert';
import 'package:shelf_plus/shelf_plus.dart';

class _HttpResponse {
  const _HttpResponse({required this.title, required this.detail});

  final String title;
  final String detail;
}

/// Reusable fallback
const _fallbackResponse = _HttpResponse(
  title: 'Unknown Error',
  detail: 'An unknown error occurred.',
);

const Map<int, _HttpResponse> _httpResponseData = {
  200: _HttpResponse(title: 'OK', detail: 'The request was successful.'),
  201: _HttpResponse(
    title: 'Created',
    detail: 'The resource was successfully created.',
  ),
  202: _HttpResponse(
    title: 'Accepted',
    detail: 'The request has been accepted for processing.',
  ),
  204: _HttpResponse(
    title: 'No Content',
    detail: 'The request was successful, but there is no content to return.',
  ),
  400: _HttpResponse(
    title: 'Bad Request',
    detail: 'The request is invalid or cannot be processed.',
  ),
  401: _HttpResponse(
    title: 'Unauthorized',
    detail: 'Authentication is required or invalid.',
  ),
  403: _HttpResponse(
    title: 'Forbidden',
    detail: 'You do not have permission to access this resource.',
  ),
  404: _HttpResponse(
    title: 'Not Found',
    detail: 'The requested resource does not exist.',
  ),
  405: _HttpResponse(
    title: 'Method Not Allowed',
    detail: 'This HTTP method is not supported for this resource.',
  ),
  408: _HttpResponse(
    title: 'Request Timeout',
    detail: 'The request took too long to process.',
  ),
  409: _HttpResponse(
    title: 'Conflict',
    detail: 'The request conflicts with the current state of the resource.',
  ),
  413: _HttpResponse(
    title: 'Payload Too Large',
    detail: 'The request body is too large to process.',
  ),
  415: _HttpResponse(
    title: 'Unsupported Media Type',
    detail: 'The uploaded file type is not supported.',
  ),
  422: _HttpResponse(
    title: 'Unprocessable Entity',
    detail: 'The request is well-formed but contains invalid data.',
  ),
  429: _HttpResponse(
    title: 'Too Many Requests',
    detail: 'You have exceeded the allowed number of requests.',
  ),
  500: _HttpResponse(
    title: 'Internal Server Error',
    detail: 'An unexpected error occurred on the server.',
  ),
  502: _HttpResponse(
    title: 'Bad Gateway',
    detail: 'The server received an invalid response from an upstream server.',
  ),
  503: _HttpResponse(
    title: 'Service Unavailable',
    detail: 'The server is temporarily unable to handle the request.',
  ),
  504: _HttpResponse(
    title: 'Gateway Timeout',
    detail: 'The upstream server failed to respond in time.',
  ),
};

const _responseHeader = {'Content-Type': 'application/json; charset=utf-8'};

class ShelfHttpResponse {
  /// Error response
  Response error(int statusCode, {required String errorCode}) {
    final responseData = _httpResponseData[statusCode] ?? _fallbackResponse;

    return Response(
      statusCode,
      headers: _responseHeader,
      body: jsonEncode({
        'errorCode': errorCode,
        'title': responseData.title,
        'detail': responseData.detail,
      }),
    );
  }

  /// Success response
  Response success([Map<String, dynamic>? body]) {
    return Response(
      body == null ? 204 : 200,
      headers: _responseHeader,
      body: body == null ? null : jsonEncode(body),
    );
  }
}
