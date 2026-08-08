import 'package:shelf_plus/shelf_plus.dart';

import '_app/shelf_server.dart';

void main() async {
  await ShelfServer.bootstrap(
    redisAddress: ShelfServer.redisIpAddress,
    redisPort: ShelfServer.redisPort,
  );

  await shelfRun(
    ShelfServer.init,
    defaultBindPort: ShelfServer.port,
    defaultBindAddress: ShelfServer.ipAddress,
    securityContext: ShelfServer.sslConfig(),
    onStartFailed: ShelfServer.runShelfFailed,
    onStarted: ShelfServer.runShelfSuccess,
  );
}
