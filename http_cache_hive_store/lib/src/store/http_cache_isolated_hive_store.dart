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
  Future<IsolatedLazyBox<CacheResponse>>? _opening;

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
  void registerAdapters() => registerHiveCacheAdapters(hive);

  @override
  Future<void> closeBox() async {
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

    final box = _box;
    if (box != null && box.isOpen) return IsolatedLazyBoxAdapter(box);

    return IsolatedLazyBoxAdapter(await (_opening ??= _open()));
  }

  /// Memoized so concurrent callers share one [IsolatedHiveInterface.openLazyBox]
  /// call instead of racing separate ones.
  Future<IsolatedLazyBox<CacheResponse>> _open() async {
    try {
      final box = await hive.openLazyBox<CacheResponse>(
        hiveBoxName,
        encryptionCipher: encryptionCipher,
        path: directory,
      );
      _box = box;
      return box;
    } finally {
      _opening = null;
    }
  }
}
