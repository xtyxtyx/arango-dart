/// ArangoDB Dart driver
///
///### Usage
/// 
/// A simple todo example:
/// 
/// ```dart
/// import 'package:arango/arango.dart';
/// 
/// void main() async {
///   final db = ArangoDatabase('http://localhost:8529');
///   db.useBasicAuth('root', 'YOUR-PASSWORD');
/// 
///   await db.collection('todos').ensureExists();
///   await db.collection('todos').ensureTTLIndex(['expiresAt']);
///   await db.collection('todos').ensureFulltextIndex(['content']);
/// 
///   await db.collection('todos').save({'content': 'Go shopping'});
///   await db.collection('todos').save({'content': 'Go home'});
/// 
///   final todos = await db
///       .query()
///       .line('FOR todo IN todos')
///       .line('RETURN todo.content')
///       .toList();
/// 
///   print('todos: $todos');
///   // -> todos: [Go shopping, Go home]
/// }
/// ```
/// 
/// Transactions:
/// ```dart
/// import 'package:arango/arango.dart';
/// 
/// void main() async {
///   final db = ArangoDatabase('http://localhost:8529');
///   db.useBasicAuth('root', 'YOUR-PASSWORD');
/// 
///   await db.collection('accounts').ensureExists();
///   await db.collection('accounts').truncate();
/// 
///   final txn = await db.beginTransaction(write: ['accounts']);
///   await txn.run(() => db.collection('accounts').save({'id': '1'}));
///   await txn.run(() => db.collection('accounts').save({'id': '2'}));
///   await txn.commit();
/// 
///   final txn2 = await db.beginTransaction(write: ['accounts']);
///   await txn2.run(() => db.collection('accounts').save({'id': '3'}));
///   await txn2.run(() => db.collection('accounts').save({'id': '4'}));
///   await txn2.abort();
/// 
///   final data = await db
///       .query()
///       .line('FOR account IN accounts')
///       .line('RETURN account.id')
///       .toList();
/// 
///   print('accounts: $data');
///   // -> accounts: [1, 2]
/// }
/// 
/// ```
library arango;

export 'src/arango_cursor.dart';
export 'src/arango_database.dart';
export 'src/arango_errors.dart';
export 'src/arango_query.dart';
export 'src/arango_transaction.dart';
export 'src/collection/arango_collection.dart';
export 'src/collection/arango_document_collection.dart';
export 'src/collection/arango_edge_collection.dart';
export 'src/collection/collection_status.dart';
export 'src/collection/collection_type.dart';
