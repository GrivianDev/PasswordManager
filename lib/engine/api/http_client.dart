import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:passwordmanager/engine/other/util.dart';

class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  LoggingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (kDebugMode) {
      debugPrint('---- HTTP REQUEST ----');
      debugPrint('${request.method} ${request.url}');
      debugPrint('Headers: ${request.headers}');
    }

    final response = await _inner.send(request);

    if (!kDebugMode) return response;

    final responseBody = await response.stream.bytesToString();

    debugPrint('---- HTTP RESPONSE ----');
    debugPrint('Status: ${response.statusCode}');
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
