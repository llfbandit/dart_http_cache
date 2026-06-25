import 'dart:convert';

import 'package:http_cache_core/http_cache_core.dart';
import 'package:test/test.dart';

import 'http_cache_client_cache_call_mocks.dart';

void main() {
  late CacheStore store;
  late CacheOptions options;

  setUp(() async {
    store = MemCacheStore();
    await store.clean();
    options = CacheOptions(store: store);
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

    var resp = await getOk(cipherOptions);
    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);
    expect(jsonDecode(resp.body)['path'], equals('/ok'));

    resp = await getOk(cipherOptions);
    expect(await store.exists(key), isTrue);
    expect(jsonDecode(resp.body)['path'], equals('/ok'));
  });

  test('Fetch 200', () async {
    final resp = await getOk(options);

    expect(jsonDecode(resp.body)['path'], equals('/ok'));
    expect(resp.statusCode, equals(200));
    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);
  });

  test('Fetch 304', () async {
    final resp = await getOk(options);

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);
    final cacheResp1 = await store.get(key);
    expect(resp.headers[ageHeader], equals('1'));

    final resp304 = await getOk(options);
    expect(resp304.statusCode, equals(200));
    final cacheResp2 = await store.get(key);
    expect(resp304.headers[ageHeader], equals('10'));
    expect(cacheResp1, isNotNull);
    expect(cacheResp2, isNotNull);
    expect(cacheResp2!.eTag, equals('5678'));
    expect(cacheResp2.getHeaders()[ageHeader], equals('10'));
  });

  test('Fetch noCache policy', () async {
    final resp = await getOk(options.copyWith(policy: CachePolicy.noCache));
    expect(resp.statusCode, equals(200));
    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isFalse);
  });

  test('Fetch force policy', () async {
    // 1st time fetch
    var resp = await getOkNoDirective(
      options.copyWith(policy: CachePolicy.forceCache),
    );
    expect(resp.statusCode, equals(200));
    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);
    final cacheResp1 = await store.get(key);

    await Future.delayed(Duration(seconds: 1));

    // 2nd time cache
    resp = await getOkNoDirective(
      options.copyWith(policy: CachePolicy.forceCache),
    );
    expect(resp.statusCode, equals(200));
    final cacheResp2 = await store.get(key);
    expect(cacheResp1, equals(cacheResp2));
    expect(cacheResp1?.responseDate, equals(cacheResp2?.responseDate));

    await Future.delayed(Duration(seconds: 1));

    // 3rd time fetch
    resp = await getOkNoDirective(
      options.copyWith(policy: CachePolicy.refreshForceCache),
    );
    expect(resp.statusCode, equals(200));
    final cacheResp3 = await store.get(key);
    expect(cacheResp1?.requestDate, isNot(equals(cacheResp3?.requestDate)));
    expect(cacheResp1?.responseDate, isNot(equals(cacheResp3?.responseDate)));
  });

  test('Fetch refresh policy', () async {
    var resp = await getOk(options);

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);
    final cacheResp1 = await store.get(key);

    await Future.delayed(Duration(seconds: 1));

    resp = await getOk(options.copyWith(
      policy: CachePolicy.refresh,
      maxStale: Duration(minutes: 10),
    ));

    expect(resp.statusCode, equals(200));
    expect(await store.exists(key), isTrue);
    final cacheResp2 = await store.get(key);

    expect(cacheResp1!.date, isNot(equals(cacheResp2!.date)));
  });

  test('Fetch post skip request', () async {
    final resp = await postOk(options);

    expect(resp.statusCode, equals(200));
    expect(jsonDecode(resp.body)['path'], equals('/ok'));

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isFalse);
  });

  test('Fetch post doesn\'t skip request', () async {
    final resp = await postOk(options.copyWith(allowPostMethod: true));

    expect(resp.statusCode, equals(200));
    expect(jsonDecode(resp.body)['path'], equals('/ok'));

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);
  });

  test('Fetch hitCacheOnErrorCodes 500', () async {
    var resp = await getOk(options);

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);
    expect(resp.statusCode, equals(200));

    resp = await getOk(
      options.copyWith(hitCacheOnErrorCodes: []),
      headers: {'x-err': '500'},
    );
    expect(resp.statusCode, equals(500));

    resp = await getOk(
      options.copyWith(hitCacheOnErrorCodes: [], policy: CachePolicy.refresh),
      headers: {'x-err': '500'},
    );
    expect(resp.statusCode, equals(500));
  });

  test('Fetch hitCacheOnErrorCodes 500 valid', () async {
    var resp = await getOk(options);

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);

    resp = await getOk(
      options
          .copyWith(hitCacheOnErrorCodes: [500], policy: CachePolicy.refresh),
      headers: {'x-err': '500'},
    );

    expect(resp.statusCode, equals(200));
    expect(jsonDecode(resp.body)['path'], equals('/ok'));
  });

  test('Fetch hitCacheOnNetworkFailure valid', () async {
    var resp = await getException(options);

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);

    resp = await getException(
      options.copyWith(hitCacheOnNetworkFailure: true),
      headers: {'x-err': '500'},
    );

    expect(resp.statusCode, equals(200));
    expect(jsonDecode(resp.body)['path'], equals('/exception'));
  });

  test('Fetch Cache-Control', () async {
    final resp = await cacheControl(options);

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);
    final cacheResp1 = await store.get(key);

    await Future.delayed(Duration(seconds: 1));

    var resp304 = await cacheControl(options);
    expect(resp304.statusCode, equals(200));
    expect(await store.exists(key), isTrue);

    final cacheResp2 = await store.get(key);

    expect(cacheResp1?.expires, isNot(equals(cacheResp2?.expires)));
  });

  test('Fetch Cache-Control expired with etag', () async {
    final resp = await cacheControlExpired(options);

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);
    final cacheResp1 = await store.get(key);

    await Future.delayed(Duration(seconds: 1));

    var resp304 = await cacheControlExpired(options);
    expect(resp304.statusCode, equals(200));
    expect(await store.exists(key), isTrue);

    final cacheResp2 = await store.get(key);

    expect(cacheResp1, cacheResp2);
  });

  test('Fetch Cache-Control no-store', () async {
    final resp = await cacheControlNoStore(options);

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isFalse);
  });

  test('Fetch max-age', () async {
    final resp = await maxAge(options);

    final key = options.keyBuilder(url: resp.request!.url);
    final cacheResp = await store.get(key);
    expect(cacheResp, isNotNull);

    // We're before max-age: 1
    expect(cacheResp!.isExpired(CacheControl()), isFalse);
    // We're after max-age: 1
    await Future.delayed(const Duration(seconds: 1));
    expect(cacheResp.isExpired(CacheControl()), isTrue);
  });

  test('Skip downloads', () async {
    final resp = await download(options);
    expect(resp.statusCode, equals(200));

    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isFalse);
  });

  test('304 with evicted entry is passed through without storing', () async {
    final resp200 = await getOk(options);
    final key = options.keyBuilder(url: resp200.request!.url);
    expect(await store.exists(key), isTrue);

    // Evict the entry between requests.
    await store.delete(key);
    expect(await store.exists(key), isFalse);

    // Known etag triggers a 304 from the mock.
    final resp304 = await getOk(options, headers: {ifNoneMatchHeader: '1234'});
    expect(resp304.statusCode, equals(304));
    expect(await store.exists(key), isFalse);
  });

  test('custom keyBuilder: conditional headers are stripped from the key',
      () async {
    final customOptions = CacheOptions(
      store: store,
      keyBuilder:
          ({required Uri url, Map<String, String>? headers, Object? body}) =>
              '${url.path}:${headers?[ifNoneMatchHeader] ?? ''}',
    );

    // Cache miss — key is '/ok:'.
    final resp1 = await getOk(customOptions);
    expect(resp1.statusCode, equals(200));
    expect(await store.exists('/ok:'), isTrue);

    // Revalidation injects if-none-match; the key must stay '/ok:'.
    await getOk(customOptions);
    expect(await store.exists('/ok:'), isTrue);
    expect(await store.exists('/ok:1234'), isFalse);
    expect(await store.exists('/ok:5678'), isFalse);
  });

  test('repeated cache hits within half window do not rewrite the store',
      () async {
    final opts = CacheOptions(
      store: store,
      policy: CachePolicy.forceCache,
      maxStale: const Duration(minutes: 10),
    );

    await getOkNoDirective(opts);
    final key = opts.keyBuilder(url: Uri.http('ok.org', '/ok-nodirective'));
    final cache1 = await store.get(key);

    await Future.delayed(const Duration(milliseconds: 5));
    await getOkNoDirective(opts);
    await getOkNoDirective(opts);

    final cache2 = await store.get(key);
    expect(cache2!.maxStale, equals(cache1!.maxStale));
  });

  test('non-ClientException network error falls back to cache', () async {
    final failOptions = options.copyWith(hitCacheOnNetworkFailure: true);

    final resp = await getNonClientError(failOptions);
    final key = options.keyBuilder(url: resp.request!.url);
    expect(await store.exists(key), isTrue);

    final cached = await getNonClientError(failOptions, headers: {'x-err': '1'});
    expect(cached.statusCode, equals(200));
    expect(jsonDecode(cached.body)['path'], equals('/ok'));
  });
}
