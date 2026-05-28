/// Class for having just one running function accross repeated calls, while just marking it for rerun.
final class RerunTask {
  bool _running = false;
  bool _rerun = false;

  Future<void> run(Future<void> Function() task) async {
    if (_running) {
      _rerun = true;
      return;
    }

    _running = true;

    try {
      do {
        _rerun = false;
        await task();
      } while (_rerun);
    } finally {
      _running = false;
    }
  }
}
