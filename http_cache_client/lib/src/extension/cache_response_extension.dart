import 'package:http/http.dart' as http;
import 'package:http_cache_client/src/model/http_base_request.dart';
import 'package:http_cache_core/http_cache_core.dart';

extension CacheResponseExtension on CacheResponse {
  http.Response toResponse(HttpBaseRequest request) {
    return http.Response.bytes(
      content ?? [],
      statusCode,
      headers: getHeaders(),
      request: request.inner,
    );
  }
}
