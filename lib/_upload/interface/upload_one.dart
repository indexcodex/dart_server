import 'package:shelf_plus/shelf_plus.dart';

import '../../_core/engine/upload_engine/module/upload_handler.dart';

void uploadOne(RouterPlus app) {
  app.post('/upload-one', (Request request) async {
    return await uploadHandler(request: request, uploadMaxFileCount: 1);
  });
}
