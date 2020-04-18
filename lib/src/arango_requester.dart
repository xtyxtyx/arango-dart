import 'dart:convert';

import 'package:dio/dio.dart';

class ArangoRequest {
  ArangoRequest({
    this.method,
    this.path,
    this.headers,
    this.queries,
    this.body,
    this.timeout,
    this.expectBinary,
  });

  final String method;
  final String path;
  final Map<String, String> headers;
  final Map<String, String> queries;
  final dynamic body;
  final Duration timeout;
  final bool expectBinary;
}

class ArangoResponse {
  ArangoRequest request;
  Response response;
  int arangoDartHostId;

  dynamic get body => response.data;
  int get statusCode => response.statusCode;
}

class ArangoRequestOptions {
  int maxSockets;
}

class ArangoRequester {
  ArangoRequester(this.baseUrl);

  final String baseUrl;

  Future<ArangoResponse> request(ArangoRequest request) async {
    final headers = Map<String, String>.from(request.headers);

    final baseUrl = Uri.parse(this.baseUrl);
    final basicAuth = base64.encode(utf8.encode(baseUrl.userInfo ?? 'root:'));
    if (headers['authorization'] == null) {
      headers['authorization'] = 'Basic $basicAuth';
    }

    // print('${request.method} ${this.baseUrl}${request.path}');

    final response = await Dio().request(
      request.path,
      data: request.body,
      options: RequestOptions(
        baseUrl: this.baseUrl,
        method: request.method,
        headers: request.headers,
        queryParameters: request.queries,
        validateStatus: (_) => true,
      ),
    );

    return ArangoResponse()
      ..request = request
      ..response = response;
  }
}
