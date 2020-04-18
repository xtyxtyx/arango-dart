import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arango/src/arango_config.dart';
import 'package:arango/src/arango_errors.dart';
import 'package:arango/src/arango_helper.dart';
import 'package:arango/src/arango_requester.dart';

const leaderEndpointHeader = 'x-arango-endpoint';

class ArangoTask {
  ArangoTask({
    this.retries,
    this.host,
    this.request,
    this.allowDirtyRead,
    this.completer,
  });

  int host;
  final bool allowDirtyRead;
  final ArangoRequest request;
  final Completer<ArangoResponse> completer;

  int retries;
}

class ArangoConnection {
  ArangoConnection(
    this.config, {
    this.loadBalancingStrategy = LoadBalancingStrategy.none,
  }) : _arangoVersion = config.arangoVersion ?? 30000 {
    final urls = config.urls ?? [config.url] ?? ['http://localhost:8529'];
    addToHostList(urls);

    if (loadBalancingStrategy == LoadBalancingStrategy.oneRandom) {
      _activeHost = (rand.nextDouble() * _hosts.length).floor();
      _activeDirtyHost = (rand.nextDouble() * _hosts.length).floor();
    } else {
      _activeHost = 0;
      _activeDirtyHost = 0;
    }
  }

  final ArangoConfig config;
  final LoadBalancingStrategy loadBalancingStrategy;

  final int _arangoVersion;
  final _maxTasks = 3;
  final _maxRetries = 0;
  final _urls = <String>[];
  final _queue = <ArangoTask>[];
  final _hosts = <ArangoRequester>[];

  var _activeTasks = 0;
  int _activeHost;
  int _activeDirtyHost;
  String _transactionId;

  bool get _shouldRetry => _maxTasks != null;
  bool get _useFailOver =>
      loadBalancingStrategy != LoadBalancingStrategy.roundRobin;

  String _databaseName;
  final Map<String, String> _headers = {};

  String get _databasePath {
    return _databaseName == null ? '' : '/_db/$_databaseName';
  }

  int get arangoMajor {
    return (_arangoVersion / 10000).floor();
  }

  void setTransactionId(String transactionId) {
    _transactionId = transactionId;
  }

  void clearTransactionId() {
    _transactionId = null;
  }

  ArangoConnection setDatabaseName(String name) {
    _databaseName = name;
    return this;
  }

  ArangoConnection setHeader(String key, String value) {
    _headers[key] = value;
    return this;
  }

  List<int> addToHostList(List<String> urls) {
    final cleanUrls = urls.map(sanitizeUrl);
    final newUrls = cleanUrls.where((url) => !_urls.contains(url)).toList();
    _urls.addAll(newUrls);
    _hosts.addAll(newUrls.map((url) => ArangoRequester(url)));
    return cleanUrls.map<int>((url) => _urls.indexOf(url)).toList();
  }

  String _buildPath({
    String path,
    String basePath,
    bool absolutePath,
  }) {
    var pathname = '';
    if (absolutePath != true) {
      pathname = _databasePath;
      if (basePath != null) pathname += basePath;
    }
    if (path != null) pathname += path;
    return pathname;
  }

  Future<ArangoResponse> request({
    String path,
    String basePath,
    bool absolutePath,
    String method = 'GET',
    Map<String, String> headers = const {},
    Map<String, String> queries = const {},
    int host,
    bool isBinary = false,
    bool expectBinary = false,
    bool allowDirtyRead = false,
    Duration timeout,
    dynamic body,
  }) async {
    var contentType = 'text/plain';

    if (isBinary == true) {
      contentType = 'application/octet-stream';
    } else if (body != null) {
      if (body is Map) {
        body = json.encode(body);
        contentType = 'application/json';
      }
    }

    final extraHeaders = {
      ..._headers,
      'content-type': contentType,
      'x-arango-version': _arangoVersion.toString(),
    };

    if (_transactionId != null) {
      extraHeaders['x-arango-trx-id'] = _transactionId;
    }

    final completer = Completer<ArangoResponse>();

    final request = ArangoRequest(
      method: method,
      body: body,
      headers: {...extraHeaders, ...headers},
      queries: queries,
      expectBinary: expectBinary,
      timeout: timeout,
      path: _buildPath(
        path: path,
        basePath: basePath,
        absolutePath: absolutePath,
      ),
    );

    final task = ArangoTask(
        retries: 0,
        host: host,
        request: request,
        completer: completer,
        allowDirtyRead: allowDirtyRead);

    _queue.add(task);
    _runQueue();

    final resp = await completer.future;

    if (resp.body is Map &&
        resp.body.containsKey('error') &&
        resp.body.containsKey('code') &&
        resp.body.containsKey('errorMessage') &&
        resp.body.containsKey('errorNum')) {
      throw ArangoError(resp);
    } else if (resp.statusCode >= 400) {
      throw ArangoHttpError(resp);
    } else {
      return resp;
    }
  }

  void _runQueue() async {
    if (_queue.isEmpty || _activeTasks >= _maxTasks) return;
    final task = _queue.removeAt(0);
    var host = _activeHost;
    if (task.host != null) {
      host = task.host;
    } else if (task.allowDirtyRead == true) {
      host = _activeDirtyHost;
      _activeDirtyHost = (_activeDirtyHost + 1) % _hosts.length;
      task.request.headers['x-arango-allow-dirty-read'] = 'true';
    } else if (loadBalancingStrategy == LoadBalancingStrategy.roundRobin) {
      _activeHost = (_activeHost + 1) % _hosts.length;
    }
    _activeTasks += 1;
    try {
      final resp = await _hosts[host].request(task.request);
      if (resp.response.statusCode == 503 &&
          resp.response.headers[leaderEndpointHeader] != null) {
        final url = resp.response.headers[leaderEndpointHeader].first;
        final index = addToHostList([url]).first;
        task.host = index;
        if (_activeHost == host) {
          _activeHost = index;
        }
        _queue.add(task);
      } else {
        resp.arangoDartHostId = host;
        task.completer.complete(resp);
      }
    } catch (e) {
      if (task.allowDirtyRead != true &&
          _hosts.length > 1 &&
          _activeHost == host &&
          _useFailOver == true) {
        _activeHost = (_activeHost + 1) % _hosts.length;
      }
      if (task.host == null &&
          _shouldRetry &&
          task.retries < (_maxRetries ?? _hosts.length - 1) &&
          e is SocketException) {
        task.retries += 1;
        _queue.add(task);
      } else {
        task.completer.completeError(e);
      }
    } finally {
      _activeTasks -= 1;
      _runQueue();
    }
  }
}
