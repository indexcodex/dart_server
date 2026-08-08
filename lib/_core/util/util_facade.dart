import 'package:shelf_server/_core/util/logger/logger.dart';
import 'package:shelf_server/_core/util/mime/mime_detector.dart';
import 'package:shelf_server/_core/util/network/network.dart';
import 'package:shelf_server/_core/util/request/request_util.dart';
import 'package:shelf_server/_core/util/response/response.dart';
import 'package:shelf_server/_core/util/unix/unix.dart';
import 'package:shelf_server/_core/util/uuid/uuid_facade.dart';

import 'file/file_util_facade.dart';

class UtilFacade {
  UnixManager unix = UnixManager();
  ShelfLogger log = ShelfLogger();
  NetworkUtil network = NetworkUtil();
  ShelfHttpRequest request = ShelfHttpRequest();
  ShelfHttpResponse response = ShelfHttpResponse();
  UuidFacade uuid = UuidFacade();
  MimeDetector mime = MimeDetector();
  FileUtilFacade file = FileUtilFacade();
}
