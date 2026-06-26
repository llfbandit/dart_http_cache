import 'package:hive_ce/hive.dart';
import 'package:http_cache_core/http_cache_core.dart';

import 'http_cache_hive_adapters.dart';
import 'http_cache_hive_base_store.dart';

/// A store saving responses using hive.
///
class HiveCacheStore extends BaseHiveCacheStore {
  /// The Hive instance to use.
  final HiveInterface hive;

  LazyBox<CacheResponse>? _box;

  /// Initialize cache store by giving Hive a home directory.
  /// [directory] can be null only on web platform or if you already use Hive
  /// in your app.
  ///
  /// [hiveInterface] is the Hive instance to use.
  /// If not provided, the default [Hive] implementation will be used.
  HiveCacheStore(
    String? directory, {
    super.hiveBoxName,
    super.encryptionCipher,
    HiveInterface? hiveInterface,
  }) : hive = hiveInterface ?? Hive,
       super(directory: directory);

  @override
  void registerAdapters() {
    if (!hive.isAdapterRegistered(CacheResponseAdapter.id)) {
      hive.registerAdapter(CacheResponseAdapter());
    }
    if (!hive.isAdapterRegistered(CacheControlAdapter.id)) {
      hive.registerAdapter(CacheControlAdapter());
    }
    if (!hive.isAdapterRegistered(CachePriorityAdapter.id)) {
      hive.registerAdapter(CachePriorityAdapter());
    }
  }

  @override
  Future<void> close() async {
    if (_box case final box? when box.isOpen) {
      _box = null;
      return box.close();
    }
  }

  @override
  Future<HttpCacheHiveBox<CacheResponse>> openBox() async {
    _box ??= await hive.openLazyBox<CacheResponse>(
      hiveBoxName,
      encryptionCipher: encryptionCipher,
      path: directory,
    );

    return LazyBoxAdapter(_box!);
  }
}
