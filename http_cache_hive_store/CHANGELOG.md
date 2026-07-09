## 5.1.1
- perf: avoid redundant reads and batch deleteFromPath
- fix: Store race condition when cleaning at start and guard RW concurrent calls.
- fix: code duplication.
- fix: make CacheControlAdapter.other field null-safe
- fix: recover from a box closed by another store instance
- fix: initialize IsolatedHive before opening boxes.
- chore: Min SDK is now 3.8.0.

## 5.1.0
- feat: Add Isolated Hive cache store.

## 5.0.2
- chore: Min SDK is now 3.6.0.
- fix: Initialize home directory for box instead of Hive.

## 5.0.1
- feat: Allow to provide a Hive implementation to be used.

## 5.0.0
- feat: Saves response status code.
- chore: Updated dependencies.

## 4.0.0
- feat: Replace `hive` with `hive_ce`.

## 3.2.2
- chore: Updated dependencies.

## 3.2.1
- chore: Updated dependencies.

## 3.2.0
- feat: Add `Store.getFromPath` method.
- feat: Add `Store.deleteFromPath` method.

## 3.1.1
- fix: Now using lazy box to avoid all values loaded into RAM.

## 3.1.0
- Add request date to stored values.
- Add encryptionCipher property for direct usage with Hive.
- Raise dio_cache_interceptor minimum version.

## 3.0.2
- core: Updated dependencies.

## 3.0.1
- fix: imports.

## 3.0.0
- Initial release.