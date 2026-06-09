import 'dart:async';

enum AppLifecycleStateModel {
  ready,
  notReady,
}

class AppLifecycle {
  AppLifecycleStateModel _state = AppLifecycleStateModel.notReady;

  Completer<void>? _readyCompleter;

  AppLifecycle({bool initiallyReady = false}) {
    if (initiallyReady) {
      markReady();
    }
  }

  AppLifecycleStateModel get state => _state;

  bool get isReady => _state == AppLifecycleStateModel.ready;

  Future<void> waitUntilReady() {
    if (_state == AppLifecycleStateModel.ready) {
      return Future.value();
    }

    _readyCompleter ??= Completer<void>();
    return _readyCompleter!.future;
  }

  void markReady() {
    _state = AppLifecycleStateModel.ready;

    if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
      _readyCompleter!.complete();
    }
    _readyCompleter = null;
  }

  void markNotReady() {
    _state = AppLifecycleStateModel.notReady;
    _readyCompleter ??= Completer<void>();
  }
}