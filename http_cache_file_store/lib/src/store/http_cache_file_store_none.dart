import 'package:http_cache_core/http_cache_core.dart';

class FileCacheStore extends CacheStore {
  FileCacheStore(String directory);

  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) {
    return Future.value();
  }

  @override
  Future<void> close() {
    return Future.value();
  }

  @override
  Future<void> delete(String key, {bool staleOnly = false}) {
    return Future.value();
  }

  @override
  Future<bool> exists(String key) {
    return Future.value(false);
  }

  @override
  Future<CacheResponse?> get(String key) {
    return Future.value();
  }

  @override
  Future<void> set(CacheResponse response) {
    return Future.value();
  }

  @override
  Future<void> deleteFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) {
    return Future.value();
  }

  @override
  Future<List<CacheResponse>> getFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) {
    return Future.value([]);
  }
}
