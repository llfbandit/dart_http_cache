part of 'http_cache_client.dart';

extension _CacheClientUtils on CacheClient {
  bool _shouldSkip(String method, CacheOptions options) {
    final rqMethod = method.toUpperCase();
    var result = (rqMethod != _getMethod);
    result &= (!options.allowPostMethod || rqMethod != _postMethod);

    return result;
  }

  /// Gets cache store from given [options]
  /// or defaults to interceptor store.
  CacheStore _getCacheStore(CacheOptions options) {
    return options.store ?? _store;
  }

  String _getCacheKey(HttpBaseRequest request) {
    final innerRequest = request.inner;

    // Strip validation headers that CacheStrategyFactory injects before
    // forwarding, so the lookup key and the save key stay stable.
    final headers = Map<String, String>.from(innerRequest.headers)
      ..removeWhere((key, _) => conditionalRequestHeaders.contains(key));

    return request.options.keyBuilder(
      url: innerRequest.url,
      headers: headers,
      body: innerRequest is http.Request ? innerRequest.body : null,
    );
  }

  /// Gets cache options from given [request]
  /// or defaults to interceptor options.
  CacheOptions _getCacheOptions(CacheOptions? cacheOptions) {
    return cacheOptions ?? _options;
  }

  /// Reads cached response from cache store and transforms it to Response object.
  Future<http.Response?> _loadResponse(HttpBaseRequest request) async {
    final existing = await _loadCacheResponse(
      request,
      readHeaders: true,
      readBody: true,
    );

    // Transform CacheResponse to Response object
    return existing?.toResponse(request);
  }

  /// Reads cached response from cache store.
  Future<CacheResponse?> _loadCacheResponse(
    HttpBaseRequest request, {
    required bool readHeaders,
    required bool readBody,
  }) async {
    final cacheKey = _getCacheKey(request);
    final cacheStore = _getCacheStore(request.options);
    final response = await cacheStore.get(cacheKey);

    return response?.readContent(
      request.options,
      readHeaders: readHeaders,
      readBody: readBody,
    );
  }

  /// Updates cached response if input has maxStale
  /// This allows to push off deletion of the entry.
  Future<CacheResponse> _updateCacheResponse(
    CacheResponse cacheResponse,
    CacheOptions cacheOptions,
  ) async {
    final maxStaleUpdate = cacheOptions.maxStale;
    if (maxStaleUpdate != null) {
      final now = DateTime.now().toUtc();
      final newMaxStale = now.add(maxStaleUpdate);

      // Skip the store write while the persisted window is still more than half
      // away; still write when it's missing, near expiry, or shrinking.
      final halfWindow = Duration(
        microseconds: maxStaleUpdate.inMicroseconds ~/ 2,
      );
      final existingMaxStale = cacheResponse.maxStale;
      final needsWrite =
          existingMaxStale == null ||
          existingMaxStale.isBefore(now.add(halfWindow)) ||
          newMaxStale.isBefore(existingMaxStale);

      cacheResponse = cacheResponse.copyWith(maxStale: newMaxStale);

      if (needsWrite) {
        await _getCacheStore(
          cacheOptions,
        ).set(await cacheResponse.writeContent(cacheOptions));
      }
    }

    return cacheResponse;
  }

  /// Writes cached response to cache store if strategy allows it.
  Future<void> _saveResponse(
    http.Response response,
    HttpBaseRequest request,
  ) async {
    final strategy =
        await CacheStrategyFactory(
          request: request,
          response: HttpBaseResponse(response),
          cacheOptions: request.options,
        ).compute(
          cacheResponseBuilder: () => response.toCacheResponse(
            key: _getCacheKey(request),
            options: request.options,
            requestDate: request.requestDate,
          ),
        );

    final cacheResp = strategy.cacheResponse;
    if (cacheResp != null) {
      // Store response to cache store
      await _getCacheStore(request.options).set(cacheResp);
    }
  }
}
