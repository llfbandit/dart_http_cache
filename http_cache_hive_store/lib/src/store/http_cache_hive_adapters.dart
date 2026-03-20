import 'package:hive_ce/hive.dart';
import 'package:http_cache_core/http_cache_core.dart';

/// Interface abstracting Hive box operations for both regular and isolated Hive.
///
/// This interface unifies the API between [LazyBox] and [IsolatedLazyBox]
/// to allow [HiveCacheStore] and [IsolatedHiveCacheStore] to share common logic.
abstract class HttpCacheHiveBox<T> {
  /// Whether the box is currently open.
  bool get isOpen;

  /// The keys stored in the box.
  ///
  /// Returns a synchronous list for regular Hive,
  /// and a Future for isolated Hive.
  Future<List<String>> get keys;

  /// Returns the value at [index].
  Future<T?> getAt(int index);

  /// Returns the value for [key].
  Future<T?> get(String key);

  /// Returns whether [key] exists in the box.
  Future<bool> containsKey(String key);

  /// Stores [value] with [key].
  Future<void> put(String key, T value);

  /// Deletes the value for [key].
  Future<void> delete(String key);

  /// Deletes all values for [keys].
  Future<void> deleteAll(List<String> keys);

  /// Closes the box.
  Future<void> close();
}

/// Adapter for [LazyBox] to conform to [HttpCacheHiveBox].
class LazyBoxAdapter<T> implements HttpCacheHiveBox<T> {
  final LazyBox<T> _box;

  LazyBoxAdapter(this._box);

  @override
  bool get isOpen => _box.isOpen;

  @override
  Future<List<String>> get keys =>
      Future.value(_box.keys.cast<String>().toList());

  @override
  Future<T?> getAt(int index) => _box.getAt(index);

  @override
  Future<T?> get(String key) => _box.get(key);

  @override
  Future<bool> containsKey(String key) => Future.value(_box.containsKey(key));

  @override
  Future<void> put(String key, T value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> deleteAll(List<String> keys) => _box.deleteAll(keys);

  @override
  Future<void> close() => _box.close();
}

/// Adapter for [IsolatedLazyBox] to conform to [HttpCacheHiveBox].
class IsolatedLazyBoxAdapter<T> implements HttpCacheHiveBox<T> {
  final IsolatedLazyBox<T> _box;

  IsolatedLazyBoxAdapter(this._box);

  @override
  bool get isOpen => _box.isOpen;

  @override
  Future<List<String>> get keys => _box.keys.then((k) => k.cast<String>());

  @override
  Future<T?> getAt(int index) => _box.getAt(index);

  @override
  Future<T?> get(String key) => _box.get(key);

  @override
  Future<bool> containsKey(String key) => _box.containsKey(key);

  @override
  Future<void> put(String key, T value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> deleteAll(List<String> keys) => _box.deleteAll(keys);

  @override
  Future<void> close() => _box.close();
}

/// Adapter for [CacheResponse]
class CacheResponseAdapter extends TypeAdapter<CacheResponse> {
  static const int id = 93;

  @override
  final int typeId = id;

  @override
  CacheResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheResponse(
      cacheControl: fields[0] as CacheControl? ?? CacheControl(),
      content: (fields[1] as List?)?.cast<int>(),
      date: fields[2] as DateTime?,
      eTag: fields[3] as String?,
      expires: fields[4] as DateTime?,
      headers: (fields[5] as List?)?.cast<int>(),
      key: fields[6] as String,
      lastModified: fields[7] as String?,
      maxStale: fields[8] as DateTime?,
      priority: fields[9] as CachePriority,
      responseDate: fields[10] as DateTime,
      url: fields[11] as String,
      requestDate: fields[12] as DateTime,
      statusCode: fields[13] as int? ?? 304,
    );
  }

  @override
  void write(BinaryWriter writer, CacheResponse obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.cacheControl)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.eTag)
      ..writeByte(4)
      ..write(obj.expires)
      ..writeByte(5)
      ..write(obj.headers)
      ..writeByte(6)
      ..write(obj.key)
      ..writeByte(7)
      ..write(obj.lastModified)
      ..writeByte(8)
      ..write(obj.maxStale)
      ..writeByte(9)
      ..write(obj.priority)
      ..writeByte(10)
      ..write(obj.responseDate)
      ..writeByte(11)
      ..write(obj.url)
      ..writeByte(12)
      ..write(obj.requestDate)
      ..writeByte(13)
      ..write(obj.statusCode);
  }
}

/// Adapter for [CacheControl]
class CacheControlAdapter extends TypeAdapter<CacheControl> {
  static const int id = 94;

  @override
  final int typeId = id;

  @override
  CacheControl read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheControl(
      maxAge: fields[0] as int? ?? -1,
      privacy: fields[1] as String?,
      noCache: fields[2] as bool? ?? false,
      noStore: fields[3] as bool? ?? false,
      other: (fields[4] as List).cast<String>(),
      maxStale: fields[5] as int? ?? -1,
      minFresh: fields[6] as int? ?? -1,
      mustRevalidate: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CacheControl obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.maxAge)
      ..writeByte(1)
      ..write(obj.privacy)
      ..writeByte(2)
      ..write(obj.noCache)
      ..writeByte(3)
      ..write(obj.noStore)
      ..writeByte(4)
      ..write(obj.other)
      ..writeByte(5)
      ..write(obj.maxStale)
      ..writeByte(6)
      ..write(obj.minFresh)
      ..writeByte(7)
      ..write(obj.mustRevalidate);
  }
}

/// Adapter for [CachePriority]
class CachePriorityAdapter extends TypeAdapter<CachePriority> {
  static const int id = 95;

  @override
  final int typeId = id;

  @override
  CachePriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CachePriority.low;
      case 2:
        return CachePriority.high;
      case 1:
      default:
        return CachePriority.normal;
    }
  }

  @override
  void write(BinaryWriter writer, CachePriority obj) {
    switch (obj) {
      case CachePriority.low:
        writer.writeByte(0);
      case CachePriority.normal:
        writer.writeByte(1);
      case CachePriority.high:
        writer.writeByte(2);
    }
  }
}
