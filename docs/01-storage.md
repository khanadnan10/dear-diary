# Edge Cases — 01: Storage

---

## EC-S-01: Device Storage Full When Saving Entry

**Trigger:** User taps save; disk has < required space.  
**Risk:** Entry lost, partial write corrupts DB.

**Handling:**
- Check available space before writing (`getApplicationDocumentsDirectory` + `StatFs` on Android, `NSFileManager` on iOS)
- Minimum threshold: 10MB free before allowing any write
- If below threshold: show dialog — "Your device is almost out of storage. Free up space to save your entry."
- Provide a "Copy text to clipboard" escape hatch so the user doesn't lose their words
- Do NOT attempt partial writes

**Code touchpoint:** `DiaryLocalDataSource.saveEntry()` — wrap write in pre-flight space check.

---

## EC-S-02: Isar Database Fails to Open

**Trigger:** DB file corrupted (e.g., power loss mid-write, filesystem error).  
**Risk:** App is completely unusable.

**Handling:**
1. Catch Isar open failure in a try/catch
2. Attempt to open in recovery mode (Isar supports schema verification)
3. If unrecoverable: rename the corrupted DB file to `diary_corrupted_<timestamp>.isar` (preserve it, don't delete)
4. Create a fresh empty DB
5. Show a one-time message: "We had trouble reading your diary. Some entries may be unavailable. Your old data has been preserved."
6. Log the error with full technical detail

**Never:** Silently swallow the error and start fresh without telling the user.

---

## EC-S-03: Isar Schema Migration Failure

**Trigger:** App update introduces a schema change; migration script throws.  
**Risk:** All entries inaccessible post-update.

**Handling:**
- Always test migrations against real data snapshots before shipping
- Migration must be transactional: either full success or full rollback
- If migration fails: preserve pre-migration DB, open app in read-only mode, show "Update error" screen with support contact
- Provide an export-before-migrate path in future versions

**Prevention:**
- Isar schema version must be bumped on any model change
- Migration scripts live in `MigrationService` with version-keyed methods
- Add unit tests for each migration

---

## EC-S-04: Audio File Missing When Entry is Opened

**Trigger:** Audio entry exists in DB but the `.m4a` file has been deleted (e.g., by a cleaner app, manual file manager use, or failed save).  
**Risk:** User sees a broken playback UI.

**Handling:**
- On opening an audio entry, check if `audioPath` file exists before rendering player
- If missing: show "This recording could not be found. It may have been removed by another app."
- Offer a "Delete entry" option to clean up the orphaned DB record
- Do NOT crash or show a broken player widget

**Code touchpoint:** `PlaybackService.load()` — pre-flight `File.exists()` check.

---

## EC-S-05: Write Interrupted Mid-Save (App Killed / Crash)

**Trigger:** OS kills app during a save operation.  
**Risk:** Partial write creates a corrupt entry.

**Handling:**
- Use Isar's transactional write API — writes are atomic; partial writes are rolled back automatically
- For audio: write to a temp file first (`<uuid>.tmp.m4a`), rename to final path only on successful recording stop
- On next launch, scan for `.tmp.m4a` files and delete them (they're incomplete recordings)

---

## EC-S-06: App Data Cleared by User (Settings → Clear Storage)

**Trigger:** User clears app data via Android Settings.  
**Risk:** All entries and encryption key are gone. App should not crash on next launch.

**Handling:**
- On launch, detect missing encryption key in secure storage
- Treat as first launch: generate new key, show empty entry list
- Do not show an error — this is an intentional user action
- On iOS, `flutter_secure_storage` data may survive app reinstall (Keychain persists); check for this and handle the case where DB is gone but key still exists (treat as first launch, discard stale key)
