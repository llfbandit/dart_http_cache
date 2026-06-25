import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_cache_client/src/extension/cache_response_extension.dart';
import 'package:http_cache_client/src/extension/response_extension.dart';
import 'package:http_cache_client/src/model/http_base_response.dart';
import 'package:http_cache_core/http_cache_core.dart';

import '../model/http_base_request.dart';

part 'http_cache_client_cache_events.dart';
part 'http_cache_client_cache_utils.dart';

class CacheClient extends http.BaseClient {
  final CacheOptions _options;
  final CacheStore _store;
  final http.Client _inner;

  CacheClient(this._inner, {required CacheOptions options})
    : assert(options.store != null),
      _options = options,
      _store = options.store!;

  @override
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    CacheOptions? options,
  }) => _onRequest(
    _prepareRequest(_getCacheOptions(options), _getMethod, url, headers),
  );

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    CacheOptions? options,
  }) => _onRequest(
    _prepareRequest(
      _getCacheOptions(options),
      _postMethod,
      url,
      headers,
      body,
      encoding,
    ),
  );

  @override
  Future<String> read(
    Uri url, {
    Map<String, String>? headers,
    CacheOptions? options,
  }) async {
    final response = await get(
      url,
      headers: headers,
      options: _getCacheOptions(options),
    );
    _checkResponseSuccess(url, response);
    return response.body;
  }

  @override
  Future<Uint8List> readBytes(
    Uri url, {
    Map<String, String>? headers,
    CacheOptions? options,
  }) async {
    final response = await get(
      url,
      headers: headers,
      options: _getCacheOptions(options),
    );
    _checkResponseSuccess(url, response);
    return response.bodyBytes;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Non-cacheable methods stream straight through; cacheable ones funnel
    // through the cache flow so send() (and any verb built on it) is cached too.
    if (_shouldSkip(request.method, _options)) {
      return _inner.send(request);
    }

    final wrapped = HttpBaseRequest(request, _options, DateTime.now());
    return _streamedResponse(await _onRequest(wrapped));
  }

  http.StreamedResponse _streamedResponse(http.Response response) {
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      contentLength: response.bodyBytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  /// Prepares a [Request] from given parameters.
  HttpBaseRequest _prepareRequest(
    CacheOptions options,
    String method,
    Uri url,
    Map<String, String>? headers, [
    Object? body,
    Encoding? encoding,
  ]) {
    var request = http.Request(method, url);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    return HttpBaseRequest(request, options, DateTime.now());
  }

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<http.Response> _sendUnstreamedRequest(HttpBaseRequest request) async {
    final http.Response response;
    try {
      // Use the inner client directly: send() is the cache funnel and would
      // recurse back here for cacheable methods.
      response = await http.Response.fromStream(
        await _inner.send(request.inner),
      );
    } catch (ex) {
      // Any transport error (ClientException, SocketException, timeout, …)
      // may fall back to cache when allowed.
      return _onError(ex, request);
    }
    return _onResponse(response, request);
  }

  /// Throws an error if [response] is not successful.
  void _checkResponseSuccess(Uri url, http.Response response) {
    if (response.statusCode < 400) return;
    var message = 'Request to $url failed with status ${response.statusCode}';
    if (response.reasonPhrase != null) {
      message = '$message: ${response.reasonPhrase}';
    }
    throw http.ClientException('$message.', url);
  }
}
