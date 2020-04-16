import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');
  db.useBasicAuth('root', '123123');

  final cursor = await db.rawQuery('FOR todo IN todos RETURN todo.title');
  final data = await cursor.all();
  print(data);

  // or use the fluent query builder
  final result = await db
      .query()
      .line('FOR todo IN todos')
      .line('RETURN todo.title')
      .toList();
  print(result);
}
