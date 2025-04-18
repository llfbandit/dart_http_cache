import 'dart:async';
import 'dart:convert';

import 'package:http_cache_core/http_cache_core.dart';
import 'package:test/test.dart';

Future<void> addFooResponse(
  CacheStore store, {
  String key = 'foo',
  CacheControl? cacheControl,
  DateTime? expires,
  String? lastModified,
  List<int>? headers,
  DateTime? maxStale,
  String url = 'https://foo.com',
  CachePriority priority = CachePriority.normal,
}) {
  final resp = CacheResponse(
    cacheControl: cacheControl ?? CacheControl(),
    content: utf8.encode('foo'),
    date: DateTime.now(),
    eTag: 'an, etag',
    expires: expires,
    headers: headers,
    key: key,
    lastModified: lastModified,
    maxStale: maxStale,
    priority: priority,
    requestDate: DateTime.now().subtract(const Duration(milliseconds: 50)),
    responseDate: DateTime.now(),
    url: url,
    statusCode: 200,
  );

  return store.set(resp);
}

Future<void> emptyByDefault(CacheStore store) async {
  expect(await store.exists('foo'), isFalse);
  expect(await store.get('foo'), isNull);
}

Future<void> addItem(CacheStore store) async {
  await addFooResponse(store, priority: CachePriority.low);
  var resp = await store.get('foo');
  expect(resp?.priority, CachePriority.low);

  await addFooResponse(store, priority: CachePriority.normal);
  resp = await store.get('foo');
  expect(resp?.priority, CachePriority.normal);

  await addFooResponse(store, priority: CachePriority.high);
  resp = await store.get('foo');
  expect(resp?.priority, CachePriority.high);
}

Future<void> getItem(CacheStore store) async {
  final headers = utf8.encode(jsonEncode({
    contentTypeHeader: [jsonContentType]
  }));
  final cacheControl = CacheControl(maxAge: 10, privacy: 'public');
  final expires = DateTime.now();
  final lastModified = HttpDate.format(DateTime.now());

  await addFooResponse(
    store,
    maxStale: DateTime.now().add(const Duration(days: 1)),
    headers: headers,
    cacheControl: cacheControl,
    priority: CachePriority.high,
    expires: expires,
    lastModified: lastModified,
  );

  final resp = await store.get('foo');
  expect(resp, isNotNull);
  expect(resp?.key, equals('foo'));
  expect(resp?.url, equals('https://foo.com'));
  expect(resp?.eTag, equals('an, etag'));
  expect(resp?.lastModified, lastModified);
  expect(resp?.maxStale, isNotNull);
  expect(resp?.content, equals(utf8.encode('foo')));
  expect(resp?.headers, equals(headers));
  expect(resp?.priority, CachePriority.high);
  expect(resp?.cacheControl, equals(cacheControl));
  expect(resp?.statusCode, equals(200));
  expect(resp!.expires!.millisecondsSinceEpoch ~/ 1000,
      equals(expires.millisecondsSinceEpoch ~/ 1000));
}

Future<void> deleteItem(CacheStore store) async {
  await addFooResponse(store);
  expect(await store.exists('foo'), isTrue);

  await store.delete('foo');
  expect(await store.exists('foo'), isFalse);
  await store.delete('foo'); // check for non exception

  await addFooResponse(
    store,
    maxStale: DateTime.now().add(const Duration(days: 1)),
  );
  expect(await store.exists('foo'), isTrue);

  await store.delete('foo', staleOnly: true);
  expect(await store.exists('foo'), isTrue);
}

Future<void> clean(CacheStore store) async {
  await addFooResponse(
    store,
    key: 'not-stale',
    maxStale: DateTime.now().add(const Duration(days: 1)),
  );
  await addFooResponse(
    store,
    key: 'stale',
    maxStale: DateTime.now().subtract(const Duration(days: 1)),
  );

  expect(await store.exists('not-stale'), isTrue);
  expect(await store.exists('stale'), isTrue);

  await store.clean(priorityOrBelow: CachePriority.low);
  expect(await store.exists('not-stale'), isTrue);
  expect(await store.exists('stale'), isTrue);

  await store.clean(staleOnly: true);
  expect(await store.exists('not-stale'), isTrue);
  expect(await store.exists('stale'), isFalse);

  await store.clean();
  expect(await store.exists('not-stale'), isFalse);
  expect(await store.exists('stale'), isFalse);
}

Future<void> expires(CacheStore store) async {
  final now = DateTime.now();
  await addFooResponse(store, expires: DateTime.now());
  final resp = await store.get('foo');
  expect(
    resp!.expires!.subtract(
      Duration(
          milliseconds: resp.expires!.millisecond,
          microseconds: resp.expires!.microsecond),
    ),
    equals(
      now.subtract(
        Duration(milliseconds: now.millisecond, microseconds: now.microsecond),
      ),
    ),
  );
}

Future<void> lastModified(CacheStore store) async {
  final lastModified = 'Wed, 21 Oct 2015 07:28:00 GMT';

  await addFooResponse(store, lastModified: lastModified);
  final resp = await store.get('foo');
  expect(resp!.lastModified, equals(lastModified));
}

Future<void> concurrentAccess(CacheStore store) async {
  final lastModified = 'Wed, 21 Oct 2015 07:28:00 GMT';

  final completer = Completer();
  final max = 3000;

  for (var i = 1; i <= max; i++) {
    final key = i % 3 == 0 ? 'bar' : 'foo';
    addFooResponse(store, key: key, lastModified: lastModified).then(
      (value) {
        store.get(key).then(
          (resp) {
            if (i % 3 == 0) {
              store.exists(key).then((value) {
                if (i == max) completer.complete();
              });
            } else if (i % 4 == 0) {
              store.clean().then((value) {
                if (i == max) completer.complete();
              });
            } else if (i % 5 == 0) {
              store.delete(key).then((value) {
                if (i == max) completer.complete();
              });
            } else {
              if (i == max) completer.complete();
            }
          },
        );
      },
    );
  }

  await completer.future;
}

void pathExists(CacheStore store) {
  // Match regex with no query params
  expect(store.pathExists('/foo', RegExp('/foo')), isTrue);
  expect(store.pathExists('/foo', RegExp('/bar')), isFalse);

  // Match with null query params (matches all query params)
  expect(
    store.pathExists(
      Uri(
        path: '/foo',
        queryParameters: {'bar': 'foobar'},
      ).toString(),
      RegExp('/foo'),
      queryParams: null,
    ),
    isTrue,
  );

  // Match with null value query param (matches key with any value)
  expect(
    store.pathExists(
      Uri(
        path: '/foo',
        queryParameters: {'bar': 'foobar'},
      ).toString(),
      RegExp('/foo'),
      queryParams: {'bar': null},
    ),
    isTrue,
  );

  // Match with exact query params
  expect(
    store.pathExists(
      Uri(
        path: '/foo',
        queryParameters: {'bar': 'foobar'},
      ).toString(),
      RegExp('/foo'),
      queryParams: {'bar': 'foobar'},
    ),
    isTrue,
  );

  // No match on different query param value
  expect(
    store.pathExists(
      Uri(
        path: '/foo',
        queryParameters: {'bar': 'foobar'},
      ).toString(),
      RegExp('/foo'),
      queryParams: {'bar': 'baz'},
    ),
    isFalse,
  );

  // No match on query params with different values
  expect(
    store.pathExists(
      Uri(
        path: '/foo',
        queryParameters: {
          'bar': 'foo',
          'qux': 'bar',
        },
      ).toString(),
      RegExp('/foo'),
      queryParams: {
        'bar': 'foo',
        'qux': 'foo',
      },
    ),
    isFalse,
  );
}

Future<void> deleteFromPath(CacheStore store) async {
  await addFooResponse(store);
  expect(await store.exists('foo'), isTrue);
  await store.deleteFromPath(RegExp('https://foo.com'));
  expect(await store.exists('foo'), isFalse);

  await addFooResponse(store, url: 'https://foo.com?bar=bar');
  expect(await store.exists('foo'), isTrue);
  await store.deleteFromPath(
    RegExp('https://foo.com'),
    queryParams: {'bar': null},
  );
  expect(await store.exists('foo'), isFalse);

  await addFooResponse(store, url: 'https://foo.com?bar=bar');
  expect(await store.exists('foo'), isTrue);
  await store.deleteFromPath(
    RegExp('https://foo.com'),
    queryParams: {'bar': 'bar'},
  );
  expect(await store.exists('foo'), isFalse);

  await addFooResponse(store, url: 'https://foo.com?bar=bar');
  expect(await store.exists('foo'), isTrue);
  await store.deleteFromPath(
    RegExp('https://foo.com'),
    queryParams: {'bar': 'foobar'},
  );
  expect(await store.exists('foo'), isTrue);
}

Future<void> getFromPath(CacheStore store) async {
  await addFooResponse(store);
  var list = await store.getFromPath(RegExp('https://foo.com'));
  expect(list.length, 1);

  await addFooResponse(store, url: 'https://foo.com?bar=bar');
  list = await store.getFromPath(
    RegExp('https://foo.com'),
    queryParams: {'bar': null},
  );
  expect(list.length, 1);

  await addFooResponse(store, url: 'https://foo.com?bar=bar');
  list = await store.getFromPath(
    RegExp('https://foo.com'),
    queryParams: {'bar': 'bar'},
  );
  expect(list.length, 1);

  await addFooResponse(store, url: 'https://foo.com?bar=bar');
  list = await store.getFromPath(
    RegExp('https://foo.com'),
    queryParams: {'bar': 'foobar'},
  );
  expect(list.length, 0);
}
