import 'dart:convert';
import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'package:http_cache_store_tester/common_store_testing.dart';
import 'package:test/test.dart';

void main() {
  final dirPath = '${Directory.current.path}/test/data/file_store';

  group('hive', () {
    late HiveCacheStore store;

    setUpAll(() {
      store = HiveCacheStore(dirPath);
    });

    setUp(() async {
      await store.clean();
    });

    tearDownAll(() async {
      await store.close();
    });

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

    test('close() can be called repeatedly without throwing', () async {
      await store.close();
      await store.close();
    });

    test(
      'recovers when the underlying box is closed by another store instance',
      () async {
        const boxName = 'shared_box_recovery';
        final storeA = HiveCacheStore(dirPath, hiveBoxName: boxName);
        final storeB = HiveCacheStore(dirPath, hiveBoxName: boxName);

        await addFooResponse(storeA);
        expect(await storeA.exists('foo'), isTrue);

        // storeB closes the box it shares with storeA behind its back.
        await storeB.close();

        // storeA must transparently reopen the box instead of throwing.
        expect(await storeA.exists('foo'), isTrue);
        await addFooResponse(storeA, key: 'bar');
        expect(await storeA.exists('bar'), isTrue);
      },
    );

    test('isolates data by hiveBoxName within the same directory', () async {
      final storeA = HiveCacheStore(dirPath, hiveBoxName: 'box_a');
      final storeB = HiveCacheStore(dirPath, hiveBoxName: 'box_b');

      await addFooResponse(storeA);
      expect(await storeA.exists('foo'), isTrue);
      expect(await storeB.exists('foo'), isFalse);
    });

    test('round-trips data through an encryption cipher', () async {
      final cipher = HiveAesCipher(List<int>.generate(32, (i) => i));
      final encryptedStore = HiveCacheStore(
        dirPath,
        hiveBoxName: 'encrypted_box',
        encryptionCipher: cipher,
      );

      await addFooResponse(encryptedStore);
      final resp = await encryptedStore.get('foo');
      expect(resp?.key, 'foo');
      expect(resp?.content, utf8.encode('fooéèàç'));
    });

    test('accepts an externally supplied HiveInterface', () async {
      final customStore = HiveCacheStore(
        dirPath,
        hiveBoxName: 'custom_hive_interface',
        hiveInterface: Hive,
      );

      await addFooResponse(customStore);
      expect(await customStore.exists('foo'), isTrue);
    });
  });

  group('Isolated hive', () {
    late IsolatedHiveCacheStore store;

    setUpAll(() {
      store = IsolatedHiveCacheStore(dirPath);
    });

    setUp(() async {
      await store.clean();
    });

    tearDownAll(() async {
      await store.close();
    });

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

    test('close() can be called repeatedly without throwing', () async {
      await store.close();
      await store.close();
    });

    test(
      'recovers when the underlying box is closed by another store instance',
      () async {
        const boxName = 'isolated_shared_box_recovery';
        final storeA = IsolatedHiveCacheStore(dirPath, hiveBoxName: boxName);
        final storeB = IsolatedHiveCacheStore(dirPath, hiveBoxName: boxName);

        await addFooResponse(storeA);
        expect(await storeA.exists('foo'), isTrue);

        // storeB closes the box it shares with storeA behind its back.
        await storeB.close();

        // storeA must transparently reopen the box instead of throwing.
        expect(await storeA.exists('foo'), isTrue);
        await addFooResponse(storeA, key: 'bar');
        expect(await storeA.exists('bar'), isTrue);
      },
    );

    test('isolates data by hiveBoxName within the same directory', () async {
      final storeA = IsolatedHiveCacheStore(dirPath, hiveBoxName: 'iso_box_a');
      final storeB = IsolatedHiveCacheStore(dirPath, hiveBoxName: 'iso_box_b');

      await addFooResponse(storeA);
      expect(await storeA.exists('foo'), isTrue);
      expect(await storeB.exists('foo'), isFalse);
    });

    test('round-trips data through an encryption cipher', () async {
      final cipher = HiveAesCipher(List<int>.generate(32, (i) => i));
      final encryptedStore = IsolatedHiveCacheStore(
        dirPath,
        hiveBoxName: 'isolated_encrypted_box',
        encryptionCipher: cipher,
      );

      await addFooResponse(encryptedStore);
      final resp = await encryptedStore.get('foo');
      expect(resp?.key, 'foo');
      expect(resp?.content, utf8.encode('fooéèàç'));
    });

    test(
      'reuses an externally provided, already-initialized IsolatedHive instance',
      () async {
        await IsolatedHive.init(dirPath);

        final customStore = IsolatedHiveCacheStore(
          dirPath,
          hiveBoxName: 'externally_owned_hive',
          hiveInterface: IsolatedHive,
        );

        await addFooResponse(customStore);
        expect(await customStore.exists('foo'), isTrue);
      },
    );
  });
}
