import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');
  db.useBasicAuth('root', '123123');

  final indexes = await db.collection('todos').indexes();
  print('-- indexes: $indexes');

  final index = await db.collection('todos').ensureIndex(['hello']);
  print('-- index: $index');

  await db.collection('todos').ensureHashIndex(['name']);
  await db.collection('todos').ensureSkipListIndex(['date']);
  await db.collection('todos').ensurePersistentIndex(['age']);
  await db.collection('todos').ensureTTLIndex(['subscription'], 100);
  await db.collection('todos').ensureFulltextIndex(['intro']);
}
