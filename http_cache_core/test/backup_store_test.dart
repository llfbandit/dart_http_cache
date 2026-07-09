import 'package:http_cache_core/http_cache_core.dart';
import 'package:http_cache_store_tester/common_store_testing.dart';
import 'package:test/test.dart';

CacheResponse _makeResponse(String key, String url, {DateTime? responseDate}) {
  return CacheResponse(
    cacheControl: CacheControl(),
    content: null,
    date: null,
    eTag: null,
    expires: null,
    headers: null,
    key: key,
    lastModified: null,
    maxStale: null,
    priority: CachePriority.normal,
    requestDate: DateTime.now(),
    responseDate: responseDate ?? DateTime.now(),
    url: url,
    statusCode: 200,
  );
}

void main() {
  late BackupCacheStore store;

  setUp(() async {
    store = BackupCacheStore(
      primary: MemCacheStore(),
      secondary: MemCacheStore(),
    );
    await store.clean();
  });

  tearDown(() async => await store.close());

  test('Empty by default', () async => await emptyByDefault(store));
  test('Add item', () async => await addItem(store));
  test('Get item', () async => await getItem(store));
  test('Delete item', () async => await deleteItem(store));
  test('Clean', () async => await clean(store));
  test('Expires', () async => await expires(store));
  test('LastModified', () async => await lastModified(store));
  test('pathExists', () => pathExists(store));
  test('deleteFromPath', () => deleteFromPath(store));
  test('getFromPath', () => getFromPath(store));
  test(
    'Concurrent access',
    () async => await concurrentAccess(store),
    timeout: Timeout(Duration(minutes: 2)),
  );

  test(
    'getFromPath deduplicates by key when primary and secondary both match',
    () async {
      final primary = MemCacheStore();
      final secondary = MemCacheStore();
      final url = 'https://example.com/resource';
      final primaryResponse = _makeResponse(
        'key1',
        url,
        responseDate: DateTime.now(),
      );
      final secondaryResponse = _makeResponse(
        'key1',
        url,
        responseDate: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await primary.set(primaryResponse);
      await secondary.set(secondaryResponse);

      final testStore = BackupCacheStore(
        primary: primary,
        secondary: secondary,
      );
      final results = await testStore.getFromPath(RegExp(r'example\.com'));

      expect(results, hasLength(1));
      expect(results.first.responseDate, equals(primaryResponse.responseDate));
    },
  );
}
