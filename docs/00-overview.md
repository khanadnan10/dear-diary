# Edge Cases — Overview

> "Antigravity" edge cases are the failure modes that don't happen in the happy path demo, but will happen to real users. This section is non-negotiable for production quality.

---

## Why This Section Exists

A journaling app handles **personal, irreplaceable data**. Unlike a to-do app, a corrupted or inaccessible diary entry cannot be recreated. The emotional trust the user places in this app demands that every edge case be handled thoughtfully and non-destructively.

---

## Edge Case Files

| File | Domain |
|------|--------|
| [`01-storage.md`](01-storage.md) | Disk full, DB corruption, migration failures |
| [`02-audio.md`](02-audio.md) | Interrupted recording, missing files, codec failures |
| [`03-auth-security.md`](03-auth-security.md) | Biometric failure, key loss, app resets |
| [`04-permissions.md`](04-permissions.md) | Denied microphone, storage, and lock screen |
| [`05-data-integrity.md`](05-data-integrity.md) | Encryption errors, partial saves, orphaned files |
| [`06-platform-os.md`](06-platform-os.md) | Android/iOS version quirks, app updates, OS upgrades |
| [`07-ui-state.md`](07-ui-state.md) | Navigation, background/foreground transitions, rapid taps |

---

## General Principles for Edge Case Handling

1. **Never silently discard data.** If a save fails, tell the user and give them a retry.
2. **Fail loudly in debug, gracefully in production.** Use `assert` for developer errors; show friendly messages for user-facing failures.
3. **Never delete data to solve a problem.** If a file is corrupt, quarantine it — don't remove it.
4. **Prefer no-op over crash.** If a feature can't work right now (e.g., mic permission denied), disable the UI path — don't throw.
5. **Log everything, surface only what's actionable.** Users don't want stack traces; they want "Something went wrong. Try again."

---

## Error Hierarchy

```dart
abstract class AppException implements Exception {
  final String message;
  final String? technicalDetail;  // For logs only, never shown to user
}

class StorageException extends AppException {}
class AudioException extends AppException {}
class AuthException extends AppException {}
class EncryptionException extends AppException {}
class PermissionException extends AppException {}
```

All exceptions map to a `Failure` in the domain layer, which maps to a user-facing message in the presentation layer.
