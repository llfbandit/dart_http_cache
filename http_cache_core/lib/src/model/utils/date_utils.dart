import 'http_date.dart';

DateTime? getExpiresHeaderValue(String? headerValue) {
  if (headerValue case final expires?) {
    try {
      return HttpDate.parse(expires);
    } catch (_) {
      // RFC 7234 §5.3: an invalid Expires value (notably "0") MUST be treated
      // as already expired. Return an epoch-past date so the response is stale.
      return DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true);
    }
  }

  return null;
}

DateTime? getDateHeaderValue(String? headerValue) {
  if (headerValue case final date?) {
    try {
      return HttpDate.parse(date);
    } catch (_) {
      // Invalid date format => ignored
    }
  }

  return null;
}
