import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/src/extension/request_extension.dart';
import 'package:http_cache_core/http_cache_core.dart';

/// Wrapper on [BaseRequest] to deal with [RequestOptions]
class DioBaseRequest extends BaseRequest {
  final RequestOptions request;
  final Map<String, String> _headers;

  DioBaseRequest(this.request) : _headers = request.getFlattenHeaders();

  @override
  void setHeader(String header, String? value) {
    if (value == null) {
      request.headers.remove(header);
      _headers.remove(header);
    } else {
      request.headers[header] = value;
      _headers[header] = value;
    }
  }

  @override
  Map<String, String> get headers => _headers;
}
