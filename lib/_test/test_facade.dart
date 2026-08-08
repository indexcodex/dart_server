import 'package:shelf_plus/shelf_plus.dart';
import 'interface/test_get_data.dart';
import 'interface/test_get_dynamic_data.dart';
import 'interface/test_post_data.dart';

class TestFacade {
  static void handlers(RouterPlus app) {
    getDataTestHandler(app);
    postDataTestHandler(app);
    getDynamicDataTestHandler(app);
  }
}
