// ignore_for_file: avoid_print

import 'package:shelf_server/_core/enum/shelf_server_env.dart';
import 'package:shelf_server/_core/core.dart';

class ShelfLogger {
  // returns true if env is not prod
  bool get _allowPrint => Core.config.env != ShelfServerEnv.prod;

  void devPrint(String value) {
    // print value if env is not prod
    if (_allowPrint) {
      print(value);
    }
  }

  void devPrintList(List<String> values) {
    // print value if env is not prod
    if (_allowPrint) {
      for (final value in values) {
        print(value);
      }
    }
  }
}
