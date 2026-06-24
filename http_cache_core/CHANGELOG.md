## 1.1.4
- perf: DeepCollectionEquality to static const in CacheResponse and CacheControl.
- perf: memoize getHeaders() to avoid repeated JSON decode per isExpired() call.
- fix: treat bare max-stale (no delta) as accept any age.
- fix: skip non-token Cache-Control directives instead of throwing.
- fix: deduplicate getFromPath results by key instead of value equality.
- fix: guard against whitespace-only and trailing-comma Cache-Control values.
- fix: include If-None-Match to prevent bypassing client conditionals.
- fix: enforce allowedStatusCodes in _isCacheable to prevent caching error responses.
- chore: Update dependencies.
- fix: anchor regex to prevent substring mismatches.
- fix: treat max-age=0 as a cache directive in _hasCacheDirectives.
- fix: move If-Modified-Since removal out of _hasConditions predicate.
- fix: guard HttpDate.parse against malformed Last-Modified.
- fix: CacheResponse.hashCode violated hash/equals contract for List fields.
- fix: repair LRU linked-list corruption when removing a middle node.
- chore: Min SDK is now 3.6.0.

## 1.1.3
- fix: Allow optional whitespace in header values.

## 1.1.2
- fix: Allow keyBuilder to depend on request body.

## 1.1.1
- fix: Send only one condition on request cache validation.
- fix: BaseRequest now has `headers` getter instead of `headerValuesAsList`.
- fix: 302 & 307 codes handling.

## 1.1.0
- feat: Early skip strategy calculation when request has already cache check conditions.
- feat: Better handling of headers.
- feat: Clamp cache-control values and other headers.
- fix: Regression from versions 1.0.1 with `CacheOptions#maxStale` inverted behaviour.
- chore: Add more comments.
- chore: Add more tests & fix some.

## 1.0.2
- fix: Enforce `CacheKeyBuilder` headers as map of `String` values instead of `dynamic`.

## 1.0.1
- chore: Add writeContent to CacheResponse.
- fix: `CacheOptions#maxStale` usage may lead to empty response body.
- chore: Allow to read only headers or body.

## 1.0.0
- Initial version.
