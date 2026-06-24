import 'dart:convert';

import 'package:ethercrypt/engine/other/util.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum HttpLogLevel {
  none,
  basic,
  verbose,
}

class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;
  final HttpLogLevel logLevel;

  LoggingHttpClient([
    http.Client? inner,
    this.logLevel = HttpLogLevel.basic,
  ]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stopwatch = Stopwatch()..start();
    final response = await _inner.send(request);
    stopwatch.stop();

    if (!kDebugMode || logLevel == HttpLogLevel.none) {
      return response;
    }

    if (logLevel == HttpLogLevel.basic) {
      debugPrint(
        '[${response.statusCode}] ${request.method} ${request.url} (${stopwatch.elapsedMilliseconds}ms)',
      );
      return response;
    }

    // verbose mode
    final responseBody = await response.stream.bytesToString();

    debugPrint('---- HTTP REQUEST ----');
    debugPrint('${request.method} ${request.url}');
    debugPrint('Headers: ${request.headers}');
    debugPrint('---- HTTP RESPONSE [${response.statusCode}] ----');
    debugPrint('Duration: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('Headers: ${response.headers}');
    debugPrint('Body: ${prettyJson(responseBody)}');

    // recreate response because we consumed the stream
    return http.StreamedResponse(
      Stream.value(utf8.encode(responseBody)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}
