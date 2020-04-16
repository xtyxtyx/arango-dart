## Dart Arango

- [Dart Arango](#dart-arango)
  - [Quick Reference](#quick-reference)
  - [Usage](#usage)
  - [Features and bugs](#features-and-bugs)

### Quick Reference

| Database            | Collection      | Document     | Index                 |
| ------------------- | --------------- | ------------ | --------------------- |
| [createDatabase]    | [create]        | [replace]    | createIndex           |
| [exists]            | [load]          | [update]     | createHashIndex       |
| [get]               | [unload]        | [bulkUpdate] | createSkipList        |
| [listDatabases]     | [setProperties] | [remove]     | createGeoIndex        |
| [listUserDatabases] | [rename]        | [list]       | createFulltextIndex   |
| [dropDatabase]      | [rotate]        | save         | createPersistentIndex |
| [truncate]          | [truncate]      |              | index                 |
| [query]             | [drop]          |              | indexes               |
| [rawQuery]          | [ensureExists]  |              | dropIndex             |
|                     |                 |              | ensureIndex           |
|                     |                 |              |                       |

| Cursor      | Simple Query     | Transaction |
| ----------- | ---------------- | ----------- |
| [count]     | all              | exists      |
| [all]       | any              | get         |
| [next]      | byExample        | commit      |
| [hasNext]   | firstExample     | abort       |
| [nextBatch] | removeByExample  | run         |
| [each]      | replaceByExample |             |
| [every]     | updateByExample  |             |
| [some]      | lookupByKeys     |             |
| [map]       | removeByKeys     |             |
| [reduce]    |                  |             |
| [kill]      |                  |             |

### Usage

A simple usage example:

```dart
import 'package:arango/arango.dart';

main() {
  var awesome = new Awesome();
}
```

### Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
