import 'package:shelf_plus/shelf_plus.dart';

import 'interface/upload_many_all_or_nothing.dart';
import 'interface/upload_one.dart';

class UploadFacade {
  static void handlers(RouterPlus app) {
    uploadManyAON(app);
    uploadOne(app);
  }
}
