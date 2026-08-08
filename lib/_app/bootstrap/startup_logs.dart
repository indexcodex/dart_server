import 'package:shelf_server/_core/core.dart';

final _log = Core.util.log;

/// outputs the logs on successful shelf run
void runShelfSuccessLog(Object object, int i) {
  _log.devPrintList([
    'Shelf Server Initialized',
    ' - env: ${Core.config.env}',
    ' - address: $object',
    ' - port: $i',
    'Rate limit request per second: ${Core.config.requestPerSecond}',
  ]);

  if (!Core.config.enableSecurity) {
    // if enableSecurity = false;
    _log.devPrintList([
      'Authentication disabled',
      'Encryption disabled',
      'Replay Guard disabled',
    ]);
  } else {
    // if enableSecurity = true;
    Core.config.appId.contains('YOUR_APP_ID')
        ? _log.devPrint('App ID not generated yet')
        : _log.devPrint('App ID ${Core.config.appId}');

    _log.devPrintList([
      'Authentication enabled',
      'Encryption enabled',
      'Replay Guard enabled',
      'Authentication bypass: ${Core.config.accessTokenEndpointPassthrough}',
      'Encryption bypass: ${Core.config.cryptoEndpointPassthrough}',
      'Replay Guard bypass: ${Core.config.replayGuardEndpointPassthrough}',
    ]);
  }

  if (!Core.config.requireSsl) {
    _log.devPrint('SSL disabled');
  } else {
    _log.devPrint('SSL enabled');
  }
}

/// outputs the logs on failed shelf run
void runShelfFailedLog(Object e) {
  _log.devPrintList(['shelfRun failed', 'shelfRun exception: $e']);
}
