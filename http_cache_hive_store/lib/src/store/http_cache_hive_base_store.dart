import 'package:hive_ce/hive.dart';
import 'package:http_cache_core/http_cache_core.dart';

import 'http_cache_hive_adapters.dart';

/// Abstract base class for Hive-based cache stores.
///
abstract class BaseHiveCacheStore extends CacheStore {
  /// Cache box name.
  final String hiveBoxName;

  /// Optional cipher to use directly with Hive.
  final HiveCipher? encryptionCipher;

  /// Home directory of the box.
  final String? directory;

  /// Opens the Hive box for cache storage.
  Future<HttpCacheHiveBox<CacheResponse>> openBox();

  /// Registers the required adapters with the Hive instance.
  void registerAdapters();

  /// Base constructor that registers adapters and cleans stale entries.
  BaseHiveCacheStore({
    this.directory,
    this.hiveBoxName = 'dio_cache',
    this.encryptionCipher,
  }) {
    registerAdapters();
    clean(staleOnly: true);
  }

  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) async {
    final box = await openBox();
    final boxKeys = await box.keys;

    final keys = <String>[];

    for (var i = 0; i < boxKeys.length; i++) {
      final resp = await box.getAt(i);

      if (resp != null) {
        var shouldRemove = resp.priority.index <= priorityOrBelow.index;
        shouldRemove &= (staleOnly && resp.isStaled()) || !staleOnly;

        if (shouldRemove) {
          keys.add(resp.key);
        }
      }
    }

    return box.deleteAll(keys);
  }

  @override
  Future<void> delete(String key, {bool staleOnly = false}) async {
    final box = await openBox();
    final resp = await box.get(key);
    if (resp == null) return Future.value();

    if (staleOnly && !resp.isStaled()) {
      return Future.value();
    }

    await box.delete(key);
  }

  @override
  Future<void> deleteFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {
    final responses = await getFromPath(pathPattern, queryParams: queryParams);

    final box = await openBox();

    for (final response in responses) {
      await box.delete(response.key);
    }
  }

  @override
  Future<bool> exists(String key) async {
    final box = await openBox();
    return box.containsKey(key);
  }

  @override
  Future<CacheResponse?> get(String key) async {
    final box = await openBox();
    return box.get(key);
  }

  @override
  Future<List<CacheResponse>> getFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {
    final responses = <CacheResponse>[];

    final box = await openBox();
    final boxKeys = await box.keys;

    for (var i = 0; i < boxKeys.length; i++) {
      final resp = await box.getAt(i);

      if (resp != null) {
        if (pathExists(resp.url, pathPattern, queryParams: queryParams)) {
          responses.add(resp);
        }
      }
    }

    return responses;
  }

  @override
  Future<void> set(CacheResponse response) async {
    final box = await openBox();
    return box.put(response.key, response);
  }
}
