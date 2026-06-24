import 'http_date.dart';

DateTime? getExpiresHeaderValue(String? headerValue) {
  if (headerValue case final expires?) {
    try {
      return HttpDate.parse(expires);
    } catch (_) {
      // Malformed Expires header
      // Treat as absent so other freshness signals (max-age, Last-Modified heuristic) are still evaluated.
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
