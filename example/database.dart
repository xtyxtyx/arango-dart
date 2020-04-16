import 'package:arango/arango.dart';

void main() async {
  final db = ArangoDatabase('http://localhost:8529');

  final jwt = await db.login('root', '123123');
  print('-- jwt: $jwt');
  // OR db.useBasicAuth('root', '123123');

  final version = await db.version();
  print('-- version: $version');

  final exists = await db.exists();
  print('-- exists: $exists');

  final current = await db.current();
  print('-- current: $current');

  final databases = await db.listDatabases();
  print('-- databases: $databases');

  final userDatabases = await db.listUserDatabases();
  print('-- userDatabases: $userDatabases');
}
