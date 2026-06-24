import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:test/test.dart';

import 'mock_httpclient_adapter.dart';

void main() {
  late Dio dio;
  late CacheStore store;
  late CacheOptions options;

  setUp(() async {
    dio = Dio(
      BaseOptions(
        sendTimeout: Duration(seconds: 2),
        connectTimeout: Duration(seconds: 2),
        receiveTimeout: Duration(seconds: 2),
      ),
    )..httpClientAdapter = MockHttpClientAdapter();

    store = MemCacheStore();
    await store.clean();
    options = CacheOptions(store: store);

    dio.interceptors.add(DioCacheInterceptor(options: options));
  });

  tearDown(() async {
    dio.close();
  });

  test('Fetch stream 200', () async {
    final resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok-stream',
      options: Options(responseType: ResponseType.stream),
    );
    expect(await store.exists(resp.extra[extraCacheKey] ?? ''), isFalse);
  });

  test('Fetch canceled', () async {
    try {
      await dio.get(
        '${MockHttpClientAdapter.mockBase}/ok',
        cancelToken: CancelToken()..cancel(),
      );
    } catch (err) {
      expect(err is DioException, isTrue);
      expect((err as DioException).type == DioExceptionType.cancel, isTrue);
      return;
    }

    expect(false, isTrue, reason: 'Should never reach this check');
  });

  test('Fetch with cipher', () async {
    final cipherOptions = options.copyWith(
      cipher: CacheCipher(
        decrypt: (bytes) =>
            Future.value(bytes.reversed.toList(growable: false)),
        encrypt: (bytes) =>
            Future.value(bytes.reversed.toList(growable: false)),
      ),
    );

    var resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok',
      options: cipherOptions.toOptions(),
    );
    expect(await store.exists(resp.extra[extraCacheKey]), isTrue);
    expect(resp.data['path'], equals('/ok'));

    resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok',
      options: cipherOptions.toOptions(),
    );
    expect(await store.exists(resp.extra[extraCacheKey]), isTrue);
    expect(resp.data['path'], equals('/ok'));
  });

  test('Fetch 200', () async {
    final resp = await dio.get('${MockHttpClientAdapter.mockBase}/ok');
    expect(resp.data['path'], equals('/ok'));
    expect(await store.exists(resp.extra[extraCacheKey]), isTrue);
  });

  test('Fetch bytes 200', () async {
    final resp = await dio.get('${MockHttpClientAdapter.mockBase}/ok-bytes');
    expect(await store.exists(resp.extra[extraCacheKey]), isTrue);
  });

  test('Fetch 304', () async {
    final resp = await dio.get('${MockHttpClientAdapter.mockBase}/ok');
    final key = resp.extra[extraCacheKey];
    expect(await store.exists(key), isTrue);
    expect(resp.headers[ageHeader], equals(['1']));

    var resp304 = await dio.get('${MockHttpClientAdapter.mockBase}/ok');
    expect(resp304.statusCode, equals(200));
    expect(resp.data['path'], equals('/ok'));
    expect(resp304.extra[extraCacheKey], equals(key));
    expect(resp304.extra[extraFromNetworkKey], isTrue);
    expect(resp304.headers[ageHeader], equals(['10']));
    expect(resp304.headers['etag'], equals(['5678']));
  });

  test('Fetch cacheStoreNo policy', () async {
    final resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok',
      options: options.copyWith(policy: CachePolicy.noCache).toOptions(),
    );
    expect(resp.statusCode, equals(200));
    expect(resp.extra[extraCacheKey], isNull);
  });

  test('Fetch force policy', () async {
    // 1st time fetch
    var resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok-nodirective',
      options: options.copyWith(policy: CachePolicy.forceCache).toOptions(),
    );
    expect(resp.statusCode, equals(200));
    expect(resp.extra[extraFromNetworkKey], isTrue);
    // 2nd time cache
    resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok-nodirective',
      options: options.copyWith(policy: CachePolicy.forceCache).toOptions(),
    );
    expect(resp.statusCode, equals(200));
    expect(resp.extra[extraFromNetworkKey], isFalse);
    // 3rd time fetch
    resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok-nodirective',
      options: options
          .copyWith(policy: CachePolicy.refreshForceCache)
          .toOptions(),
    );
    expect(resp.statusCode, equals(200));
    expect(resp.extra[extraFromNetworkKey], isTrue);
  });

  test('Fetch refresh policy', () async {
    final resp = await dio.get('${MockHttpClientAdapter.mockBase}/ok');
    final key = resp.extra[extraCacheKey];
    expect(await store.exists(key), isTrue);

    final resp200 = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok',
      options: options
          .copyWith(
            policy: CachePolicy.refresh,
            maxStale: Duration(minutes: 10),
          )
          .toOptions(),
    );
    expect(resp200.statusCode, equals(200));
    expect(resp.data['path'], equals('/ok'));
  });

  test('Fetch post skip request', () async {
    final resp = await dio.post('${MockHttpClientAdapter.mockBase}/post');
    expect(resp.statusCode, equals(200));
    expect(resp.data['path'], equals('/post'));
    expect(resp.extra[extraCacheKey], isNull);
  });

  test('Fetch post doesn\'t skip request', () async {
    final resp = await dio.post(
      '${MockHttpClientAdapter.mockBase}/post',
      options: Options(
        extra: options.copyWith(allowPostMethod: true).toExtra(),
      ),
    );

    expect(resp.statusCode, equals(200));
    expect(resp.data['path'], equals('/post'));
    expect(resp.extra[extraCacheKey], isNotNull);
  });

  test('Fetch hitCacheOnErrorCodes 500', () async {
    var resp = await dio.get('${MockHttpClientAdapter.mockBase}/ok');
    final key = resp.extra[extraCacheKey];
    expect(await store.exists(key), isTrue);
    expect(resp.statusCode, equals(200));

    try {
      resp = await dio.get(
        '${MockHttpClientAdapter.mockBase}/ok',
        options: Options(
          extra:
              options
                  .copyWith(
                    hitCacheOnErrorCodes: [],
                    policy: CachePolicy.refresh,
                  )
                  .toExtra()
                ..addAll({'x-err': '500'}),
        ),
      );
    } catch (err) {
      expect((err as DioException).response?.statusCode, equals(500));
    }

    try {
      resp = await dio.get(
        '${MockHttpClientAdapter.mockBase}/ok',
        options: Options(
          extra:
              options
                  .copyWith(
                    hitCacheOnErrorCodes: [],
                    policy: CachePolicy.refresh,
                  )
                  .toExtra()
                ..addAll({'x-err': '500'}),
        ),
      );
    } catch (err) {
      expect((err as DioException).response?.statusCode, equals(500));
      return;
    }

    expect(false, isTrue, reason: 'Should never reach this check');
  });

  test('Fetch hitCacheOnErrorCodes 500 valid', () async {
    final resp = await dio.get('${MockHttpClientAdapter.mockBase}/ok');
    final key = resp.extra[extraCacheKey];
    expect(await store.exists(key), isTrue);
    expect(resp.statusCode, equals(200));

    final resp2 = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok',
      options: Options(
        extra:
            options
                .copyWith(
                  hitCacheOnErrorCodes: [500],
                  policy: CachePolicy.refresh,
                )
                .toExtra()
              ..addAll({'x-err': '500'}),
      ),
    );

    expect(resp2.statusCode, equals(200));
    expect(resp2.data['path'], equals('/ok'));
  });

  test('Fetch hitCacheOnNetworkFailure valid', () async {
    final resp = await dio.get('${MockHttpClientAdapter.mockBase}/exception');
    final key = resp.extra[extraCacheKey];
    expect(await store.exists(key), isTrue);

    final resp2 = await dio.get(
      '${MockHttpClientAdapter.mockBase}/exception',
      options: Options(
        extra: options.copyWith(hitCacheOnNetworkFailure: true).toExtra()
          ..addAll({'x-err': '500'}),
      ),
    );

    expect(resp2.statusCode, equals(200));
    expect(resp2.data['path'], equals('/exception'));
  });

  test('Fetch Cache-Control', () async {
    final resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/cache-control',
    );
    var key = resp.extra[extraCacheKey];
    expect(await store.exists(key), isTrue);

    var resp304 = await dio.get(
      '${MockHttpClientAdapter.mockBase}/cache-control',
    );
    expect(resp304.statusCode, equals(200));
    expect(resp304.extra[extraCacheKey], equals(key));
    expect(resp304.extra[extraFromNetworkKey], isTrue);
  });

  test('Fetch Cache-Control expired with etag', () async {
    final resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/cache-control-expired',
    );
    var key = resp.extra[extraCacheKey];
    expect(await store.exists(key), isTrue);

    final resp304 = await dio.get(
      '${MockHttpClientAdapter.mockBase}/cache-control-expired',
    );
    expect(resp304.statusCode, equals(200));
    key = resp304.extra[extraCacheKey];
    expect(await store.exists(key), isTrue);
    expect(resp304.extra[extraFromNetworkKey], isTrue);
  });

  test('Fetch Cache-Control no-store', () async {
    final resp = await dio.get(
      '${MockHttpClientAdapter.mockBase}/cache-control-no-store',
    );
    final key = resp.extra[extraCacheKey];
    expect(key, isNull);
  });

  test('Fetch max-age', () async {
    final resp = await dio.get('${MockHttpClientAdapter.mockBase}/max-age');
    final key = resp.extra[extraCacheKey];
    final cacheResp = await store.get(key);
    expect(cacheResp, isNotNull);

    // We're before max-age: 1
    expect(cacheResp!.isExpired(CacheControl()), isFalse);
    // We're after max-age: 1
    await Future.delayed(const Duration(seconds: 1));
    expect(cacheResp.isExpired(CacheControl()), isTrue);
  });

  test('Skip downloads', () async {
    final resp = await dio.get('${MockHttpClientAdapter.mockBase}/download');
    final key = resp.extra[extraCacheKey];
    expect(key, isNull);
  });

  test(
    'Fetch 304 with evicted cache entry is passed through without storing',
    () async {
      // Prime the cache so we know the etag.
      final resp200 = await dio.get('${MockHttpClientAdapter.mockBase}/ok');
      final key = resp200.extra[extraCacheKey] as String;
      expect(await store.exists(key), isTrue);

      // Simulate eviction of the entry after onRequest but before onResponse.
      await store.delete(key);
      expect(await store.exists(key), isFalse);

      // Re-request with the known etag; the mock returns 304.
      // validateStatus routes the 304 through onResponse rather than onError.
      final resp304 = await dio.get(
        '${MockHttpClientAdapter.mockBase}/ok',
        options: Options(
          validateStatus: (s) => s == 304,
          headers: {'if-none-match': resp200.headers['etag']!.first},
        ),
      );

      // 304 is passed through as-is — no broken entry stored.
      expect(resp304.statusCode, equals(304));
      expect(resp304.extra[extraCacheKey], isNull);
      expect(await store.exists(key), isFalse);
    },
  );

  test('Fetch 304 handle in response flow', () async {
    final resp = await dio.get('${MockHttpClientAdapter.mockBase}/ok');
    final key = resp.extra[extraCacheKey];
    expect(await store.exists(key), isTrue);

    expect(resp.headers['etag'], ['1234']);

    final resp304 = await dio.get(
      '${MockHttpClientAdapter.mockBase}/ok',
      options: Options(validateStatus: (status) => status == 304),
    );

    expect(resp304.statusCode, equals(200));
    expect(resp304.extra[extraCacheKey], equals(key));
    expect(resp304.extra[extraFromNetworkKey], isTrue);

    final cacheResp = await store.get(key);
    expect(
      cacheResp?.content,
      equals(Uint8List.fromList('{"path":"/ok"}'.codeUnits)),
    );
    expect(cacheResp?.eTag, equals('5678'));
  });

  test(
    'toCacheResponse does not crash when extraRequestSentDateKey is absent',
    () async {
      // Simulates DioCacheInterceptor.onRequest being bypassed.
      final request = RequestOptions(
        path: '${MockHttpClientAdapter.mockBase}/ok',
      );
      // extraRequestSentDateKey is intentionally absent from request.extra.
      expect(request.extra.containsKey(extraRequestSentDateKey), isFalse);

      final response = Response<dynamic>(
        data: {'path': '/ok'},
        statusCode: 200,
        requestOptions: request,
        headers: Headers.fromMap({
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'etag': ['1234'],
        }),
      );

      final cacheResp = await response.toCacheResponse(
        key: 'test_key',
        options: CacheOptions(store: MemCacheStore()),
      );

      expect(cacheResp.requestDate, isNotNull);
    },
  );

  test(
    'repeated cache hits with maxStale do not write to the store on every hit',
    () async {
      final countingStore = _CountingStore(MemCacheStore());

      dio.interceptors.clear();
      dio.interceptors.add(
        DioCacheInterceptor(
          options: CacheOptions(
            store: countingStore,
            policy: CachePolicy.forceCache,
            maxStale: const Duration(minutes: 10),
          ),
        ),
      );

      // First request: cache miss — network fetch + _saveResponse stores entry.
      await dio.get('${MockHttpClientAdapter.mockBase}/ok');
      final writesAfterPrime = countingStore.setCount;

      // Subsequent cache hits within the half-window (5 min) must not write.
      await dio.get('${MockHttpClientAdapter.mockBase}/ok');
      await dio.get('${MockHttpClientAdapter.mockBase}/ok');

      expect(
        countingStore.setCount,
        equals(writesAfterPrime),
        reason:
            'no store write expected while maxStale is still >half-window away',
      );
    },
  );

  group('store exception handling', () {
    test(
      'store.get() throwing in onRequest rejects with DioException',
      () async {
        dio.interceptors.clear();
        dio.interceptors.add(
          DioCacheInterceptor(
            options: CacheOptions(store: _ThrowingOnGetStore()),
          ),
        );

        expect(
          () => dio.get('${MockHttpClientAdapter.mockBase}/ok'),
          throwsA(isA<DioException>()),
        );
      },
    );

    test(
      'store.set() throwing in onResponse rejects with DioException',
      () async {
        dio.interceptors.clear();
        dio.interceptors.add(
          DioCacheInterceptor(
            options: CacheOptions(store: _ThrowingOnSetStore()),
          ),
        );

        expect(
          () => dio.get('${MockHttpClientAdapter.mockBase}/ok'),
          throwsA(isA<DioException>()),
        );
      },
    );

    test(
      'store.get() throwing in onError does not hang — completes with DioException',
      () async {
        dio.interceptors.clear();
        dio.interceptors.add(
          DioCacheInterceptor(
            options: CacheOptions(
              store: _ThrowingOnGetStore(),
              hitCacheOnNetworkFailure: true,
            ),
          ),
        );

        // Must complete (not hang) and produce a DioException.
        expect(
          () => dio.get(
            '${MockHttpClientAdapter.mockBase}/exception',
            options: Options(extra: {'x-err': '500'}),
          ),
          throwsA(isA<DioException>()),
        );
      },
    );
  });
}

/// Store that delegates to [_inner] and counts [set] calls.
class _CountingStore implements CacheStore {
  _CountingStore(this._inner);

  final CacheStore _inner;
  int setCount = 0;

  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) => _inner.clean(priorityOrBelow: priorityOrBelow, staleOnly: staleOnly);

  @override
  Future<void> close() => _inner.close();

  @override
  Future<void> delete(String key, {bool staleOnly = false}) =>
      _inner.delete(key, staleOnly: staleOnly);

  @override
  Future<bool> exists(String key) => _inner.exists(key);

  @override
  Future<CacheResponse?> get(String key) => _inner.get(key);

  @override
  Future<void> set(CacheResponse response) {
    setCount++;
    return _inner.set(response);
  }

  @override
  Future<List<CacheResponse>> getFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) => _inner.getFromPath(pathPattern, queryParams: queryParams);

  @override
  Future<void> deleteFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) => _inner.deleteFromPath(pathPattern, queryParams: queryParams);

  @override
  bool pathExists(
    String url,
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) => _inner.pathExists(url, pathPattern, queryParams: queryParams);
}

/// Store that throws on [get] to simulate read failures.
class _ThrowingOnGetStore implements CacheStore {
  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> delete(String key, {bool staleOnly = false}) async {}

  @override
  Future<bool> exists(String key) async => false;

  @override
  Future<CacheResponse?> get(String key) =>
      Future.error(Exception('Store read failure'));

  @override
  Future<void> set(CacheResponse response) async {}

  @override
  Future<List<CacheResponse>> getFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async => [];

  @override
  Future<void> deleteFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {}

  @override
  bool pathExists(
    String url,
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) => false;
}

/// Store that throws on [set] to simulate write failures (reads succeed with null).
class _ThrowingOnSetStore implements CacheStore {
  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> delete(String key, {bool staleOnly = false}) async {}

  @override
  Future<bool> exists(String key) async => false;

  @override
  Future<CacheResponse?> get(String key) async => null;

  @override
  Future<void> set(CacheResponse response) =>
      Future.error(Exception('Store write failure'));

  @override
  Future<List<CacheResponse>> getFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async => [];

  @override
  Future<void> deleteFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async {}

  @override
  bool pathExists(
    String url,
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) => false;
}
