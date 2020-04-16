import 'package:arango/src/arango_connection.dart';

class ArangoCursor {
  final Map<String, dynamic> extra;
  final int count;

  final ArangoConnection _connection;
  final int _host;
  final bool _allowDirtyRead;
  final String _id;

  List<dynamic> _result;
  bool _hasMore;

  ArangoCursor(
    this._connection,
    this._host,
    this._allowDirtyRead,
    Map<String, dynamic> body,
  )   : extra = body['extra'],
        count = body['count'],
        _result = body['result'],
        _id = body['id'],
        _hasMore = body['id'] != null && body['hasMore'] == true;

  Future<ArangoCursor> _drain() async {
    await _more();
    if (_hasMore != true) return this;
    return _drain();
  }

  Future<void> _more() async {
    if (_hasMore != true) return;

    final resp = await _connection.request(
      method: 'PUT',
      path: '/_api/cursor/$_id',
      host: _host,
      allowDirtyRead: _allowDirtyRead,
    );

    _result.addAll(resp.body['result']);
    _hasMore = resp.body['hasMore'];
  }

  Future<List<dynamic>> all() async {
    await _drain();
    final result = _result;
    _result = [];
    return result;
  }

  Future<dynamic> next() async {
    while (_result.isEmpty && _hasMore) {
      await _more();
    }
    if (_result.isEmpty) {
      return null;
    }

    return _result.removeAt(0);
  }

  bool get hasNext {
    return _hasMore || _result.isNotEmpty;
  }

  Future<List<dynamic>> nextBatch() async {
    while (_result.isEmpty && _hasMore) {
      await _more();
    }

    if (_result.isEmpty) {
      return null;
    }

    final result = _result;
    _result = [];
    return result;
  }

  Future<bool> each(
    dynamic Function(dynamic value, int index, ArangoCursor self) fn,
  ) async {
    var index = 0;
    while (_result.isNotEmpty || _hasMore) {
      while (_result.isNotEmpty) {
        final result = fn(_result.removeAt(0), index, this);
        index++;
        if (result == false) return result;
      }
      if (_hasMore) await _more();
    }
    return true;
  }

  Future<bool> every(
    bool Function(dynamic value, int index, ArangoCursor self) fn,
  ) async {
    var index = 0;
    while (_result.isNotEmpty || _hasMore) {
      while (_result.isNotEmpty) {
        final result = fn(_result.removeAt(0), index, this);
        index++;
        if (!result) return result;
      }
      if (_hasMore) await _more();
    }
    return true;
  }

  Future<bool> some(
    bool Function(dynamic value, int index, ArangoCursor self) fn,
  ) async {
    var index = 0;
    while (_result.isNotEmpty || _hasMore) {
      while (_result.isNotEmpty) {
        final result = fn(_result.removeAt(0), index, this);
        index++;
        if (result) return result;
      }
      if (_hasMore) await _more();
    }
    return false;
  }

  Stream<T> map<T>(
    T Function(dynamic value, int index, ArangoCursor self) fn,
  ) async* {
    var index = 0;
    while (_result.isNotEmpty || _hasMore) {
      while (_result.isNotEmpty) {
        yield fn(_result.removeAt(0), index, this);
        index++;
      }
      if (_hasMore) await _more();
    }
  }

  Future<T> reduce<T>(
    T Function(T accu, dynamic value, int index, ArangoCursor self) fn,
    T accu,
  ) async {
    var index = 0;
    while (_result.isNotEmpty || _hasMore) {
      while (_result.isNotEmpty) {
        accu = fn(accu, _result.removeAt(0), index, this);
        index++;
      }
      if (_hasMore) await _more();
    }
    return accu;
  }

  Future<void> kill() async {
    if (_hasMore != true) return;

    await _connection.request(
      method: 'DELETE',
      path: '/_api/cursor/$_id',
    );

    _hasMore = false;
    return;
  }

  @override
  String toString() {
    return 'ArangoCursor{hasNext: $hasNext}';
  }
}
