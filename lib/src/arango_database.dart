import 'dart:convert';

import 'package:arango/src/arango_cursor.dart';
import 'package:arango/src/arango_query.dart';
import 'package:arango/src/arango_transaction.dart';
import 'package:arango/src/collection/arango_collection.dart';
import 'package:arango/src/arango_config.dart';
import 'package:arango/src/arango_connection.dart';
import 'package:arango/src/arango_errors.dart';
import 'package:arango/src/arango_helper.dart';
import 'package:arango/src/collection/arango_document_collection.dart';
import 'package:arango/src/collection/arango_edge_collection.dart';
import 'package:arango/src/collection/collection_status.dart';
import 'package:arango/src/collection/collection_type.dart';

ArangoCollection _constructCollection(
  ArangoConnection connection,
  Map<String, dynamic> data,
) {
  final id = data['id'];
  final name = data['name'];
  final status = data['status'];
  final type = data['type'];
  final isSystem = data['isSystem'];
  final globallyUniqueId = data['globallyUniqueId'];

  final collectionStatus = parseCollectionStatus(status);
  final collectionType = parseCollectionType(type);

  switch (collectionType) {
    case CollectionType.document:
      return ArangoDocumentCollection(
        name: name,
        connection: connection,
        id: id,
        status: collectionStatus,
        isSystem: isSystem,
        globallyUniqueId: globallyUniqueId,
      );
    case CollectionType.edge:
      return ArangoEdgeCollection(
        name: name,
        connection: connection,
        id: id,
        status: collectionStatus,
        isSystem: isSystem,
        globallyUniqueId: globallyUniqueId,
      );
    default:
      throw UnsupportedError('Unsupported collection type: $type');
  }
}

class CreateDatabaseUser {
  CreateDatabaseUser(
    this.username, {
    this.passwd,
    this.active,
    this.extra,
  });

  final String username;
  final String passwd;
  final bool active;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() => {
        'username': username,
        'passwd': passwd,
        'active': active,
        'extra': extra,
      };
}

class ArangoDatabase {
  ArangoConnection _connection;

  ArangoDatabase(String url) {
    final config = ArangoConfig(url: url);
    _connection = ArangoConnection(config);
  }

  //#region misc
  Future<Map<String, dynamic>> version() async {
    final resp = await _connection.request(
      method: 'GET',
      path: '/_api/version',
    );
    return resp.body;
  }

  //#endregion

  //#region auth
  Future login([String username = 'root', String password = '']) async {
    final resp = await _connection.request(
      method: 'POST',
      path: '/_open/auth',
      body: {'username': username, 'password': password},
    );
    useBearerAuth(resp.body['jwt']);
    return resp.body;
  }

  ArangoDatabase useBasicAuth(String username, String password) {
    final bytes = utf8.encode('${username}:${password}');
    final basic = base64.encode(bytes);
    _connection.setHeader('authorization', 'Basic $basic');
    return this;
  }

  ArangoDatabase useBearerAuth(String token) {
    _connection.setHeader('authorization', 'Bearer $token');
    return this;
  }

  //#endregion

  //#region databases
  ArangoDatabase useDatabase(String name) {
    _connection.setDatabaseName(name);
    return this;
  }

  Future<Map<String, dynamic>> current() async {
    final resp = await _connection.request(
      path: '/_api/database/current',
    );
    return asJson(resp.body['result']);
  }

  Future<bool> exists() async {
    try {
      await current();
      return true;
    } on ArangoError catch (e) {
      const databaseNotFound = 1228;
      if (e.errorNum == databaseNotFound) {
        return false;
      } else {
        rethrow;
      }
    }
  }

  Future<void> createDatabase(
    String databaseName, [
    List<CreateDatabaseUser> users,
  ]) {
    final userList = users?.map((u) => u.toJson())?.toList();
    return _connection.request(
      method: 'POST',
      path: '/_api/database',
      body: {'name': databaseName, 'users': userList},
    );
  }

  Future<List<String>> listDatabases() async {
    final resp = await _connection.request(
      path: '/_api/database',
    );
    return List<String>.from(resp.body['result']);
  }

  Future<List<String>> listUserDatabases() async {
    final resp = await _connection.request(
      path: '/_api/database/user',
    );
    return List<String>.from(resp.body['result']);
  }

  Future<void> dropDatabase(String databaseName) {
    return _connection.request(
      method: 'DELETE',
      path: '/_api/database/$databaseName',
    );
  }

  //#endregion

  //#region collections
  ArangoDocumentCollection collection(String collectionName) {
    return ArangoDocumentCollection(
      name: collectionName,
      connection: _connection,
    );
  }

  ArangoEdgeCollection edgeCollection(String collectionName) {
    return ArangoEdgeCollection(
      name: collectionName,
      connection: _connection,
    );
  }

  Future<List<Map<String, dynamic>>> listCollections({
    bool excludeSystem = true,
  }) async {
    final resp = await _connection.request(
        path: '/_api/collection',
        queries: {'excludeSystem': excludeSystem.toString()});

    final data = _connection.arangoMajor <= 2
        ? resp.body['collections']
        : resp.body['result'];

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<ArangoCollection>> collections({
    bool excludeSystem = true,
  }) async {
    final collections = await listCollections(excludeSystem: excludeSystem);
    return collections
        .map((data) => _constructCollection(_connection, data))
        .toList();
  }

  Future<void> truncate({bool excludeSystem = true}) async {
    final collections = await listCollections(excludeSystem: excludeSystem);
    final futures = collections.map((coll) {
      return _connection.request(
        method: 'PUT',
        path: '/_api/collection/${coll['name']}/truncate',
      );
    });
    return Future.wait(futures);
  }

  //#endregion

  ArangoQuery query() {
    return ArangoQuery(this);
  }

  Future<ArangoCursor> rawQuery(
    String aql, {
    Map<String, dynamic> bindVars,
    bool allowDirtyRead,
    Duration timeout,
    bool returnCount = false,
    int batchSize,
    int ttl,
    bool cache,
    int memoryLimit,
    Map<String, dynamic> options,
  }) async {
    final resp = await _connection.request(
      method: 'POST',
      path: '/_api/cursor',
      allowDirtyRead: allowDirtyRead,
      timeout: timeout,
      body: {
        'query': aql,
        if (bindVars != null) 'bindVars': bindVars,
        'count': returnCount,
        'batchSize': batchSize,
        'ttl': ttl,
        'cache': cache,
        'memoryLimit': memoryLimit,
        'options': options,
      },
    );

    return ArangoCursor(
      _connection,
      resp.arangoDartHostId,
      allowDirtyRead,
      resp.body,
    );
  }

  //#endregion

  //#region transaction

  Future<dynamic> executeTransaction({
    List<String> exclusive,
    List<String> write,
    List<String> read,
    String action,
    dynamic params,
    bool allowImplicit,
    int lockTimeout,
    int maxTransactionSize,
    bool waitForSync,
  }) async {
    if (action == null) throw ArgumentError.notNull('action');
    if (write == null) throw ArgumentError.notNull('write');
    final resp = await _connection.request(
      method: 'POST',
      path: '/_api/transaction',
      body: {
        'collections': {
          if (exclusive != null) 'exclusive': exclusive,
          if (write != null) 'write': write,
          if (read != null) 'read': read,
        },
        if (action != null) 'action': action,
        if (params != null) 'params': params,
        if (allowImplicit != null) 'allowImplicit': allowImplicit,
        if (lockTimeout != null) 'lockTimeout': lockTimeout,
        if (maxTransactionSize != null)
          'maxTransactionSize': maxTransactionSize,
        if (waitForSync != null) 'waitForSync': waitForSync,
      },
    );
    return resp.body['result'];
  }

  Future<ArangoTransaction> beginTransaction({
    List<String> exclusive,
    List<String> write,
    List<String> read,
    bool allowImplicit,
    int lockTimeout,
    int maxTransactionSize,
    bool waitForSync,
  }) async {
    final resp = await _connection.request(
      method: 'POST',
      path: '/_api/transaction/begin',
      body: {
        'collections': {
          if (exclusive != null) 'exclusive': exclusive,
          if (write != null) 'write': write,
          if (read != null) 'read': read,
        },
        if (allowImplicit != null) 'allowImplicit': allowImplicit,
        if (lockTimeout != null) 'lockTimeout': lockTimeout,
        if (maxTransactionSize != null)
          'maxTransactionSize': maxTransactionSize,
        if (waitForSync != null) 'waitForSync': waitForSync,
      },
    );
    return ArangoTransaction(_connection, resp.body['result']['id']);
  }

  Future<List<Map<String, dynamic>>> listTransactions() async {
    final resp = await _connection.request(path: '/_api/transaction');
    return List<Map<String, dynamic>>.from(resp.body['transactions']);
  }

  Future<List<ArangoTransaction>> transactions() async {
    final transactions = await listTransactions();
    return transactions
        .map((t) => ArangoTransaction(_connection, t['id']))
        .toList();
  }
//#endregion
}
