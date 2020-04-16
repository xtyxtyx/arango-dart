import 'package:arango/src/arango_connection.dart';
import 'package:arango/src/collection/arango_collection.dart';

class ArangoEdgeCollection extends ArangoCollection {
  @override
  final type = CollectionType.edgeCollection;

  ArangoEdgeCollection(String name, ArangoConnection _connection)
      : super(name, _connection);
}
