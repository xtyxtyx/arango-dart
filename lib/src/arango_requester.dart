import 'dart:convert';

import 'package:dio/dio.dart';

class ArangoRequest {
  ArangoRequest({
    required this.method,
    required this.path,
    this.headers,
    this.queries,
    this.body,
    this.timeout,
    this.expectBinary,
  });

  final String method;
  final String path;
  final Map<String, String?>? headers;
  final Map<String, String?>? queries;
  final dynamic body;
  final Duration? timeout;
  final bool? expectBinary;
}

class ArangoResponse {
  late final ArangoRequest request;
  late final Response response;
  int? arangoDartHostId;

  dynamic get body => response.data;
  int? get statusCode => response.statusCode;
}

class ArangoRequestOptions {
  int? maxSockets;
}

class ArangoRequester {
  ArangoRequester(this.baseUrl);

  final String baseUrl;

  Future<ArangoResponse> request(ArangoRequest request) async {
    final headers = Map<String, String>.from(request.headers ?? {});

    final baseUrl = Uri.parse(this.baseUrl);
    final auth = baseUrl.userInfo.isEmpty ? 'root:' : baseUrl.userInfo;
    final authEncoded = base64.encode(utf8.encode(auth));
    if (headers['authorization'] == null) {
      headers['authorization'] = 'Basic $authEncoded';
    }

    // print('${request.method} ${this.baseUrl}${request.path}');

    final response = await Dio(BaseOptions(
      baseUrl: this.baseUrl,
    )).request(
      request.path,
      data: request.body,
      queryParameters: request.queries,
      options: Options(
        method: request.method,
        headers: request.headers,
        validateStatus: (_) => true,
      ),
    );

    return ArangoResponse()
      ..request = request
      ..response = response;
  }
}
