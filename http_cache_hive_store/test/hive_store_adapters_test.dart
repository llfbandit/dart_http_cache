import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:http_cache_core/http_cache_core.dart';
import 'package:http_cache_hive_store/src/store/http_cache_hive_adapters.dart';
import 'package:test/test.dart';

void main() {
  final dirPath = '${Directory.current.path}/test/data/adapters_store';

  setUpAll(() async {
    // Adapter registration must be idempotent: constructing several stores
    // (or calling this twice) against the same registry must not throw.
    registerHiveCacheAdapters(Hive);
    registerHiveCacheAdapters(Hive);

    await IsolatedHive.init(dirPath);
    registerHiveCacheAdapters(IsolatedHive);
    registerHiveCacheAdapters(IsolatedHive);
  });

  group('LazyBoxAdapter', () {
    test('exposes isOpen/close and delegates box operations', () async {
      final box = await Hive.openLazyBox<CacheResponse>(
        'lazy_box_adapter_test',
        path: dirPath,
      );
      final adapter = LazyBoxAdapter<CacheResponse>(box);

      expect(adapter.isOpen, isTrue);
      expect(await adapter.keys, isEmpty);
      expect(await adapter.containsKey('foo'), isFalse);
      expect(await adapter.get('foo'), isNull);

      await adapter.put('foo', _fooResponse());
      expect(await adapter.containsKey('foo'), isTrue);
      expect((await adapter.get('foo'))?.key, 'foo');
      expect((await adapter.getAt(0))?.key, 'foo');
      expect(await adapter.keys, ['foo']);

      await adapter.delete('foo');
      expect(await adapter.containsKey('foo'), isFalse);

      await adapter.put('foo', _fooResponse());
      await adapter.deleteAll(['foo']);
      expect(await adapter.containsKey('foo'), isFalse);

      await adapter.close();
      expect(adapter.isOpen, isFalse);
      expect(box.isOpen, isFalse);
    });
  });

  group('IsolatedLazyBoxAdapter', () {
    test('exposes isOpen/close and delegates box operations', () async {
      final box = await IsolatedHive.openLazyBox<CacheResponse>(
        'isolated_lazy_box_adapter_test',
        path: dirPath,
      );
      final adapter = IsolatedLazyBoxAdapter<CacheResponse>(box);

      expect(adapter.isOpen, isTrue);
      expect(await adapter.keys, isEmpty);
      expect(await adapter.containsKey('foo'), isFalse);
      expect(await adapter.get('foo'), isNull);

      await adapter.put('foo', _fooResponse());
      expect(await adapter.containsKey('foo'), isTrue);
      expect((await adapter.get('foo'))?.key, 'foo');
      expect((await adapter.getAt(0))?.key, 'foo');
      expect(await adapter.keys, ['foo']);

      await adapter.delete('foo');
      expect(await adapter.containsKey('foo'), isFalse);

      await adapter.put('foo', _fooResponse());
      await adapter.deleteAll(['foo']);
      expect(await adapter.containsKey('foo'), isFalse);

      await adapter.close();
      expect(adapter.isOpen, isFalse);
      expect(box.isOpen, isFalse);
    });
  });

  group('CacheControlAdapter', () {
    // Regression test for entries persisted before the "other" field existed:
    // the field map simply lacks key 4, so `fields[4]` is null.
    test(
      'defaults "other" to an empty list for older, pre-"other" entries',
      () {
        final control = CacheControlAdapter().read(
          _FakeBinaryReader(
            bytes: [7, 0, 1, 2, 3, 5, 6, 7],
            values: [10, 'public', false, false, -1, -1, false],
          ),
        );

        expect(control.other, isEmpty);
        expect(control.maxAge, 10);
        expect(control.privacy, 'public');
        expect(control.noCache, isFalse);
        expect(control.noStore, isFalse);
        expect(control.mustRevalidate, isFalse);
      },
    );
  });

  group('CachePriorityAdapter', () {
    test('defaults to normal for an unrecognized stored byte', () {
      final priority = CachePriorityAdapter().read(
        _FakeBinaryReader(bytes: [42], values: []),
      );
      expect(priority, CachePriority.normal);
    });
  });
}

CacheResponse _fooResponse() => CacheResponse(
  cacheControl: CacheControl(),
  content: null,
  date: null,
  eTag: null,
  expires: null,
  headers: null,
  key: 'foo',
  lastModified: null,
  maxStale: null,
  priority: CachePriority.normal,
  requestDate: DateTime.now(),
  responseDate: DateTime.now(),
  url: 'https://foo.com',
  statusCode: 200,
);

/// Minimal [BinaryReader] fake driving a fixed sequence of [readByte] and
/// [read] results, in the exact order the adapters under test call them.
class _FakeBinaryReader implements BinaryReader {
  _FakeBinaryReader({required List<int> bytes, required List<dynamic> values})
    : _bytes = bytes,
      _values = values;

  final List<int> _bytes;
  final List<dynamic> _values;
  int _byteIndex = 0;
  int _valueIndex = 0;

  @override
  int readByte() => _bytes[_byteIndex++];

  @override
  dynamic read([int? typeId]) => _values[_valueIndex++];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
