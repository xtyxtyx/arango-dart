// interface TransactionStatus {
//   id: string;
//   status: 'running' | 'committed' | 'aborted';
// }

import 'package:arango/arango.dart';
import 'package:arango/src/arango_connection.dart';

class ArangoTransaction {
  final ArangoConnection _connection;
  final String id;

  ArangoTransaction(this._connection, this.id);

  Future<bool> exists() async {
    try {
      await get();
      return true;
    } on ArangoError catch (e) {
      const TRANSACTION_NOT_FOUND = 10;
      if (e.errorNum == TRANSACTION_NOT_FOUND) {
        return false;
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> get() async {
    final resp = await _connection.request(path: '/_api/transaction/$id');
    return resp.body['result'];
  }

  Future<Map<String, dynamic>> commit() async {
    final resp = await _connection.request(
      method: 'PUT',
      path: '/_api/transaction/$id',
    );
    return resp.body['result'];
  }

  Future<Map<String, dynamic>> abort() async {
    final resp = await _connection.request(
      method: 'DELETE',
      path: '/_api/transaction/$id',
    );
    return resp.body['result'];
  }

  Future<T> run<T>(Future<T> Function() fn) {
    _connection.setTransactionId(id);
    try {
      return fn();
    } finally {
      _connection.clearTransactionId();
    }
  }
}
