import 'package:http_cache_core/http_cache_core.dart';
import 'package:test/test.dart';

void main() {
  test('Default headers', () {
    final cacheControl1 = CacheControl();
    expect(cacheControl1.maxAge, equals(-1));
    expect(cacheControl1.noCache, false);
    expect(cacheControl1.noStore, false);
    expect(cacheControl1.other, equals([]));
    expect(cacheControl1.privacy, isNull);
    expect(cacheControl1.maxStale, equals(-1));
    expect(cacheControl1.minFresh, equals(-1));
    expect(cacheControl1.mustRevalidate, equals(false));

    expect(cacheControl1, equals(CacheControl.fromHeader(null)));
    expect(cacheControl1, equals(CacheControl.fromHeader([])));
  });

  test('headers', () {
    final cacheControl1 = CacheControl(
      maxAge: 1,
      noCache: true,
      noStore: true,
      other: ['unknown', 'unknown2=2'],
      privacy: 'public',
      maxStale: 2,
      minFresh: 3,
      mustRevalidate: true,
    );

    final cacheControl2 = CacheControl.fromHeader([
      'max-age=1, no-store, no-cache, public, unknown, unknown2=2, max-stale=2, min-fresh=3, must-revalidate',
    ]);

    expect(cacheControl1, equals(cacheControl2));

    // Redo test with toHeader()
    final cacheControl3 = CacheControl.fromHeader([cacheControl2.toHeader()]);
    expect(cacheControl1, equals(cacheControl3));
  });

  test('headers with and without optional whitespace', () {
    final cacheControl1 = CacheControl(
      maxAge: 1,
      noCache: true,
      noStore: true,
      other: ['unknown', 'unknown2=2'],
      privacy: 'public',
      maxStale: 2,
      minFresh: 3,
      mustRevalidate: true,
    );

    final cacheControl2 = CacheControl.fromHeader([
      'max-age=1 , no-store,  no-cache, public,unknown , unknown2=2 , max-stale=2,min-fresh=3,must-revalidate',
    ]);

    expect(cacheControl1, equals(cacheControl2));

    // Redo test with toHeader()
    final cacheControl3 = CacheControl.fromHeader([cacheControl2.toHeader()]);
    expect(cacheControl1, equals(cacheControl3));
  });

  test('headers splitted', () {
    final cacheControl1 = CacheControl(
      maxAge: 1,
      noCache: true,
      noStore: true,
      privacy: 'public',
      maxStale: 2,
      minFresh: 3,
      mustRevalidate: true,
    );

    final cacheControl2 = CacheControl.fromHeader([
      'max-age=1',
      'no-store',
      'no-cache',
      'public',
      'max-stale=2',
      'min-fresh=3',
      'must-revalidate',
    ]);

    expect(cacheControl1, equals(cacheControl2));

    // Redo test with toHeader()
    final cacheControl3 = CacheControl.fromHeader([cacheControl2.toHeader()]);
    expect(cacheControl1, equals(cacheControl3));
  });

  test('bare max-stale (no delta-seconds) means accept any stale age', () {
    // With a value: parses normally.
    expect(CacheControl.fromHeader(['max-stale=60']).maxStale, equals(60));

    // Bare directive: must store a large positive value, not -1 (= "not set").
    final bare = CacheControl.fromHeader(['max-stale']);
    expect(bare.maxStale, greaterThan(0));

    // Sanity-check: the value is large enough that multiplying by 1000 (ms)
    // won't overflow and a stale response is always considered acceptable.
    expect(
      bare.maxStale * 1000,
      greaterThan(Duration(days: 365).inMilliseconds),
    );
  });

  test('fromHeader tolerates non-token characters (e.g. CDN extensions)', () {
    // A lone non-token directive must not throw and is silently skipped.
    expect(() => CacheControl.fromHeader(['{cdn-extension}']), returnsNormally);
    expect(CacheControl.fromHeader(['{cdn-extension}']), equals(CacheControl()));

    // Valid directives before the bad token must be preserved.
    final cc = CacheControl.fromHeader(['no-cache, {cdn-extension}, max-age=60']);
    expect(cc.noCache, isTrue);
    expect(cc.maxAge, equals(60));
  });

  test('fromHeader tolerates whitespace-only and trailing-comma values', () {
    // Whitespace-only header value must not throw.
    expect(() => CacheControl.fromHeader([' ']), returnsNormally);
    expect(CacheControl.fromHeader([' ']), equals(CacheControl()));

    // Trailing comma after valid directive must not throw.
    expect(() => CacheControl.fromHeader(['no-cache, ']), returnsNormally);
    expect(
      CacheControl.fromHeader(['no-cache, ']),
      equals(CacheControl(noCache: true)),
    );
  });

  test('equal instances have the same hashCode', () {
    final cc = CacheControl(maxAge: 60, noCache: true, other: ['x-custom']);
    final copy = CacheControl(maxAge: 60, noCache: true, other: ['x-custom']);
    expect(cc, equals(copy));
    expect(cc.hashCode, equals(copy.hashCode));
  });

  test('CacheControl.fromString', () {
    final cacheControl1 = CacheControl(
      maxAge: 1,
      noCache: true,
      noStore: true,
      privacy: 'public',
      maxStale: 2,
      minFresh: 3,
      mustRevalidate: true,
    );

    final cacheControl2 = CacheControl.fromString(
      [
        'max-age=1',
        'no-store',
        'no-cache="set-cookie"', // no-cache is detected but set-cookie is lost
        'public',
        'max-stale=2',
        'min-fresh=3',
        'must-revalidate',
      ].join(', '),
    );

    expect(cacheControl1, equals(cacheControl2));

    // Redo test with toHeader()
    final cacheControl3 = CacheControl.fromHeader([cacheControl2.toHeader()]);
    expect(cacheControl1, equals(cacheControl3));
  });
}
