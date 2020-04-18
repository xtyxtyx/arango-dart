## ArangoDB Dart Driver

The dart driver for [ArangoDB](https://www.arangodb.com/) the native multi-model database

### Index

- [ArangoDB Dart Driver](#arangodb-dart-driver)
  - [Index](#index)
  - [Quick Reference](#quick-reference)
  - [Usage](#usage)
  - [AQL](#aql)
  - [Features and bugs](#features-and-bugs)
  - [Todo](#todo)

### Quick Reference

| Database                                  | Collection                        | Document                    | Index                                             |
| ----------------------------------------- | --------------------------------- | --------------------------- | ------------------------------------------------- |
| [createDatabase][db.createDatabase]       | [create][cl.create]               | [replace][cl.replace]       | [ensureIndex][cl.ensureIndex]                     |
| [exists][db.exists]                       | [load][cl.load]                   | [update][cl.update]         | [ensureHashIndex][cl.ensureHashIndex]             |
| [version][db.version]                     | [unload][cl.unload]               | [bulkUpdate][cl.bulkUpdate] | [ensureSkipList][cl.ensureSkipListIndex]          |
| [listDatabases][db.listDatabases]         | [setProperties][cl.setProperties] | [remove][cl.remove]         | [ensureGeoIndex][cl.ensureGeoIndex]               |
| [listUserDatabases][db.listUserDatabases] | [rename][cl.rename]               | [list][cl.list]             | [ensureFulltextIndex][cl.ensureFulltextIndex]     |
| [dropDatabase][db.dropDatabase]           | [rotate][cl.rotate]               | [save][dc.save]             | [ensurePersistentIndex][cl.ensurePersistentIndex] |
| [truncate][db.truncate]                   | [truncate][cl.truncate]           |                             | [index][cl.index]                                 |
| [query][db.query]                         | [drop][cl.drop]                   |                             | [indexes][cl.indexes]                             |
| [rawQuery][db.rawQuery]                   | [ensureExists][cl.ensureExists]   |                             | [dropIndex][cl.dropIndex]                         |
|                                           | [import][cl.import]               |                             |                                                   |
|                                           |                                   |                             |                                                   |

| Cursor                    | Simple Query                            | Transaction                                 |
| ------------------------- | --------------------------------------- | ------------------------------------------- |
| [count][cr.count]         | [all][cl.all]                           | [beginTransaction][db.beginTransaction]     |
| [all][cr.all]             | [list][cl.list]                         | [listTransactions][db.listTransactions]     |
| [next][cr.next]           | [any][cl.any]                           | [executeTransaction][db.executeTransaction] |
| [hasNext][cr.hasNext]     | [byExample][cl.byExample]               | [exists][tx.exists]                         |
| [nextBatch][cr.nextBatch] | [firstExample][cl.firstExample]         | [get][tx.get]                               |
| [each][cr.each]           | [removeByExample][cl.removeByExample]   | [commit][tx.commit]                         |
| [every][cr.every]         | [replaceByExample][cl.replaceByExample] | [abort][tx.abort]                           |
| [some][cr.some]           | [updateByExample][cl.updateByExample]   | [run][tx.run]                               |
| [map][cr.map]             | [lookupByKeys][cl.lookupByKeys]         |                                             |
| [reduce][cr.reduce]       | [removeByKeys][cl.removeByKeys]         |                                             |
| [kill][cr.kill]           |                                         |                                             |

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

Run query:
```dart
import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');
  db.useBasicAuth('root', '123123');

  final cursor = await db.rawQuery('FOR todo IN todos RETURN todo.title');
  final data = await cursor.all();
  print(data);

  // or with the fluent query builder
  final result = await db
      .query()
      .line('FOR todo IN todos')
      .line('RETURN todo.title')
      .toList();
  print(result);
}

```

### AQL

The ArangoDB Query Language (AQL) can be used to retrieve and modify data that are stored in ArangoDB.

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

[db.beginTransaction]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/beginTransaction.html
[db.collection]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/collection.html
[db.collections]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/collections.html
[db.createDatabase]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/createDatabase.html
[db.current]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/current.html
[db.dropDatabase]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/dropDatabase.html
[db.edgeCollection]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/edgeCollection.html
[db.executeTransaction]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/executeTransaction.html
[db.exists]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/exists.html
[db.listCollections]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/listCollections.html
[db.listDatabases]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/listDatabases.html
[db.listTransactions]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/listTransactions.html
[db.listUserDatabases]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/listUserDatabases.html
[db.login]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/login.html
[db.query]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/query.html
[db.rawQuery]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/rawQuery.html
[db.transactions]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/transactions.html
[db.truncate]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/truncate.html
[db.useBasicAuth]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/useBasicAuth.html
[db.useBearerAuth]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/useBearerAuth.html
[db.useDatabase]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/useDatabase.html
[db.version]: https://pub.dev/documentation/arango/latest/arango/ArangoDatabase/version.html

[cl.all]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/all.html
[cl.any]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/any.html
[cl.bulkUpdate]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/bulkUpdate.html
[cl.byExample]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/byExample.html
[cl.checksum]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/checksum.html
[cl.count]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/count.html
[cl.create]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/create.html
[cl.document]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/document.html
[cl.documentExists]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/documentExists.html
[cl.drop]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/drop.html
[cl.dropIndex]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/dropIndex.html
[cl.ensureExists]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/ensureExists.html
[cl.ensureFulltextIndex]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/ensureFulltextIndex.html
[cl.ensureGeoIndex]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/ensureGeoIndex.html
[cl.ensureHashIndex]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/ensureHashIndex.html
[cl.ensureIndex]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/ensureIndex.html
[cl.ensurePersistentIndex]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/ensurePersistentIndex.html
[cl.ensureSkipListIndex]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/ensureSkipListIndex.html
[cl.ensureTTLIndex]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/ensureTTLIndex.html
[cl.exists]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/exists.html
[cl.figures]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/figures.html
[cl.firstExample]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/firstExample.html
[cl.get]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/get.html
[cl.getResponsibleShard]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/getResponsibleShardb.html
[cl.import]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/import.html
[cl.index]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/index.html
[cl.indexes]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/indexes.html
[cl.list]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/list.html
[cl.load]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/loadb.html
[cl.lookupByKeys]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/lookupByKeys.html
[cl.properties]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/properties.html
[cl.remove]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/remove.html
[cl.removeByExample]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/removeByExample.html
[cl.removeByKeys]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/removeByKeys.html
[cl.rename]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/rename.html
[cl.replace]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/replace.html
[cl.replaceByExample]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/replaceByExample.html
[cl.revision]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/revision.html
[cl.rotate]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/rotate.html
[cl.setProperties]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/setProperties.html
[cl.truncate]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/truncate.html
[cl.unload]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/unloadb.html
[cl.update]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/update.html
[cl.updateByExample]: https://pub.dev/documentation/arango/latest/arango/ArangoCollection/updateByExample.html

[dc.save]: https://pub.dev/documentation/arango/latest/arango/ArangoDocumentCollection/save.html

[cr.all]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/all.html
[cr.each]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/each.html
[cr.every]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/every.html
[cr.kill]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/kill.html
[cr.map]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/map.html
[cr.next]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/next.html
[cr.nextBatch]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/nextBatch.html
[cr.reduce]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/reduce.html
[cr.some]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/some.html
[cr.count]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/count.html
[cr.hasNext]: https://pub.dev/documentation/arango/latest/arango/ArangoCursor/hasNext.html

[tx.abort]: https://pub.dev/documentation/arango/latest/arango/ArangoTransaction/abort.html
[tx.commit]: https://pub.dev/documentation/arango/latest/arango/ArangoTransaction/commit.html
[tx.exists]: https://pub.dev/documentation/arango/latest/arango/ArangoTransaction/exists.html
[tx.get]: https://pub.dev/documentation/arango/latest/arango/ArangoTransaction/get.html
[tx.run]: https://pub.dev/documentation/arango/latest/arango/ArangoTransaction/run.html