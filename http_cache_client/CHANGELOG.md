## 1.0.6
- fix: pass a 304 through without storing when no cached entry exists to update.
- fix: strip if-none-match/if-modified-since before invoking keyBuilder to keep the cache key stable.
- fix: fall back to cache on any transport error, not just http.ClientException.
- perf: skip the store write on a cache hit while maxStale is still half-window fresh.
- fix: route caching through send() so cacheable requests issued via send() are cached too.
- fix: reuse core getHeaders() in CacheResponse.toResponse (due to previous changes).
- fix: drop double _getCacheOptions resolution in read/readBytes.

## 1.0.5
- fix: Age header refresh on 304 revalidation
- chore: Min SDK is now 3.6.0.

## 1.0.4
- chore: Updated dependencies.

## 1.0.3
- fix: Allow keyBuilder to depend on request body.

## 1.0.2
- fix: BaseRequest now has `headers` getter instead of `headerValuesAsList`.
- chore: Updated dependencies.

## 1.0.1
- fix: Improve cache save time.
- fix: Improve request date assignment.
- fix: bump http to ^1.2.0
- fix: `CacheOptions#maxStale` usage may lead to empty response body.
- feat: Improve performance on cache check when using cipher.

## 1.0.0
- Initial version.
