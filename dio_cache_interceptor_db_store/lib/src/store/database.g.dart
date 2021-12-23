// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class DioCacheData extends DataClass implements Insertable<DioCacheData> {
  final String cacheKey;
  final DateTime? date;
  final String? cacheControl;
  final Uint8List? content;
  final String? eTag;
  final DateTime? expires;
  final Uint8List? headers;
  final String? lastModified;
  final DateTime? maxStale;
  final int priority;
  final DateTime responseDate;
  final String url;
  DioCacheData(
      {required this.cacheKey,
      this.date,
      this.cacheControl,
      this.content,
      this.eTag,
      this.expires,
      this.headers,
      this.lastModified,
      this.maxStale,
      required this.priority,
      required this.responseDate,
      required this.url});
  factory DioCacheData.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return DioCacheData(
      cacheKey: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}cacheKey'])!,
      date: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}date']),
      cacheControl: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}cacheControl']),
      content: const BlobType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content']),
      eTag: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}eTag']),
      expires: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}expires']),
      headers: const BlobType()
          .mapFromDatabaseResponse(data['${effectivePrefix}headers']),
      lastModified: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}lastModified']),
      maxStale: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}maxStale']),
      priority: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}priority'])!,
      responseDate: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}responseDate'])!,
      url: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}url'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cacheKey'] = Variable<String>(cacheKey);
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<DateTime?>(date);
    }
    if (!nullToAbsent || cacheControl != null) {
      map['cacheControl'] = Variable<String?>(cacheControl);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<Uint8List?>(content);
    }
    if (!nullToAbsent || eTag != null) {
      map['eTag'] = Variable<String?>(eTag);
    }
    if (!nullToAbsent || expires != null) {
      map['expires'] = Variable<DateTime?>(expires);
    }
    if (!nullToAbsent || headers != null) {
      map['headers'] = Variable<Uint8List?>(headers);
    }
    if (!nullToAbsent || lastModified != null) {
      map['lastModified'] = Variable<String?>(lastModified);
    }
    if (!nullToAbsent || maxStale != null) {
      map['maxStale'] = Variable<DateTime?>(maxStale);
    }
    map['priority'] = Variable<int>(priority);
    map['responseDate'] = Variable<DateTime>(responseDate);
    map['url'] = Variable<String>(url);
    return map;
  }

  DioCacheCompanion toCompanion(bool nullToAbsent) {
    return DioCacheCompanion(
      cacheKey: Value(cacheKey),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      cacheControl: cacheControl == null && nullToAbsent
          ? const Value.absent()
          : Value(cacheControl),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      eTag: eTag == null && nullToAbsent ? const Value.absent() : Value(eTag),
      expires: expires == null && nullToAbsent
          ? const Value.absent()
          : Value(expires),
      headers: headers == null && nullToAbsent
          ? const Value.absent()
          : Value(headers),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      maxStale: maxStale == null && nullToAbsent
          ? const Value.absent()
          : Value(maxStale),
      priority: Value(priority),
      responseDate: Value(responseDate),
      url: Value(url),
    );
  }

  factory DioCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DioCacheData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      date: serializer.fromJson<DateTime?>(json['date']),
      cacheControl: serializer.fromJson<String?>(json['cacheControl']),
      content: serializer.fromJson<Uint8List?>(json['content']),
      eTag: serializer.fromJson<String?>(json['eTag']),
      expires: serializer.fromJson<DateTime?>(json['expires']),
      headers: serializer.fromJson<Uint8List?>(json['headers']),
      lastModified: serializer.fromJson<String?>(json['lastModified']),
      maxStale: serializer.fromJson<DateTime?>(json['maxStale']),
      priority: serializer.fromJson<int>(json['priority']),
      responseDate: serializer.fromJson<DateTime>(json['responseDate']),
      url: serializer.fromJson<String>(json['url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'date': serializer.toJson<DateTime?>(date),
      'cacheControl': serializer.toJson<String?>(cacheControl),
      'content': serializer.toJson<Uint8List?>(content),
      'eTag': serializer.toJson<String?>(eTag),
      'expires': serializer.toJson<DateTime?>(expires),
      'headers': serializer.toJson<Uint8List?>(headers),
      'lastModified': serializer.toJson<String?>(lastModified),
      'maxStale': serializer.toJson<DateTime?>(maxStale),
      'priority': serializer.toJson<int>(priority),
      'responseDate': serializer.toJson<DateTime>(responseDate),
      'url': serializer.toJson<String>(url),
    };
  }

  DioCacheData copyWith(
          {String? cacheKey,
          DateTime? date,
          String? cacheControl,
          Uint8List? content,
          String? eTag,
          DateTime? expires,
          Uint8List? headers,
          String? lastModified,
          DateTime? maxStale,
          int? priority,
          DateTime? responseDate,
          String? url}) =>
      DioCacheData(
        cacheKey: cacheKey ?? this.cacheKey,
        date: date ?? this.date,
        cacheControl: cacheControl ?? this.cacheControl,
        content: content ?? this.content,
        eTag: eTag ?? this.eTag,
        expires: expires ?? this.expires,
        headers: headers ?? this.headers,
        lastModified: lastModified ?? this.lastModified,
        maxStale: maxStale ?? this.maxStale,
        priority: priority ?? this.priority,
        responseDate: responseDate ?? this.responseDate,
        url: url ?? this.url,
      );
  @override
  String toString() {
    return (StringBuffer('DioCacheData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('date: $date, ')
          ..write('cacheControl: $cacheControl, ')
          ..write('content: $content, ')
          ..write('eTag: $eTag, ')
          ..write('expires: $expires, ')
          ..write('headers: $headers, ')
          ..write('lastModified: $lastModified, ')
          ..write('maxStale: $maxStale, ')
          ..write('priority: $priority, ')
          ..write('responseDate: $responseDate, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, date, cacheControl, content, eTag,
      expires, headers, lastModified, maxStale, priority, responseDate, url);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DioCacheData &&
          other.cacheKey == this.cacheKey &&
          other.date == this.date &&
          other.cacheControl == this.cacheControl &&
          other.content == this.content &&
          other.eTag == this.eTag &&
          other.expires == this.expires &&
          other.headers == this.headers &&
          other.lastModified == this.lastModified &&
          other.maxStale == this.maxStale &&
          other.priority == this.priority &&
          other.responseDate == this.responseDate &&
          other.url == this.url);
}

class DioCacheCompanion extends UpdateCompanion<DioCacheData> {
  final Value<String> cacheKey;
  final Value<DateTime?> date;
  final Value<String?> cacheControl;
  final Value<Uint8List?> content;
  final Value<String?> eTag;
  final Value<DateTime?> expires;
  final Value<Uint8List?> headers;
  final Value<String?> lastModified;
  final Value<DateTime?> maxStale;
  final Value<int> priority;
  final Value<DateTime> responseDate;
  final Value<String> url;
  const DioCacheCompanion({
    this.cacheKey = const Value.absent(),
    this.date = const Value.absent(),
    this.cacheControl = const Value.absent(),
    this.content = const Value.absent(),
    this.eTag = const Value.absent(),
    this.expires = const Value.absent(),
    this.headers = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.maxStale = const Value.absent(),
    this.priority = const Value.absent(),
    this.responseDate = const Value.absent(),
    this.url = const Value.absent(),
  });
  DioCacheCompanion.insert({
    required String cacheKey,
    this.date = const Value.absent(),
    this.cacheControl = const Value.absent(),
    this.content = const Value.absent(),
    this.eTag = const Value.absent(),
    this.expires = const Value.absent(),
    this.headers = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.maxStale = const Value.absent(),
    required int priority,
    required DateTime responseDate,
    required String url,
  })  : cacheKey = Value(cacheKey),
        priority = Value(priority),
        responseDate = Value(responseDate),
        url = Value(url);
  static Insertable<DioCacheData> custom({
    Expression<String>? cacheKey,
    Expression<DateTime?>? date,
    Expression<String?>? cacheControl,
    Expression<Uint8List?>? content,
    Expression<String?>? eTag,
    Expression<DateTime?>? expires,
    Expression<Uint8List?>? headers,
    Expression<String?>? lastModified,
    Expression<DateTime?>? maxStale,
    Expression<int>? priority,
    Expression<DateTime>? responseDate,
    Expression<String>? url,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cacheKey': cacheKey,
      if (date != null) 'date': date,
      if (cacheControl != null) 'cacheControl': cacheControl,
      if (content != null) 'content': content,
      if (eTag != null) 'eTag': eTag,
      if (expires != null) 'expires': expires,
      if (headers != null) 'headers': headers,
      if (lastModified != null) 'lastModified': lastModified,
      if (maxStale != null) 'maxStale': maxStale,
      if (priority != null) 'priority': priority,
      if (responseDate != null) 'responseDate': responseDate,
      if (url != null) 'url': url,
    });
  }

  DioCacheCompanion copyWith(
      {Value<String>? cacheKey,
      Value<DateTime?>? date,
      Value<String?>? cacheControl,
      Value<Uint8List?>? content,
      Value<String?>? eTag,
      Value<DateTime?>? expires,
      Value<Uint8List?>? headers,
      Value<String?>? lastModified,
      Value<DateTime?>? maxStale,
      Value<int>? priority,
      Value<DateTime>? responseDate,
      Value<String>? url}) {
    return DioCacheCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      date: date ?? this.date,
      cacheControl: cacheControl ?? this.cacheControl,
      content: content ?? this.content,
      eTag: eTag ?? this.eTag,
      expires: expires ?? this.expires,
      headers: headers ?? this.headers,
      lastModified: lastModified ?? this.lastModified,
      maxStale: maxStale ?? this.maxStale,
      priority: priority ?? this.priority,
      responseDate: responseDate ?? this.responseDate,
      url: url ?? this.url,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cacheKey'] = Variable<String>(cacheKey.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime?>(date.value);
    }
    if (cacheControl.present) {
      map['cacheControl'] = Variable<String?>(cacheControl.value);
    }
    if (content.present) {
      map['content'] = Variable<Uint8List?>(content.value);
    }
    if (eTag.present) {
      map['eTag'] = Variable<String?>(eTag.value);
    }
    if (expires.present) {
      map['expires'] = Variable<DateTime?>(expires.value);
    }
    if (headers.present) {
      map['headers'] = Variable<Uint8List?>(headers.value);
    }
    if (lastModified.present) {
      map['lastModified'] = Variable<String?>(lastModified.value);
    }
    if (maxStale.present) {
      map['maxStale'] = Variable<DateTime?>(maxStale.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (responseDate.present) {
      map['responseDate'] = Variable<DateTime>(responseDate.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DioCacheCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('date: $date, ')
          ..write('cacheControl: $cacheControl, ')
          ..write('content: $content, ')
          ..write('eTag: $eTag, ')
          ..write('expires: $expires, ')
          ..write('headers: $headers, ')
          ..write('lastModified: $lastModified, ')
          ..write('maxStale: $maxStale, ')
          ..write('priority: $priority, ')
          ..write('responseDate: $responseDate, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }
}

class DioCache extends Table with TableInfo<DioCache, DioCacheData> {
  final GeneratedDatabase _db;
  final String? _alias;
  DioCache(this._db, [this._alias]);
  final VerificationMeta _cacheKeyMeta = const VerificationMeta('cacheKey');
  late final GeneratedColumn<String?> cacheKey = GeneratedColumn<String?>(
      'cacheKey', aliasedName, false,
      type: const StringType(),
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL PRIMARY KEY');
  final VerificationMeta _dateMeta = const VerificationMeta('date');
  late final GeneratedColumn<DateTime?> date = GeneratedColumn<DateTime?>(
      'date', aliasedName, true,
      type: const IntType(),
      requiredDuringInsert: false,
      $customConstraints: '');
  final VerificationMeta _cacheControlMeta =
      const VerificationMeta('cacheControl');
  late final GeneratedColumn<String?> cacheControl = GeneratedColumn<String?>(
      'cacheControl', aliasedName, true,
      type: const StringType(),
      requiredDuringInsert: false,
      $customConstraints: '');
  final VerificationMeta _contentMeta = const VerificationMeta('content');
  late final GeneratedColumn<Uint8List?> content = GeneratedColumn<Uint8List?>(
      'content', aliasedName, true,
      type: const BlobType(),
      requiredDuringInsert: false,
      $customConstraints: '');
  final VerificationMeta _eTagMeta = const VerificationMeta('eTag');
  late final GeneratedColumn<String?> eTag = GeneratedColumn<String?>(
      'eTag', aliasedName, true,
      type: const StringType(),
      requiredDuringInsert: false,
      $customConstraints: '');
  final VerificationMeta _expiresMeta = const VerificationMeta('expires');
  late final GeneratedColumn<DateTime?> expires = GeneratedColumn<DateTime?>(
      'expires', aliasedName, true,
      type: const IntType(),
      requiredDuringInsert: false,
      $customConstraints: '');
  final VerificationMeta _headersMeta = const VerificationMeta('headers');
  late final GeneratedColumn<Uint8List?> headers = GeneratedColumn<Uint8List?>(
      'headers', aliasedName, true,
      type: const BlobType(),
      requiredDuringInsert: false,
      $customConstraints: '');
  final VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  late final GeneratedColumn<String?> lastModified = GeneratedColumn<String?>(
      'lastModified', aliasedName, true,
      type: const StringType(),
      requiredDuringInsert: false,
      $customConstraints: '');
  final VerificationMeta _maxStaleMeta = const VerificationMeta('maxStale');
  late final GeneratedColumn<DateTime?> maxStale = GeneratedColumn<DateTime?>(
      'maxStale', aliasedName, true,
      type: const IntType(),
      requiredDuringInsert: false,
      $customConstraints: '');
  final VerificationMeta _priorityMeta = const VerificationMeta('priority');
  late final GeneratedColumn<int?> priority = GeneratedColumn<int?>(
      'priority', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  final VerificationMeta _responseDateMeta =
      const VerificationMeta('responseDate');
  late final GeneratedColumn<DateTime?> responseDate =
      GeneratedColumn<DateTime?>('responseDate', aliasedName, false,
          type: const IntType(),
          requiredDuringInsert: true,
          $customConstraints: 'NOT NULL');
  final VerificationMeta _urlMeta = const VerificationMeta('url');
  late final GeneratedColumn<String?> url = GeneratedColumn<String?>(
      'url', aliasedName, false,
      type: const StringType(),
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [
        cacheKey,
        date,
        cacheControl,
        content,
        eTag,
        expires,
        headers,
        lastModified,
        maxStale,
        priority,
        responseDate,
        url
      ];
  @override
  String get aliasedName => _alias ?? 'DioCache';
  @override
  String get actualTableName => 'DioCache';
  @override
  VerificationContext validateIntegrity(Insertable<DioCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cacheKey')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cacheKey']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    if (data.containsKey('cacheControl')) {
      context.handle(
          _cacheControlMeta,
          cacheControl.isAcceptableOrUnknown(
              data['cacheControl']!, _cacheControlMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('eTag')) {
      context.handle(
          _eTagMeta, eTag.isAcceptableOrUnknown(data['eTag']!, _eTagMeta));
    }
    if (data.containsKey('expires')) {
      context.handle(_expiresMeta,
          expires.isAcceptableOrUnknown(data['expires']!, _expiresMeta));
    }
    if (data.containsKey('headers')) {
      context.handle(_headersMeta,
          headers.isAcceptableOrUnknown(data['headers']!, _headersMeta));
    }
    if (data.containsKey('lastModified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['lastModified']!, _lastModifiedMeta));
    }
    if (data.containsKey('maxStale')) {
      context.handle(_maxStaleMeta,
          maxStale.isAcceptableOrUnknown(data['maxStale']!, _maxStaleMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('responseDate')) {
      context.handle(
          _responseDateMeta,
          responseDate.isAcceptableOrUnknown(
              data['responseDate']!, _responseDateMeta));
    } else if (isInserting) {
      context.missing(_responseDateMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  DioCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return DioCacheData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  DioCache createAlias(String alias) {
    return DioCache(_db, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

abstract class _$DioCacheDatabase extends GeneratedDatabase {
  _$DioCacheDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final DioCache dioCache = DioCache(this);
  late final DioCacheDao dioCacheDao = DioCacheDao(this as DioCacheDatabase);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [dioCache];
}

// **************************************************************************
// DaoGenerator
// **************************************************************************

mixin _$DioCacheDaoMixin on DatabaseAccessor<DioCacheDatabase> {
  DioCache get dioCache => attachedDatabase.dioCache;
}
