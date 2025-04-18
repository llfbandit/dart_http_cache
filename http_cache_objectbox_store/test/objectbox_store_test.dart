import 'dart:io';

import 'package:http_cache_objectbox_store/http_cache_objectbox_store.dart';
import 'package:http_cache_store_tester/common_store_testing.dart';
import 'package:test/test.dart';

void main() {
  late ObjectBoxCacheStore store;

  setUpAll(() {
    store = ObjectBoxCacheStore(storePath: Directory.current.path);
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
}
