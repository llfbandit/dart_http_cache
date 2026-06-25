import 'package:http_cache_core/http_cache_core.dart';
import 'package:test/test.dart';

void main() {
  group('getExpiresHeaderValue', () {
    test('returns null on null', () {
      expect(getExpiresHeaderValue(null), isNull);
    });

    test('returns DateTime when valid', () {
      expect(
        getExpiresHeaderValue('Thu, 1 Jan 1970 00:00:00 GMT'),
        isA<DateTime>(),
      );
    });

    test('malformed header treated as already expired (RFC 7234 §5.3)', () {
      final epochPast = DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true);
      expect(getExpiresHeaderValue('Thu, 1 Jan 1972'), equals(epochPast));
      expect(getExpiresHeaderValue('not-a-date'), equals(epochPast));
    });
  });

  group('getExpiresHeaderValue', () {
    test('returns null on null', () {
      expect(getDateHeaderValue(null), isNull);
    });

    test('returns null on invalid', () {
      expect(getDateHeaderValue('Thu, 1 Jan 1972'), isNull);
    });

    test('returns DateTime when valid', () {
      expect(
        getDateHeaderValue('Thu, 1 Jan 1970 00:00:00 GMT'),
        isA<DateTime>(),
      );
    });
  });
}
