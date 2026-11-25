/// Keeps one live listener per key for the life of the app and replays the
/// latest value to every new listener at once.
///
/// A page that is opened again (Earn, Coins, Earnings) used to subscribe a
/// fresh Firestore query each time and sit on a loader until the server
/// answered, or, with a plain broadcast stream, wait for the NEXT change and
/// never draw at all. With this the second visit draws from memory on its
/// first frame and keeps listening for changes.
library;

import 'dart:async';

class LiveCache {
  LiveCache._();

  static final _entries = <String, _Live<Object?>>{};

  /// The replaying stream for [key]; [open] runs once per key.
  static Stream<T> of<T>(String key, Stream<T> Function() open) {
    final e = _entries.putIfAbsent(key, () => _Live<T>(open)) as _Live<T>;
    return e.stream;
  }

  /// Last value seen for [key], for a StreamBuilder's initialData.
  static T? latest<T>(String key) {
    final e = _entries[key];
    return e == null ? null : e.last as T?;
  }

  static void debugClear() {
    for (final e in _entries.values) {
      e.close();
    }
    _entries.clear();
  }
}

class _Live<T> {
  _Live(this._open);
  final Stream<T> Function() _open;
  StreamSubscription<T>? _sub;
  final _out = StreamController<T>.broadcast();
  T? last;
  var _has = false;
  Object? _error;

  Stream<T> get stream {
    _sub ??= _open().listen((v) {
      last = v;
      _has = true;
      _error = null;
      _out.add(v);
    }, onError: (Object e, StackTrace s) {
      _error = e;
      _out.addError(e, s);
    });
    return Stream<T>.multi((c) {
      if (_has) {
        c.add(last as T);
      } else if (_error != null) {
        c.addError(_error!);
      }
      final s = _out.stream.listen(c.add, onError: c.addError, onDone: c.close);
      c.onCancel = s.cancel;
    });
  }

  void close() {
    unawaited(_sub?.cancel());
    unawaited(_out.close());
  }
}
