import 'package:arango/src/arango_connection.dart';
import 'package:arango/src/collection/arango_collection.dart';
import 'package:arango/src/collection/collection_status.dart';
import 'package:arango/src/collection/collection_type.dart';
import 'package:meta/meta.dart';

class ArangoEdgeCollection extends ArangoCollection {
  ArangoEdgeCollection({
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
}
