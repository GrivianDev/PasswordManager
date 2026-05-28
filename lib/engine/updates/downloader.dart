import 'dart:async';
import 'dart:io';

import 'package:ethercrypt/engine/app_exception.dart';
import 'package:flutter/foundation.dart';

class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double bytesPerSecond;
  final bool finished;
  final bool canceled;

  const DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.bytesPerSecond,
    required this.finished,
    required this.canceled,
  });

  double get progress => totalBytes <= 0 ? 0 : downloadedBytes / totalBytes;

  bool get hasKnownSize => totalBytes > 0;

  DownloadProgress copyWith({
    int? downloadedBytes,
    int? totalBytes,
    double? bytesPerSecond,
    bool? finished,
    bool? canceled,
  }) {
    return DownloadProgress(
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
      finished: finished ?? this.finished,
      canceled: canceled ?? this.canceled,
    );
  }

  factory DownloadProgress.initial() {
    return const DownloadProgress(
      downloadedBytes: 0,
      totalBytes: 0,
      bytesPerSecond: 0,
      finished: false,
      canceled: false,
    );
  }
}

class Downloader {
  Downloader() : progress = ValueNotifier(DownloadProgress.initial());

  final ValueNotifier<DownloadProgress> progress;

  HttpClient? _client;

  bool _isCanceled = false;

  Future<void> startDownload(Uri url, File destination) async {
    IOSink? sink;

    try {
      _isCanceled = false;
      progress.value = DownloadProgress.initial();

      _client = HttpClient();
      final HttpClientRequest request = await _client!.getUrl(url);
      final HttpClientResponse response = await request.close();

      final int totalBytes = response.contentLength;
      int downloadedBytes = 0;

      sink = destination.openWrite();

      final Stopwatch stopwatch = Stopwatch()..start();

      int lastBytes = 0;
      int lastMilliseconds = 0;

      await for (final List<int> chunk in response) {
        if (_isCanceled) {
          break;
        }

        sink.add(chunk);

        downloadedBytes += chunk.length;

        final int nowMilliseconds = stopwatch.elapsedMilliseconds;

        double bytesPerSecond = 0;

        final int elapsedDelta = nowMilliseconds - lastMilliseconds;

        if (elapsedDelta >= 500) {
          bytesPerSecond = (downloadedBytes - lastBytes) / (elapsedDelta / 1000);

          lastBytes = downloadedBytes;
          lastMilliseconds = nowMilliseconds;
        } else {
          bytesPerSecond = progress.value.bytesPerSecond;
        }

        progress.value = progress.value.copyWith(
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          bytesPerSecond: bytesPerSecond,
        );
      }

      await sink.flush();
      await sink.close();

      if (!_isCanceled) {
        progress.value = progress.value.copyWith(
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          finished: true,
          bytesPerSecond: 0,
        );
      }
    } catch (e, s) {
      await sink?.close();

      await cancel();

      throw AppException(
        'Failed download',
        debugContext: 'Downloader',
        cause: e,
        stackTrace: s,
      );
    }
  }

  Future<void> cancel() async {
    _isCanceled = true;

    _client?.close(force: true);

    progress.value = progress.value.copyWith(
      canceled: true,
      finished: false,
      bytesPerSecond: 0,
    );
  }

  void dispose() {
    progress.dispose();

    _client?.close(force: true);
  }
}
