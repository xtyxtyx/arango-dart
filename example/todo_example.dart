import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');
  db.useBasicAuth('root', '123123');

  await db.collection('todos').ensureExists();
  await db.collection('todos').ensureTTLIndex(['expiresAt']);
  await db.collection('todos').ensureFulltextIndex(['content']);

  await db.collection('todos').save({'content': 'Go shopping'});
  await db.collection('todos').save({'content': 'Go home'});

  final todos = await db
      .query()
      .line('FOR todo IN todos')
      .line('RETURN todo.content')
      .toList();

  print('todos: $todos');
}
