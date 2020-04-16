import 'package:arango/src/arango_connection.dart';
import 'package:arango/src/arango_requester.dart';
import 'package:arango/src/collection/arango_document_collection.dart';
import 'package:arango/src/collection/arango_edge_collection.dart';

import '../../arango.dart';
import '../../arango.dart';
import '../../arango.dart';
import '../arango_errors.dart';

class CollectionType {
  static const documentCollection = 2;
  static const edgeCollection = 3;
}

class KeyGeneratorType {
  const KeyGeneratorType._(this._name);
  final String _name;

  static const traditional = KeyGeneratorType._('traditional');
  static const autoincrement = KeyGeneratorType._('autoincrement');

  @override
  String toString() => _name;
}

abstract class ArangoCollection {
  int get type;

  final ArangoConnection _connection;
  String _idPrefix;
  String _name;
  String get name => _name;

  ArangoCollection(this._name, this._connection) : _idPrefix = '$_name/';

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
    final resp = await _connection.request(
      path: '/_api/collection/$name/$path',
      queries: queries,
    );

    return resp.body;
  }

  Future<Map<String, dynamic>> _put(String path, [dynamic body]) async {
    final resp = await _connection.request(
      method: 'PUT',
      path: '/_api/collection/$name/$path',
      body: body,
    );

    return resp.body;
  }

  Future<Map<String, dynamic>> get() async {
    final resp = await _connection.request(path: '/_api/collection/$name');
    return resp.body;
  }

  Future<bool> exists() async {
    try {
      await get();
    } on ArangoError catch (e) {
      print('here');
      print(e.errorNum);
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

    final resp = await _connection.request(
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
    final resp = await _connection.request(
        method: 'PUT',
        path: '/_api/collection/$name/rename',
        body: {'name': name});
    _name = name;
    _idPrefix = '${name}/';
    return resp.body;
  }

  Future<Map<String, dynamic>> rotate() {
    return _put('rotate', null);
  }

  Future<Map<String, dynamic>> truncate() {
    return _put('truncate', null);
  }

  Future<Map<String, dynamic>> drop(Map<String, String> opts) async {
    final resp = await _connection.request(
      method: 'DELETE',
      path: '/_api/collection/$name',
      queries: opts,
    );
    return resp.body;
  }

  Future<String> getResponsibleShard(Map<String, dynamic> document) async {
    final resp = await _connection.request(
      method: 'PUT',
      path: '/_api/collection/$name/responsibleShard',
      body: document,
    );
    return resp.body['shardId'];
  }

  Future<bool> documentExists(String documentHandle) async {
    try {
      await _connection.request(
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
      final resp = await _connection.request(
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
    if (rev != null && _connection.arangoMajor >= 3) {
      headers['if-match'] = rev;
    }

    final queries = <String, String>{};
    if (waitForSync == true) queries['waitForSync'] = 'true';
    if (silent == true) queries['silent'] = 'true';
    if (returnNew == true) queries['returnNew'] = 'true';
    if (returnOld == true) queries['returnOld'] = 'true';

    final resp = await _connection.request(
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
    if (rev != null && _connection.arangoMajor >= 3) {
      headers['if-match'] = rev;
    }

    final queries = <String, String>{};
    if (waitForSync == true) queries['waitForSync'] = 'true';
    if (silent == true) queries['silent'] = 'true';
    if (returnNew == true) queries['returnNew'] = 'true';
    if (returnOld == true) queries['returnOld'] = 'true';
    if (keepNull == true) queries['keepNull'] = 'true';
    if (mergeObjects == true) queries['mergeObjects'] = 'true';

    final resp = await _connection.request(
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
    final resp = await _connection.request(
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
    if (rev != null && _connection.arangoMajor >= 3) {
      headers['if-match'] = rev;
    }

    final queries = <String, String>{};
    if (waitForSync == true) queries['waitForSync'] = 'true';
    if (overwrite == true) queries['silent'] = 'true';
    if (returnOld == true) queries['returnNew'] = 'true';
    if (silent == true) queries['returnOld'] = 'true';

    final resp = await _connection.request(
      method: 'DELETE',
      path: '/_api/${_documentPath(documentHandle)}',
      queries: queries,
      headers: headers,
    );

    return resp.body;
  }

  Future<List<String>> list([String type = 'id']) async {
    if (_connection.arangoMajor <= 2) {
      final resp = await _connection.request(
        path: '/_api/document',
        queries: {'type': type, 'collection': name},
      );
      return resp.body['documents'];
    }

    final resp = await _connection.request(
      method: 'PUT',
      path: '/_api/simple/all-keys',
      body: {'type': type, 'collection': name},
    );
    return resp.body['result'];
  }

  // all(opts?: any) {
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/all',
  //       body: {
  //         ...opts,
  //         collection: this.name
  //       }
  //     },
  //     res => new ArrayCursor(this._connection, res.body, res.arangojsHostId)
  //   );
  // }

  // any() {
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/any',
  //       body: { collection: this.name }
  //     },
  //     res => res.body.document
  //   );
  // }

  // byExample(example: any, opts?: any) {
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/by-example',
  //       body: {
  //         ...opts,
  //         example,
  //         collection: this.name
  //       }
  //     },
  //     res => new ArrayCursor(this._connection, res.body, res.arangojsHostId)
  //   );
  // }

  // firstExample(example: any) {
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/first-example',
  //       body: {
  //         example,
  //         collection: this.name
  //       }
  //     },
  //     res => res.body.document
  //   );
  // }

  // removeByExample(example: any, opts?: RemoveByExampleOptions) {
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/remove-by-example',
  //       body: {
  //         ...opts,
  //         example,
  //         collection: this.name
  //       }
  //     },
  //     res => res.body
  //   );
  // }

  // replaceByExample(
  //   example: any,
  //   newValue: any,
  //   opts?: { waitForSync?: boolean; limit?: number }
  // ) {
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/replace-by-example',
  //       body: {
  //         ...opts,
  //         example,
  //         newValue,
  //         collection: this.name
  //       }
  //     },
  //     res => res.body
  //   );
  // }

  // updateByExample(example: any, newValue: any, opts?: UpdateByExampleOptions) {
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/update-by-example',
  //       body: {
  //         ...opts,
  //         example,
  //         newValue,
  //         collection: this.name
  //       }
  //     },
  //     res => res.body
  //   );
  // }

  // lookupByKeys(keys: string[]) {
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/lookup-by-keys',
  //       body: {
  //         keys,
  //         collection: this.name
  //       }
  //     },
  //     res => res.body.documents
  //   );
  // }

  // removeByKeys(keys: string[], options: any) {
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/remove-by-keys',
  //       body: {
  //         options,
  //         keys,
  //         collection: this.name
  //       }
  //     },
  //     res => res.body
  //   );
  // }

  // import(
  //   data: Buffer | Blob | string | any[],
  //   { type = 'auto', ...opts }: ImportOptions = {}
  // ): Promise<ImportResult> {
  //   if (Array.isArray(data)) {
  //     data = data.map(line => JSON.stringify(line)).join('\r\n') + '\r\n';
  //   }
  //   return this._connection.request(
  //     {
  //       method: 'POST',
  //       path: '/_api/import',
  //       body: data,
  //       isBinary: true,
  //       qs: {
  //         type: type === null ? undefined : type,
  //         ...opts,
  //         collection: this.name
  //       }
  //     },
  //     res => res.body
  //   );
  // }

  // indexes() {
  //   return this._connection.request(
  //     {
  //       path: '/_api/index',
  //       qs: { collection: this.name }
  //     },
  //     res => res.body.indexes
  //   );
  // }

  // index(indexHandle: IndexHandle) {
  //   return this._connection.request(
  //     { path: '/_api/index/${this._indexHandle(indexHandle)}' },
  //     res => res.body
  //   );
  // }

  // ensureIndex(details: any) {
  //   return this._connection.request(
  //     {
  //       method: 'POST',
  //       path: '/_api/index',
  //       body: details,
  //       qs: { collection: this.name }
  //     },
  //     res => res.body
  //   );
  // }

  // /** @deprecated use ensureIndex instead */
  // createIndex(details: any) {
  //   return this.ensureIndex(details);
  // }

  // dropIndex(indexHandle: IndexHandle) {
  //   return this._connection.request(
  //     {
  //       method: 'DELETE',
  //       path: '/_api/index/${this._indexHandle(indexHandle)}'
  //     },
  //     res => res.body
  //   );
  // }

  // createHashIndex(fields: string[] | string, opts?: any) {
  //   if (typeof fields === 'string') {
  //     fields = [fields];
  //   }
  //   if (typeof opts === 'boolean') {
  //     opts = { unique: opts };
  //   }
  //   return this._connection.request(
  //     {
  //       method: 'POST',
  //       path: '/_api/index',
  //       body: { unique: false, ...opts, type: 'hash', fields: fields },
  //       qs: { collection: this.name }
  //     },
  //     res => res.body
  //   );
  // }

  // createSkipList(fields: string[] | string, opts?: any) {
  //   if (typeof fields === 'string') {
  //     fields = [fields];
  //   }
  //   if (typeof opts === 'boolean') {
  //     opts = { unique: opts };
  //   }
  //   return this._connection.request(
  //     {
  //       method: 'POST',
  //       path: '/_api/index',
  //       body: { unique: false, ...opts, type: 'skiplist', fields: fields },
  //       qs: { collection: this.name }
  //     },
  //     res => res.body
  //   );
  // }

  // createPersistentIndex(fields: string[] | string, opts?: any) {
  //   if (typeof fields === 'string') {
  //     fields = [fields];
  //   }
  //   if (typeof opts === 'boolean') {
  //     opts = { unique: opts };
  //   }
  //   return this._connection.request(
  //     {
  //       method: 'POST',
  //       path: '/_api/index',
  //       body: { unique: false, ...opts, type: 'persistent', fields: fields },
  //       qs: { collection: this.name }
  //     },
  //     res => res.body
  //   );
  // }

  // createGeoIndex(fields: string[] | string, opts?: any) {
  //   if (typeof fields === 'string') {
  //     fields = [fields];
  //   }
  //   return this._connection.request(
  //     {
  //       method: 'POST',
  //       path: '/_api/index',
  //       body: { ...opts, fields, type: 'geo' },
  //       qs: { collection: this.name }
  //     },
  //     res => res.body
  //   );
  // }

  // createFulltextIndex(fields: string[] | string, minLength?: number) {
  //   if (typeof fields === 'string') {
  //     fields = [fields];
  //   }
  //   return this._connection.request(
  //     {
  //       method: 'POST',
  //       path: '/_api/index',
  //       body: { fields, minLength, type: 'fulltext' },
  //       qs: { collection: this.name }
  //     },
  //     res => res.body
  //   );
  // }

  // fulltext(attribute: any, query: any, opts: any = {}) {
  //   if (opts.index) opts.index = this._indexHandle(opts.index);
  //   return this._connection.request(
  //     {
  //       method: 'PUT',
  //       path: '/_api/simple/fulltext',
  //       body: {
  //         ...opts,
  //         attribute,
  //         query,
  //         collection: this.name
  //       }
  //     },
  //     res => new ArrayCursor(this._connection, res.body, res.arangojsHostId)
  //   );
  // }
}

ArangoCollection constructCollection(
  ArangoConnection connection,
  Map<String, dynamic> data,
) {
  final name = data['name'];
  return data['type'] == CollectionType.edgeCollection
      ? ArangoEdgeCollection(name, connection)
      : ArangoDocumentCollection(name, connection);
}
