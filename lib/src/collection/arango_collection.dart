import 'dart:convert';

import 'package:arango/src/arango_connection.dart';
import 'package:arango/src/arango_cursor.dart';
import 'package:arango/src/arango_errors.dart';
import 'package:arango/src/collection/collection_status.dart';
import 'package:arango/src/collection/collection_type.dart';
import 'package:meta/meta.dart';

class KeyGeneratorType {
  const KeyGeneratorType._(this._name);

  final String _name;

  static const traditional = KeyGeneratorType._('traditional');
  static const autoincrement = KeyGeneratorType._('autoincrement');

  @override
  String toString() => _name;
}

class ImportType {
  const ImportType._(this._name);

  final String _name;

  static const auto = ImportType._('auto');
  static const documents = ImportType._('documents');
  static const array = ImportType._('array');

  @override
  String toString() => _name;
}

class OnDuplicateType {
  const OnDuplicateType._(this._name);

  final String _name;

  static const error = OnDuplicateType._('error');
  static const update = OnDuplicateType._('update');
  static const replace = OnDuplicateType._('replace');
  static const ignore = OnDuplicateType._('ignore');

  @override
  String toString() => _name;
}

class IndexType {
  const IndexType._(this._name);

  final String _name;

  static const hash = IndexType._('hash');
  static const skiplist = IndexType._('skiplist');
  static const persistent = IndexType._('persistent');
  static const ttl = IndexType._('ttl');
  static const geo = IndexType._('geo');
  static const fulltext = IndexType._('fulltext');

  @override
  String toString() => _name;
}

abstract class ArangoCollection {
  ArangoCollection({
    @required String name,
    @required this.connection,
    this.id,
    this.status,
    this.type,
    this.isSystem,
    this.globallyUniqueId,
  }) : _name = name;

  final ArangoConnection connection;
  final String id;
  String _name;
  final CollectionStatus status;
  final CollectionType type;
  final bool isSystem;
  final String globallyUniqueId;

  String get name => _name;

  String get _idPrefix => '$name/';

  String _documentPath(String documentHandle) {
    return '/document/${_documentHandle(documentHandle)}';
  }

  String _documentHandle(String documentHandle) {
    if (documentHandle.contains('/')) {
      return documentHandle;
    }
    return _idPrefix + documentHandle;
  }

  String _indexHandle(String indexHandle) {
    if (indexHandle.contains('/')) {
      return indexHandle;
    }
    return _idPrefix + indexHandle;
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String> queries,
  ]) async {
    final resp = await connection.request(
      path: '/_api/collection/$name/$path',
      queries: queries,
    );

    return resp.body;
  }

  Future<Map<String, dynamic>> _put(String path, [dynamic body]) async {
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/collection/$name/$path',
      body: body,
    );

    return resp.body;
  }

  Future<Map<String, dynamic>> get() async {
    final resp = await connection.request(path: '/_api/collection/$name');
    return resp.body;
  }

  Future<bool> exists() async {
    try {
      await get();
    } on ArangoError catch (e) {
      const COLLECTION_NOT_FOUND = 1203;
      if (e.errorNum == COLLECTION_NOT_FOUND) {
        return false;
      } else {
        rethrow;
      }
    }
    return true;
  }

  Future<Map<String, dynamic>> create({
    bool waitForSync,
    int journalSize,
    bool isVolatile,
    bool isSystem,
    int numberOfShards,
    List<String> shardKeys,
    String distributeShardsLike,
    String shardingStrategy,
    String smartJoinAttribute,
    int replicationFactor,
    int minReplicationFactor,
    bool waitForSyncReplication,
    bool enforceReplicationFactor,
    KeyGeneratorType keyType,
    bool keyAllowUserKeys,
    int keyIncrement,
    int keyOffset,
  }) async {
    final body = {
      'name': name,
      'type': type,
      if (waitForSync != null) 'waitForSync': waitForSync,
      if (journalSize != null) 'journalSize': journalSize,
      if (isVolatile != null) 'isVolatile': isVolatile,
      if (isSystem != null) 'isSystem': isSystem,
      'keyOptions': {
        if (keyType != null) 'type': keyType,
        if (keyAllowUserKeys != null) 'allowUserKeys': keyAllowUserKeys,
        if (keyIncrement != null) 'increment': keyIncrement,
        if (keyOffset != null) 'offset': keyOffset,
      },
      if (numberOfShards != null) 'numberOfShards': numberOfShards,
      if (shardKeys != null) 'shardKeys': shardKeys,
      if (distributeShardsLike != null)
        'distributeShardsLike': distributeShardsLike,
      if (shardingStrategy != null) 'shardingStrategy': shardingStrategy,
      if (smartJoinAttribute != null) 'smartJoinAttribute': smartJoinAttribute,
      if (replicationFactor != null) 'replicationFactor': replicationFactor,
      if (minReplicationFactor != null)
        'minReplicationFactor': minReplicationFactor,
    };

    final qs = <String, String>{};
    if (waitForSyncReplication != null) {
      qs['waitForSyncReplication'] = waitForSyncReplication ? '1' : '0';
    }
    if (enforceReplicationFactor != null) {
      qs['enforceReplicationFactor'] = enforceReplicationFactor ? '1' : '0';
    }

    final resp = await connection.request(
      method: 'POST',
      path: '/_api/collection',
      body: body,
      queries: qs,
    );

    return resp.body;
  }

  Future<void> ensureExists() async {
    if (!await exists()) {
      try {
        await create();
      } on ArangoError catch (e) {
        const duplicateName = 1207;
        if (e.errorNum == duplicateName) {
          return;
        } else {
          rethrow;
        }
      }
    }
  }

  Future<Map<String, dynamic>> properties() {
    return _get('properties');
  }

  Future<Map<String, dynamic>> count() {
    return _get('count');
  }

  Future<Map<String, dynamic>> figures() {
    return _get('figures');
  }

  Future<Map<String, dynamic>> revision() {
    return _get('revision');
  }

  Future<Map<String, dynamic>> checksum([Map<String, String> opts]) {
    return _get('checksum', opts);
  }

  Future<Map<String, dynamic>> load({bool count}) {
    final body = count == true ? {'count': count} : null;
    return _put('load', body);
  }

  Future<Map<String, dynamic>> unload() {
    return _put('unload', null);
  }

  Future<Map<String, dynamic>> setProperties({
    bool waitForSync,
    int journalSize,
    int indexBuckets,
    int replicationFactor,
    int minReplicationFactor,
  }) {
    final body = {
      if (waitForSync != null) 'waitForSync': waitForSync,
      if (journalSize != null) 'journalSize': journalSize,
      if (indexBuckets != null) 'indexBuckets': indexBuckets,
      if (replicationFactor != null) 'replicationFactor': replicationFactor,
      if (minReplicationFactor != null)
        'minReplicationFactor': minReplicationFactor,
    };
    return _put('properties', body);
  }

  Future<Map<String, dynamic>> rename(String name) async {
    final resp = await connection.request(
        method: 'PUT',
        path: '/_api/collection/$name/rename',
        body: {'name': name});
    _name = name;
    return resp.body;
  }

  Future<Map<String, dynamic>> rotate() {
    return _put('rotate', null);
  }

  Future<Map<String, dynamic>> truncate() {
    return _put('truncate', null);
  }

  Future<Map<String, dynamic>> drop(Map<String, String> opts) async {
    final resp = await connection.request(
      method: 'DELETE',
      path: '/_api/collection/$name',
      queries: opts,
    );
    return resp.body;
  }

  Future<String> getResponsibleShard(Map<String, dynamic> document) async {
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/collection/$name/responsibleShard',
      body: document,
    );
    return resp.body['shardId'];
  }

  Future<bool> documentExists(String documentHandle) async {
    try {
      await connection.request(
        method: 'HEAD',
        path: '/_api/${_documentPath(documentHandle)}',
      );
      return true;
    } on ArangoHttpError catch (e) {
      if (e.statusCode == 404) {
        return false;
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> document(
    String documentHandle, {
    bool graceful = false,
    bool allowDirtyRead = false,
  }) async {
    try {
      final resp = await connection.request(
        path: '/_api/${_documentPath(documentHandle)}',
        allowDirtyRead: allowDirtyRead,
      );
      return resp.body;
    } on ArangoError catch (e) {
      const DOCUMENT_NOT_FOUND = 1202;
      if (graceful || e.errorNum == DOCUMENT_NOT_FOUND) {
        return null;
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> replace(
    String documentHandle,
    Map<String, dynamic> newValue, {
    String rev,
    bool waitForSync,
    bool silent,
    bool returnNew,
    bool returnOld,
  }) async {
    final headers = <String, String>{};
    if (rev != null && connection.arangoMajor >= 3) {
      headers['if-match'] = rev;
    }

    final queries = <String, String>{};
    if (waitForSync == true) queries['waitForSync'] = 'true';
    if (silent == true) queries['silent'] = 'true';
    if (returnNew == true) queries['returnNew'] = 'true';
    if (returnOld == true) queries['returnOld'] = 'true';

    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/${_documentPath(documentHandle)}',
      body: newValue,
      queries: queries,
      headers: headers,
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> update(
    String documentHandle,
    Map<String, dynamic> newValue, {
    String rev,
    bool waitForSync,
    bool silent,
    bool returnNew,
    bool returnOld,
    bool keepNull,
    bool mergeObjects,
  }) async {
    final headers = <String, String>{};
    if (rev != null && connection.arangoMajor >= 3) {
      headers['if-match'] = rev;
    }

    final queries = <String, String>{};
    if (waitForSync == true) queries['waitForSync'] = 'true';
    if (silent == true) queries['silent'] = 'true';
    if (returnNew == true) queries['returnNew'] = 'true';
    if (returnOld == true) queries['returnOld'] = 'true';
    if (keepNull == true) queries['keepNull'] = 'true';
    if (mergeObjects == true) queries['mergeObjects'] = 'true';

    final resp = await connection.request(
      method: 'PATCH',
      path: '/_api/${_documentPath(documentHandle)}',
      body: newValue,
      queries: queries,
      headers: headers,
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> bulkUpdate(
    List<Map<String, dynamic>> newValues, [
    Map<String, dynamic> opts,
  ]) async {
    final resp = await connection.request(
      method: 'PATCH',
      path: '/_api/document/$name',
      body: newValues,
      queries: opts,
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> remove(
    String documentHandle, {
    String rev,
    bool waitForSync,
    bool overwrite,
    bool returnOld,
    bool silent,
  }) async {
    final headers = <String, String>{};
    if (rev != null && connection.arangoMajor >= 3) {
      headers['if-match'] = rev;
    }

    final queries = <String, String>{};
    if (waitForSync == true) queries['waitForSync'] = 'true';
    if (overwrite == true) queries['silent'] = 'true';
    if (returnOld == true) queries['returnNew'] = 'true';
    if (silent == true) queries['returnOld'] = 'true';

    final resp = await connection.request(
      method: 'DELETE',
      path: '/_api/${_documentPath(documentHandle)}',
      queries: queries,
      headers: headers,
    );

    return resp.body;
  }

  Future<List<String>> list([String type = 'id']) async {
    if (connection.arangoMajor <= 2) {
      final resp = await connection.request(
        path: '/_api/document',
        queries: {'type': type, 'collection': name},
      );
      return List<String>.from(resp.body['documents']);
    }

    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/simple/all-keys',
      body: {'type': type, 'collection': name},
    );

    return List<String>.from(resp.body['result']);
  }

  Future<ArangoCursor> all([Map<String, dynamic> opts]) async {
    opts ??= {};
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/simple/all',
      body: {...opts, 'collection': name},
    );
    return ArangoCursor(connection, resp.arangoDartHostId, false, resp.body);
  }

  /// Fetches a document from the collection at random.
  Future<Map<String, dynamic>> any() async {
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/simple/any',
      body: {'collection': name},
    );
    return resp.body['document'];
  }

  Future<ArangoCursor> byExample(
    Map<String, dynamic> example, [
    Map<String, dynamic> opts,
  ]) async {
    opts ??= {};
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/simple/by-example',
      body: {...opts, 'example': example, 'collection': name},
    );
    return ArangoCursor(connection, resp.arangoDartHostId, false, resp.body);
  }

  Future<Map<String, dynamic>> firstExample(
    Map<String, dynamic> example,
  ) async {
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/simple/first-example',
      body: {'example': example, 'collection': name},
    );
    return resp.body['document'];
  }

  Future<int> removeByExample(
    Map<String, dynamic> example, {
    bool waitForSync,
    int limit,
  }) async {
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/simple/remove-by-example',
      body: {
        if (waitForSync != null) 'waitForSync': waitForSync,
        if (limit != null) 'limit': limit,
        'example': example,
        'collection': name,
      },
    );
    return resp.body['deleted'];
  }

  Future<int> replaceByExample(
    Map<String, dynamic> example,
    Map<String, dynamic> newValue, {
    bool waitForSync,
    int limit,
  }) async {
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/simple/replace-by-example',
      body: {
        if (waitForSync != null) 'waitForSync': waitForSync,
        if (limit != null) 'limit': limit,
        'example': example,
        'newValue': newValue,
        'collection': name,
      },
    );
    return resp.body['replaced'];
  }

  Future<int> updateByExample(
    Map<String, dynamic> example,
    Map<String, dynamic> newValue, {
    int limit,
    bool keepNull,
    bool waitForSync,
    bool mergeObjects,
  }) async {
    final resp = await connection
        .request(method: 'PUT', path: '/_api/simple/update-by-example', body: {
      if (limit != null) 'limit': limit,
      if (keepNull != null) 'keepNull': keepNull,
      if (waitForSync != null) 'waitForSync': waitForSync,
      if (mergeObjects != null) 'mergeObjects': mergeObjects,
      'example': example,
      'newValue': newValue,
      'collection': name
    });
    return resp.body['updated'];
  }

  Future<List<Map<String, dynamic>>> lookupByKeys(List<String> keys) async {
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/simple/lookup-by-keys',
      body: {'keys': keys, 'collection': name},
    );
    return List<Map<String, dynamic>>.from(resp.body['documents']);
  }

  Future<Map<String, dynamic>> removeByKeys(
    List<String> keys, [
    Map<String, dynamic> options,
  ]) async {
    final resp = await connection.request(
      method: 'PUT',
      path: '/_api/simple/remove-by-keys',
      body: {
        if (options != null) 'options': options,
        'keys': keys,
        'collection': name
      },
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> import(
    dynamic data, {
    ImportType type = ImportType.auto,
    OnDuplicateType onDuplicate,
    String fromPrefix,
    String toPrefix,
    bool overwrite,
    bool waitForSync,
    bool complete,
    bool details,
  }) async {
    if (data is List) {
      data = data.map(json.encode).join('\r\n') + '\r\n';
    }

    final resp = await connection.request(
      method: 'POST',
      path: '/_api/import',
      body: data,
      isBinary: true,
      queries: {
        if (type != null) 'type': type.toString(),
        if (fromPrefix != null) 'fromPrefix': fromPrefix,
        if (toPrefix != null) 'toPrefix': toPrefix,
        if (overwrite != null) 'overwrite': overwrite.toString(),
        if (waitForSync != null) 'waitForSync': waitForSync.toString(),
        if (onDuplicate != null) 'onDuplicate': onDuplicate.toString(),
        if (complete != null) 'complete': complete.toString(),
        if (details != null) 'details': details.toString(),
        'collection': name
      },
    );

    return resp.body;
  }

  Future<List<Map<String, dynamic>>> indexes() async {
    final resp = await connection.request(
      path: '/_api/index',
      queries: {'collection': name},
    );
    return List<Map<String, dynamic>>.from(resp.body['indexes']);
  }

  Future<Map<String, dynamic>> index(String indexHandle) async {
    final resp = await connection.request(
      path: '/_api/index/${_indexHandle(indexHandle)}',
    );
    return Map<String, dynamic>.from(resp.body);
  }

  Future<Map<String, dynamic>> ensureIndex(
    List<String> fields, {
    IndexType type = IndexType.hash,
    bool unique = false,
  }) async {
    final resp = await connection.request(
      method: 'POST',
      path: '/_api/index',
      body: {'unique': unique, 'type': type.toString(), 'fields': fields},
      queries: {'collection': name},
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> dropIndex(String indexHandle) async {
    final resp = await connection.request(
      method: 'DELETE',
      path: '/_api/index/${_indexHandle(indexHandle)}',
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> ensureHashIndex(
    List<String> fields, {
    bool unique = false,
    bool sparse = false,
    bool deduplicate = true,
  }) async {
    final resp = await connection.request(
      method: 'POST',
      path: '/_api/index',
      body: {
        'type': 'hash',
        'unique': unique,
        'sparse': sparse,
        'deduplicate': deduplicate,
        'fields': fields,
      },
      queries: {'collection': name},
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> ensureSkipListIndex(
    List<String> fields, {
    bool unique = false,
    bool sparse = false,
    bool deduplicate = true,
  }) async {
    final resp = await connection.request(
      method: 'POST',
      path: '/_api/index',
      body: {
        'type': 'skiplist',
        'unique': unique,
        'sparse': sparse,
        'deduplicate': deduplicate,
        'fields': fields,
      },
      queries: {'collection': name},
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> ensurePersistentIndex(
    List<String> fields, {
    bool unique = false,
    bool sparse = false,
  }) async {
    final resp = await connection.request(
      method: 'POST',
      path: '/_api/index',
      body: {
        'type': 'persistent',
        'unique': unique,
        'sparse': sparse,
        'fields': fields,
      },
      queries: {'collection': name},
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> ensureTTLIndex(
    List<String> fields, [
    int expireAfter,
  ]) async {
    expireAfter ??= 0;
    final resp = await connection.request(
      method: 'POST',
      path: '/_api/index',
      body: {
        'type': 'ttl',
        'expireAfter': expireAfter,
        'fields': fields,
      },
      queries: {'collection': name},
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> ensureGeoIndex(
    List<String> fields, {
    bool geoJson,
  }) async {
    final resp = await connection.request(
      method: 'POST',
      path: '/_api/index',
      body: {
        'fields': fields,
        'type': 'geo',
        if (geoJson != null) 'geoJson': geoJson,
      },
      queries: {'collection': name},
    );
    return resp.body;
  }

  Future<Map<String, dynamic>> ensureFulltextIndex(
    List<String> fields, {
    int minLength,
  }) async {
    final resp = await connection.request(
      method: 'POST',
      path: '/_api/index',
      body: {
        'type': 'fulltext',
        'fields': fields,
        if (minLength != null) 'minLength': minLength,
      },
      queries: {'collection': name},
    );
    return resp.body;
  }
}
