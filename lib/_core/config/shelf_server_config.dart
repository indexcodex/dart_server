import 'package:shelf_server/_core/enum/shelf_server_env.dart';
import 'package:shelf_server/_core/enum/shelf_server_type.dart';

/// MasterConfig defines how the server will run
class ShelfServerConfig {
  // ==================
  // Environment config
  // ==================
  //
  /// sets the server environment to determine where the data will be routed
  final ShelfServerEnv env = ShelfServerEnv.dev;
  //
  /// the server's currently running port
  int get port {
    switch (env) {
      case ShelfServerEnv.staging:
      case ShelfServerEnv.dev:
      case ShelfServerEnv.qa:
      case ShelfServerEnv.uat:
        return 1001;
      case ShelfServerEnv.prod:
        return 1001; // should point to prod port
    }
  }

  //
  /// returns the ip address based on the given env
  ///
  /// cfprod: cloudflare prod is just dev that is handled by cloudflare
  String get ipAddress {
    switch (env) {
      case ShelfServerEnv.staging:
      case ShelfServerEnv.dev:
      case ShelfServerEnv.qa:
      case ShelfServerEnv.uat:
        return '0.0.0.0';
      case ShelfServerEnv.prod:
        return '192.168.254.100'; // should point to server IP
    }
  }

  // =====================
  // Security config
  // =====================
  /// Enables the full request security pipeline.
  ///
  /// When enabled, all incoming requests must pass through:
  ///
  /// 1. Authentication
  ///    - Requires a valid App ID token for all endpoints.
  ///    - Requires a valid access token for all protected endpoints.
  ///
  /// 2. Payload cryptography (ECC-based)
  ///    - Requests must be encrypted using device-specific key pairs.
  ///    - Responses are encrypted before being returned to the client.
  ///    - Ensures confidentiality of request/response data.
  ///
  /// 3. Replay attack protection
  ///    - Each request must include a unique nonce and timestamp (x-guard).
  ///    - Prevents duplicate or delayed request reuse within a time window.
  ///
  /// Notes:
  /// - These mechanisms are tightly coupled and designed to work together.
  /// - Disabling this flag bypasses all security layers (plaintext mode).
  /// - Certain endpoints may explicitly bypass parts of the pipeline.
  ///
  /// Default: false (intended for development or trusted environments only)
  final bool enableSecurity = false;

  // =====================
  // Server Type
  // =====================
  //
  /// microservice: utilizes redis to handle middleware data
  /// monolith: utilizes instance memory to handle middleware data
  final ShelfServerType serverType = ShelfServerType.monolith;

  // =====================
  // Memcache config
  // =====================
  /// the number of allowed records in a cache\
  /// if this limit is reached, a cleanup needs to run
  final int memcacheRecordLimit = 400;

  // ==================
  // Redis config
  // ==================
  //
  // the port where redis is running
  final int redisPort = 6379;
  //
  /// returns the redis ip address based on the given env
  ///
  /// most of the time, uses the same ip address as shelf server,\
  /// the only time it will differ is if redis is in a different machine
  String get redisIpAddress {
    switch (env) {
      case ShelfServerEnv.staging:
      case ShelfServerEnv.dev:
      case ShelfServerEnv.qa:
      case ShelfServerEnv.uat:
        return '0.0.0.0';
      case ShelfServerEnv.prod:
        return '192.168.254.100'; // should point to server IP
    }
  }

  // =====================
  // Authentication config
  //
  // requires enableSecurity=true to take effect
  // =====================
  //
  /// allows clients with the correct client id to connect
  /// - get your app id here: https://randomkeygen.com/
  /// - or you can create your own app id, example: abc123
  ///
  /// List of allowed App IDs that are permitted to connect to this server.
  final Set<String> appId = {'YOUR_APP_ID'};
  //
  /// token scope for users who are not logged in yet\
  /// these prevents API access from unauthenticated users
  final List<String> guestTokenScope = [
    '/get-data',
    '/get-dynamic-data',
    '/post-data',
  ];
  //
  /// token scope for admin
  /// prevents API access from unauthenticated users
  final List<String> adminTokenScope = [];
  //
  /// endpoints that will bypass access token check.
  ///
  /// /handshake/init bypass accesstoken because
  /// this is the first endpoint that will be called,
  /// and there's no access token yet in the request header
  final List<String> accessTokenEndpointPassthrough = ['/handshake/init'];

  // =====================
  // Rate Limit config
  //
  // Always ON
  // =====================
  /// imposes a defined numbers of requests per second
  /// to protect the server from DOS attacks and memory pressure
  ///
  /// for a lenient rate limit: increase requestPerSecond
  /// for strict rate limit: decrease requestPerSecond
  final int requestPerSecond = 5;
  //
  /// the time window in 'millisecond' where the request is considered valid\
  /// this means that any request within this window is accepted
  ///
  /// default value is 1 second
  final int rateLimitValidityWindowMs = 1000; // 1000 millisecond window

  // =====================
  // Upload config
  // =====================
  //
  /// Maximum size allowed for an individual uploaded file.
  /// Helps prevent excessive use of server storage.
  final int uploadMaxFileSize = 1024 * 1024; // 1 MB
  //
  /// Maximum total size allowed for a single upload request.
  /// Helps prevent abuse through multiple small file uploads.
  final int uploadMaxRequestSize = 5 * 1024 * 1024; // 5 MB
  //
  /// Maximum field size allowed for a single upload request.
  /// Helps prevent abuse through large form fields.
  final int uploadMaxFieldSize = 64 * 1024; // 64 KB

  // ===================
  // Cryptography config
  //
  // requires enableSecurity=true to take effect
  // ===================
  //
  // validate payload size to prevent memory pressure attacks
  final int maxPayloadSize = 1024 * 1024; // 1MB or 1 million characters
  //
  /// endpoints that will ignore encryption/decryption if enableSecurity is true
  ///
  /// /handshake/init bypass encryption/decryption because
  /// this is the first endpoint that will be called,
  /// and there's no encryption keys yet
  final List<String> cryptoEndpointPassthrough = ['/handshake/init'];

  // =====================
  // Replay guard config
  //
  // requires enableSecurity=true to take effect
  // =====================
  //
  /// endpoints that will ignore replay guard if requireReplayGuard is true
  ///
  /// /handshake/init bypass replay guard because
  /// this is the first endpoint that will be called,
  /// and there's no encryption keys yet
  final List<String> replayGuardEndpointPassthrough = ['/handshake/init'];
  //
  /// the time window where the request is still valid\
  /// this means that any request within this window is accepted
  final int replayGuardValidityWindow = 5 * 60 * 1000; // 5 minutes window

  // ==============================
  // Database config
  //
  // port and host are fixed values
  // you can change it as long as you know what you are doing
  // ==============================
  /// database connection port
  final int databasePort = 3306;
  //
  /// database connection ip
  final String databaseHost = '127.0.0.1';
  //
  /// the database to connect to
  final String databaseName = 'shelfserver';
  //
  /// database user credentials
  final String databaseUser = 'shelfserver';
  //
  /// database user credentials
  final String databasePassword = 'shelfserver';

  // ==============================
  // SMTP config
  //
  // SMTP stands for Simple Mail Transfer Protocol
  // this enables the server to send email to users
  // ==============================
  /// smtp client
  final String smtpHost = '';
  //
  /// smtp user credentials
  final String smtpUsername = '';
  //
  /// smtp user credentials
  final String smtpPassword = '';

  // =====================
  // SSL config
  // =====================
  /// enables SSL in the server
  ///
  /// this config requires that you know the following:
  /// - ssl intallation and configuration
  /// - cron job with ssl renewal
  ///
  /// requireSsl is false by default
  final bool requireSsl = false;
}
