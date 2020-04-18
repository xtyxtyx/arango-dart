## Dart Arango

[ArangoDB](https://www.arangodb.com/)

- [Dart Arango](#dart-arango)
  - [Quick Reference](#quick-reference)
  - [Usage](#usage)
  - [Features and bugs](#features-and-bugs)
  - [TODO](#todo)

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
| [kill]      | fulltext           |                      |

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

### Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme


### TODO

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