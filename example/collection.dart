import 'dart:convert';

import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');
  db.useBasicAuth('root', '123123');

  final collections = await db.listCollections();
  print('-- collections: $collections');
  // OR final collections = await db.collections();
  //    print('-- collections: $collections'

  final collection = await db.collection('todos').get();
  print('-- collection: $collection');

  final exists = await db.collection('todos1').exists();
  print('-- todos1 exists: $exists');

  await db.collection('todos1').ensureExists();

  final props = await db.collection('todos1').properties();
  print('-- todos1 props: $props');

  final count = await db.collection('todos1').count();
  print('-- count: $count');

  final figures = await db.collection('todos1').figures();
  print('-- figures: $figures');

  final revision = await db.collection('todos1').revision();
  print('-- revision: $revision');

  final load = await db.collection('todos1').load();
  print('-- load: $load');

  final docExists = await db.collection('todos1').documentExists('123');
  print('-- docExists: $docExists');

  final doc = await db.collection('todos1').document('123', graceful: true);
  print('-- doc: $doc');

  final replaceResult =
      await db.collection('todos1').replace('123', {'hello': 'world'});
  print('-- replaceResult: $replaceResult');

  final updateResult = await db.collection('todos1').update(
        '123',
        {'welcome': 'world'},
        mergeObjects: true,
      );
  print('-- updateResult: $updateResult');

  final list = await db.collection('todos1').list();
  print('-- list: $list');

  final cursor = await db.collection('todos1').all();
  final all = await cursor.all();
  print('-- all: $all');

  final any = await db.collection('todos1').any();
  print('-- any: $any');

  final example =
      await db.collection('todos1').firstExample({'hello': 'world'});
  print('-- example: $example');

  final replace = await db.collection('todos1').replaceByExample(
    {'hello': 'world'},
    {'hello': 'world!'},
  );
  print('-- replace: $replace');

  final update = await db.collection('todos1').updateByExample(
    {'hello': 'world!'},
    {'world': 'hello'},
  );
  print('-- update: $update');

  final lookup = await db.collection('todos1').lookupByKeys(['123']);
  print('-- lookup: $lookup');

  final remove = await db.collection('todos1').removeByKeys(['456']);
  print('-- remove: $remove');

  final save = await db.collection('todos1').save({'time': 'now'});
  print('-- save: $save');
}
