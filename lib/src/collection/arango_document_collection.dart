import 'package:arango/src/arango_connection.dart';
import 'package:arango/src/collection/arango_collection.dart';
import 'package:arango/src/collection/collection_status.dart';
import 'package:arango/src/collection/collection_type.dart';
import 'package:meta/meta.dart';

class ArangoDocumentCollection extends ArangoCollection {
  ArangoDocumentCollection({
    @required String name,
    @required ArangoConnection connection,
    String id,
    CollectionStatus status,
    CollectionType type,
    bool isSystem,
    String globallyUniqueId,
  }) : super(
          name: name,
          connection: connection,
          id: id,
          status: status,
          type: type,
          isSystem: isSystem,
          globallyUniqueId: globallyUniqueId,
        );

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

    if (connection.arangoMajor <= 2) {
      final resp = await connection.request(
        method: 'POST',
        path: '/_api/document',
        body: data,
        queries: queries,
      );
      return resp.body;
    }

    final resp = await connection.request(
      method: 'POST',
      path: '/_api/document/$name',
      body: data,
      queries: queries,
    );

    return resp.body;
  }
}
