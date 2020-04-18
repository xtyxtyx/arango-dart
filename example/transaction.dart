import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');
  db.useBasicAuth('root', '123123');

  await db.collection('accounts').ensureExists();
  await db.collection('accounts').truncate();

  final txn = await db.beginTransaction(write: ['accounts']);
  await txn.run(() => db.collection('accounts').save({'id': '1'}));
  await txn.run(() => db.collection('accounts').save({'id': '2'}));
  await txn.commit();

  final txn2 = await db.beginTransaction(write: ['accounts']);
  await txn2.run(() => db.collection('accounts').save({'id': '3'}));
  await txn2.run(() => db.collection('accounts').save({'id': '4'}));
  await txn2.abort();

  final data = await db
      .query()
      .line('FOR account IN accounts')
      .line('RETURN account.id')
      .toList();

  print('accounts: $data');
  // -> accounts: [1, 2]
}
