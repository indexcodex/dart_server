import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_handshake/interface/handshake_init.dart';

class HandshakeFacade {
  static void handlers(RouterPlus app) {
    handshakeInit(app);
  }
}
