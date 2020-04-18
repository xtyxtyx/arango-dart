import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');
  db.useBasicAuth('root', '123123');

  await db.collection('todos').ensureExists();
  await db.collection('todos').save({'content': 'Go shopping'});

  final result = await db.executeTransaction(
    write: ['todos'],
    action: r'''
    function(params) {
      const { query } = require("@arangodb");
      return query`
        FOR todo IN todos
        RETURN todo.content
      `.toArray();
    }
  ''',
  );
  print('-- txn result: $result');
}
