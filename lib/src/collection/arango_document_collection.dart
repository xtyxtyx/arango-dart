import 'package:arango/src/arango_connection.dart';
import 'package:arango/src/collection/arango_collection.dart';

class ArangoDocumentCollection extends ArangoCollection {
  @override
  final type = CollectionType.documentCollection;

  final ArangoConnection _connection;

  ArangoDocumentCollection(String name, this._connection)
      : super(name, _connection);

  Future<Map<String, dynamic>> save(
    dynamic data, {
    bool waitForSync,
    bool silent,
    bool returnNew,
  }) async {
    final queries = <String, String>{
      if (waitForSync != null) 'waitForSync': waitForSync.toString(),
      if (silent != null) 'silent': silent.toString(),
      if (returnNew != null) 'returnNew': returnNew.toString(),
      'collection': name,
    };

    if (_connection.arangoMajor <= 2) {
      final resp = await _connection.request(
        method: 'POST',
        path: '/_api/document',
        body: data,
        queries: queries,
      );
      return resp.body;
    }

    final resp = await _connection.request(
      method: 'POST',
      path: '/_api/document/$name',
      body: data,
      queries: queries,
    );

    return resp.body;
  }
}
