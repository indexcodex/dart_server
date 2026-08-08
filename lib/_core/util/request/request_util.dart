import 'package:shelf_plus/shelf_plus.dart';

class ShelfHttpRequest {
  /// returns true if the request is multipart/form-data\
  /// returns false if content-type is null or other content type
  bool isMultipartFormdata(Request request) {
    return request.headers['content-type']?.toLowerCase().startsWith(
          'multipart/form-data',
        ) ??
        false;
  }

  /// returns true if the request is text/plain\
  /// returns false if content-type is null or other content type
  bool isTextPlain(Request request) {
    return request.headers['content-type']?.toLowerCase().startsWith(
          'text/plain',
        ) ??
        false;
  }

  /// returns true if the request is application/json\
  /// returns false if content-type is null or other content type
  bool isApplicationJson(Request request) {
    return request.headers['content-type']?.toLowerCase().startsWith(
          'application/json',
        ) ??
        false;
  }
}
