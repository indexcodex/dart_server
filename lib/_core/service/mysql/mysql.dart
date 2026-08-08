// ignore_for_file: avoid_redundant_argument_values

import 'package:mysql1/mysql1.dart';
import 'package:shelf_server/_core/core.dart';

// ===========================================
// CONFIG YOUR DB HERE
// ===========================================
final _connectionSettings = ConnectionSettings(
  port: Core.config.databasePort,
  host: Core.config.databaseHost,
  db: Core.config.databaseName,
  user: Core.config.databaseUser,
  password: Core.config.databasePassword,
);

// ===========================================

class MySqlService {
  /// generic query method
  Future<Results> query(String query, [List<Object?>? values]) async {
    // establish db connection
    final conn = await MySqlConnection.connect(_connectionSettings);

    // this is the most important bit of code to make querying work
    // it seems like a bug with the completer during the connect to the db.
    // The override is to wait a while for the connection.
    await Future.delayed(const Duration(microseconds: 1));

    try {
      // query
      return await conn.query(query, values);
    } finally {
      // close db connection regardless if the query succeed or failed
      await conn.close();
    }
  }

  /// roll back data on query fail
  Future<void> transaction(
    Future Function(TransactionContext transaction) queryBlock,
  ) async {
    // establish db connection
    final conn = await MySqlConnection.connect(_connectionSettings);

    // this is the most important bit of code to make querying work
    // it seems like a bug with the completer during the connect to the db.
    // The override is to wait a while for the connection.
    await Future.delayed(const Duration(microseconds: 1));

    try {
      // query
      return await conn.transaction(queryBlock);
    } finally {
      // close db connection regardless if the query succeed or failed
      await conn.close();
    }
  }

  /// check if a value has duplicate
  Future<bool> isDuplicate({
    required String tableName,
    required String columnName,
    required dynamic value,
  }) async {
    // the query to run
    // always use parameterized value to avoid sql injection
    String query = 'SELECT * FROM $tableName WHERE $columnName=?;';

    // establish db connection
    final conn = await MySqlConnection.connect(_connectionSettings);

    // this is the most important bit of code to make querying work
    // it seems like a bug with the completer during the connect to the db.
    // The override is to wait a while for the connection.
    await Future.delayed(const Duration(microseconds: 1));

    // query
    var result = await conn.query(query, [value]);

    // close db connection
    await conn.close();

    if (result.firstOrNull == null) {
      return false;
    } else {
      return true;
    }
  }

  /// check if a value exists
  ///
  /// basically just a clone of isDuplicate
  /// just with different function name
  Future<bool> exists({
    required String tableName,
    required String columnName,
    required dynamic value,
  }) async {
    // the query to run
    // always use parameterized value to avoid sql injection
    String query = 'SELECT * FROM $tableName WHERE $columnName=?;';

    // establish db connection
    final conn = await MySqlConnection.connect(_connectionSettings);

    // this is the most important bit of code to make querying work
    // it seems like a bug with the completer during the connect to the db.
    // The override is to wait a while for the connection.
    await Future.delayed(const Duration(microseconds: 1));

    // query
    var result = await conn.query(query, [value]);

    // close db connection
    await conn.close();

    if (result.firstOrNull == null) {
      return false;
    } else {
      return true;
    }
  }

  /// returns the record as a list of map
  ///
  /// Convert result to a list using `List.generate`
  List<Map<String, dynamic>> getRecords(Results queryResult) {
    return List.generate(queryResult.length, (int i) {
      // Get row as a map
      return queryResult.elementAt(i).fields;
    });
  }

  /// returns a single result from the query
  Map<String, dynamic>? getSingleRecord(Results queryResult) {
    return queryResult.firstOrNull?.fields;
  }
}
