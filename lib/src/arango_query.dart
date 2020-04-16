import 'package:arango/src/arango_cursor.dart';
import 'package:arango/src/arango_database.dart';

class ArangoQuery {
  ArangoQuery(ArangoDatabase database)
      : assert(database != null),
        _database = database;

  final ArangoDatabase _database;
  final _lines = <String>[];
  final _bindVars = <String, dynamic>{};

  ArangoQuery line(String line) {
    _lines.add(line);
    return this;
  }

  ArangoQuery lineWhen(bool cond, String line, [String otherwise]) {
    if (cond == true) _lines.add(line);
    if (cond == false) _lines.add(otherwise);
    return this;
  }

  ArangoQuery bind(String key, dynamic value) {
    _bindVars[key] = value;
    return this;
  }

  String get _query => _lines.join('\n');

  Future<List> toList() async {
    final cursor = await toCursor();
    return cursor.all();
  }

  Stream<List> toStream() async* {
    final cursor = await toCursor();
    while (cursor.hasNext) {
      yield await cursor.nextBatch();
    }
  }

  Future<ArangoCursor> toCursor() {
    return _database.rawQuery(_query, bindVars: _bindVars);
  }
}
