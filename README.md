## ArangoDB Dart Driver

The dart driver for [ArangoDB] the native multi-model database

[ArangoDB](https://www.arangodb.com/)

- [ArangoDB Dart Driver](#arangodb-dart-driver)
  - [Quick Reference](#quick-reference)
  - [Usage](#usage)
  - [AQL](#aql)
  - [Features and bugs](#features-and-bugs)
  - [Todo](#todo)

### Quick Reference

| Database            | Collection      | Document     | Index                   |
| ------------------- | --------------- | ------------ | ----------------------- |
| [createDatabase]    | [create]        | [replace]    | [ensureIndex]           |
| [exists]            | [load]          | [update]     | [ensureHashIndex]       |
| [get]               | [unload]        | [bulkUpdate] | [ensureSkipList]        |
| [listDatabases]     | [setProperties] | [remove]     | [ensureGeoIndex]        |
| [listUserDatabases] | [rename]        | [list]       | [ensureFulltextIndex]   |
| [dropDatabase]      | [rotate]        | [save]       | [ensurePersistentIndex] |
| [truncate]          | [truncate]      |              | [index]                 |
| [query]             | [drop]          |              | [indexes]               |
| [rawQuery]          | [ensureExists]  |              | [dropIndex]             |
|                     | [import]        |              |                         |
|                     |                 |              |                         |

| Cursor      | Simple Query       | Transaction          |
| ----------- | ------------------ | -------------------- |
| [count]     | [all]              | [beginTransaction]   |
| [all]       | [list]             | [listTransactions]   |
| [next]      | [any]              | [executeTransaction] |
| [hasNext]   | [byExample]        | [exists]             |
| [nextBatch] | [firstExample]     | [get]                |
| [each]      | [removeByExample]  | [commit]             |
| [every]     | [replaceByExample] | [abort]              |
| [some]      | [updateByExample]  | [run]                |
| [map]       | [lookupByKeys]     |                      |
| [reduce]    | [removeByKeys]     |                      |
| [kill]      |                    |                      |

> Simple Queries are deprecated from version 3.4.0 on. They are superseded by AQL queries.

### Usage

A simple todo example:

```dart
import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');
  db.useBasicAuth('root', 'YOUR-PASSWORD');

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
  // -> todos: [Go shopping, Go home]
}
```

Transactions:
```dart
import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');
  db.useBasicAuth('root', 'YOUR-PASSWORD');

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

```

### AQL

To learn more about AQL, please refer to https://www.arangodb.com/docs/stable/aql/

### Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/xtyxtyx/arango-dart/issues


### Todo

| Analyzer      | View             |
| ------------- | ---------------- |
| exists        | arangoSearchView |
| get           | listViews        |
| create        | views            |
| drop          |                  |
| listAnalyzers |                  |
| analyzers     |                  |
| analyzer      |                  |
|               |                  |