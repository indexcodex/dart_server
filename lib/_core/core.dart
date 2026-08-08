import 'config/shelf_server_config.dart';
import 'engine/engine_facade.dart';
import 'service/service_facade.dart';
import 'util/util_facade.dart';

class Core {
  /// sets the server environment to determine where the data will be routed
  static ShelfServerConfig config = ShelfServerConfig();
  static ServiceFacade service = ServiceFacade();
  static UtilFacade util = UtilFacade();
  static EngineFacade engine = EngineFacade();
}
