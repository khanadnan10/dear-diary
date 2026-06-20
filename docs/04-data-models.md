# 04 — Data Models & Storage Design

## Diary Entry (Domain Entity)

```dart
class DiaryEntry {
  final String id;           // UUID v4
  final EntryType type;      // EntryType.text | EntryType.audio
  final String? text;        // Decrypted text (null for audio entries)
  final String? audioPath;   // Absolute path to audio file (null for text entries)
  final Duration? duration;  // Audio duration (null for text entries)
  final DateTime createdAt;  // UTC
  final DateTime updatedAt;  // UTC
}

enum EntryType { text, audio }
```

---

## Isar Model (Data Layer)

```dart
@collection
class DiaryEntryIsar {
  Id get isarId => fastHash(id);

  @Index(unique: true)
  late String id;

  late String type;           // "text" or "audio"
  late String? encryptedText; // AES-encrypted ciphertext
  late String? audioPath;
  late int? durationMs;
  late DateTime createdAt;
  late DateTime updatedAt;
}
```

### Notes
- `encryptedText` is the only field that contains sensitive data
- `audioPath` is a relative path from the app documents directory
- Full-text search index is applied on `encryptedText` — **this requires that the search index is built on decrypted content in memory**, never stored as plaintext in the index
- Isar collection lives at: `<appDocDir>/diary.isar`

---

## Audio File Storage

```
<appDocumentsDir>/
└── audio/
    ├── .nomedia          ← Prevents Android gallery indexing
    ├── 2024/
    │   └── 03/
    │       ├── <uuid>.m4a
    │       └── <uuid>.m4a
    └── 2025/
        └── 01/
            └── <uuid>.m4a
```

- Format: AAC/M4A (`.m4a`) — good compression, native support on both platforms
- Files named by UUID — no date metadata in filename
- Year/month subdirectory for manageable directory sizes
- On iOS: automatically in app sandbox, not accessible to other apps
- On Android: stored in `getApplicationDocumentsDirectory()`, not in `Downloads` or `DCIM`

---

## Encryption Key Storage

```
Key name: "diary_encryption_key"
Storage:  flutter_secure_storage
          → iOS:     Keychain (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
          → Android: EncryptedSharedPreferences backed by Keystore
```

Key is generated once on first launch:
```dart
final key = generateSecureRandomBytes(32); // 256-bit AES key
await secureStorage.write(key: 'diary_encryption_key', value: base64.encode(key));
```

---

## Database Migration Strategy

- Isar schema versions are tracked via `@collection` schema hash
- A `MigrationService` class handles version upgrades
- Breaking schema changes increment the `schemaVersion` in Isar config
- Migrations run before any read/write operations on launch
- Migration failures must be surfaced to the user — **never silently corrupt data**

---

## Settings Storage

Settings are stored in `flutter_secure_storage` (not `SharedPreferences`) to prevent plaintext exposure in backups:

| Key | Type | Default |
|-----|------|---------|
| `theme_mode` | String (`system`/`light`/`dark`) | `system` |
| `session_timeout_minutes` | int | `5` |
| `screenshot_prevention` | bool | `true` |
