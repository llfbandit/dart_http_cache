import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:http_cache_core/http_cache_core.dart';

import 'http_cache_hive_adapters.dart';

/// Reads run concurrently; a write waits for all reads/writes to drain and
/// blocks new ones until done. Needed because hive_ce boxes never serialize
/// read-vs-write, only read-vs-read and write-vs-write.
class _RwLock {
  Future<void> _writeQueue = Future.value();
  int _activeReaders = 0;
  Completer<void>? _readersDrained;

  Future<T> read<T>(Future<T> Function() action) async {
    await _writeQueue;
    _activeReaders++;
    try {
      return await action();
    } finally {
      _activeReaders--;
      if (_activeReaders == 0) {
        _readersDrained?.complete();
        _readersDrained = null;
      }
    }
  }

  Future<T> write<T>(Future<T> Function() action) {
    final previous = _writeQueue;
    final completer = Completer<void>();
    _writeQueue = completer.future;
    return _runExclusive(action, previous, completer);
  }

  Future<T> _runExclusive<T>(
    Future<T> Function() action,
    Future<void> previous,
    Completer<void> completer,
  ) async {
    await previous;

    if (_activeReaders > 0) {
      await (_readersDrained ??= Completer<void>()).future;
    }

    try {
      return await action();
    } finally {
      completer.complete();
    }
  }
}

/// Abstract base class for Hive-based cache stores.
///
abstract class BaseHiveCacheStore extends CacheStore {
  /// Cache box name.
  final String hiveBoxName;

  /// Optional cipher to use directly with Hive.
  final HiveCipher? encryptionCipher;

  /// Home directory of the box.
  final String? directory;

  final _RwLock _lock = _RwLock();

  /// Opens the Hive box for cache storage.
  Future<HttpCacheHiveBox<CacheResponse>> openBox();

  /// Closes the Hive box.
  Future<void> closeBox();

  /// Registers the required adapters with the Hive instance.
  void registerAdapters();

  /// `clean` queues on [_lock] synchronously, so it's always the first
  /// writer in line and can't race a caller's first operation.
  BaseHiveCacheStore({
    this.directory,
    this.hiveBoxName = 'dio_cache',
    this.encryptionCipher,
  }) {
    registerAdapters();
    clean(staleOnly: true);
  }

  @override
  Future<void> close() {
    return _lock.write(closeBox);
  }

  /// Yields every non-null entry currently stored in [box].
  Stream<CacheResponse> _entries(HttpCacheHiveBox<CacheResponse> box) async* {
    final boxKeys = await box.keys;

    for (var i = 0; i < boxKeys.length; i++) {
      final resp = await box.getAt(i);
      if (resp != null) yield resp;
    }
  }

  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) {
    return _lock.write(
      () => _cleanImpl(priorityOrBelow: priorityOrBelow, staleOnly: staleOnly),
    );
  }

  Future<void> _cleanImpl({
    required CachePriority priorityOrBelow,
    required bool staleOnly,
  }) async {
    final box = await openBox();
    final keys = <String>[];

    await for (final resp in _entries(box)) {
      var shouldRemove = resp.priority.index <= priorityOrBelow.index;
      shouldRemove &= (staleOnly && resp.isStaled()) || !staleOnly;

      if (shouldRemove) {
        keys.add(resp.key);
      }
    }

    return box.deleteAll(keys);
  }

  @override
  Future<void> delete(String key, {bool staleOnly = false}) {
    return _lock.write(() => _deleteImpl(key, staleOnly: staleOnly));
  }

  Future<void> _deleteImpl(String key, {bool staleOnly = false}) async {
    final box = await openBox();

    if (staleOnly) {
      final resp = await box.get(key);
      if (resp == null || !resp.isStaled()) return;
    }

    await box.delete(key);
  }

  @override
  Future<void> deleteFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) {
    return _lock.write(
      () => _deleteFromPathImpl(pathPattern, queryParams: queryParams),
    );
  }

  Future<void> _deleteFromPathImpl(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {
    final responses = await _getFromPathImpl(
      pathPattern,
      queryParams: queryParams,
    );

    final box = await openBox();

    await box.deleteAll(responses.map((response) => response.key).toList());
  }

  @override
  Future<bool> exists(String key) {
    return _lock.read(() => _existsImpl(key));
  }

  Future<bool> _existsImpl(String key) async {
    final box = await openBox();
    return box.containsKey(key);
  }

  @override
  Future<CacheResponse?> get(String key) {
    return _lock.read(() => _getImpl(key));
  }

  Future<CacheResponse?> _getImpl(String key) async {
    final box = await openBox();
    return box.get(key);
  }

  @override
  Future<List<CacheResponse>> getFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) {
    return _lock.read(
      () => _getFromPathImpl(pathPattern, queryParams: queryParams),
    );
  }

  /// Unlocked: called directly from [_deleteFromPathImpl], which already
  /// holds the write lock.
  Future<List<CacheResponse>> _getFromPathImpl(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {
    final responses = <CacheResponse>[];
    final box = await openBox();

    await for (final resp in _entries(box)) {
      if (pathExists(resp.url, pathPattern, queryParams: queryParams)) {
        responses.add(resp);
      }
    }

    return responses;
  }

  @override
  Future<void> set(CacheResponse response) {
    return _lock.write(() => _setImpl(response));
  }

  Future<void> _setImpl(CacheResponse response) async {
    final box = await openBox();
    return box.put(response.key, response);
  }
}
