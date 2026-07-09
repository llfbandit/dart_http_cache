import 'package:hive_ce/hive.dart';
import 'package:http_cache_core/http_cache_core.dart';

import 'http_cache_hive_adapters.dart';
import 'http_cache_hive_base_store.dart';

/// A store saving responses using isolated hive.
///
class IsolatedHiveCacheStore extends BaseHiveCacheStore {
  /// The Isolated Hive instance to use.
  final IsolatedHiveInterface hive;

  /// Whether we own [hive] (default singleton) vs. caller supplied.
  final bool _ownsHive;

  IsolatedLazyBox<CacheResponse>? _box;
  Future<void>? _initFuture;

  /// Initialize cache store by giving Hive a home directory.
  /// [directory] can be null only on web platform or if you already use Hive
  /// in your app.
  ///
  /// [hiveInterface] is the Isolated Hive instance to use.
  /// If not provided, the default [IsolatedHive] implementation will be used
  /// and initialized automatically. If provided, it must already be
  /// initialized (via `init()`) by the caller.
  IsolatedHiveCacheStore(
    String? directory, {
    super.hiveBoxName,
    super.encryptionCipher,
    IsolatedHiveInterface? hiveInterface,
  }) : hive = hiveInterface ?? IsolatedHive,
       _ownsHive = hiveInterface == null,
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
    final box = _box;
    _box = null;
    if (box != null && box.isOpen) {
      return box.close();
    }
  }

  @override
  Future<HttpCacheHiveBox<CacheResponse>> openBox() async {
    if (_ownsHive) {
      await (_initFuture ??= hive.init(directory));
    }

    if (_box == null || !_box!.isOpen) {
      _box = await hive.openLazyBox<CacheResponse>(
        hiveBoxName,
        encryptionCipher: encryptionCipher,
        path: directory,
      );
    }

    return IsolatedLazyBoxAdapter(_box!);
  }
}
