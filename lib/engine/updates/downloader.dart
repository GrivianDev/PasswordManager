import 'dart:async';
import 'dart:io';

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
  StreamSubscription<List<int>>? _subscription;

  bool _isCanceled = false;

  Future<void> startDownload(Uri url, File destination) async {
    _isCanceled = false;

    progress.value = DownloadProgress.initial();

    _client = HttpClient();
    final HttpClientRequest request = await _client!.getUrl(url);
    final HttpClientResponse response = await request.close();

    final int totalBytes = response.contentLength;

    final IOSink sink = destination.openWrite();

    int downloadedBytes = 0;

    final Stopwatch stopwatch = Stopwatch()..start();

    int lastBytes = 0;
    int lastMilliseconds = 0;

    final completer = Completer<void>();

    _subscription = response.listen(
      (chunk) {
        if (_isCanceled) {
          return;
        }

        sink.add(chunk);

        downloadedBytes += chunk.length;

        final nowMilliseconds = stopwatch.elapsedMilliseconds;

        double bytesPerSecond = 0;

        final elapsedDelta = nowMilliseconds - lastMilliseconds;

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
      },
      onDone: () async {
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

        completer.complete();
      },
      onError: (error, stackTrace) async {
        await sink.close();

        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  Future<void> cancel() async {
    _isCanceled = true;

    await _subscription?.cancel();

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
