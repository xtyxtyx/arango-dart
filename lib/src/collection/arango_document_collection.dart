import 'package:arango/src/arango_connection.dart';
import 'package:arango/src/collection/arango_collection.dart';

class ArangoDocumentCollection extends ArangoCollection {
  @override
  final type = CollectionType.documentCollection;

  ArangoDocumentCollection(String name, ArangoConnection _connection)
      : super(name, _connection);
}
