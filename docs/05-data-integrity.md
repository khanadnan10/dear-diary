# Edge Cases — 05: Data Integrity

---

## EC-DI-01: Decryption Fails on a Single Entry

**Trigger:** Entry's encrypted blob is corrupted (bit flip, truncated write, encoding error).  
**Risk:** App crashes when opening that entry; or all entries appear blank.

**Handling:**
- Wrap every decryption call in try/catch
- If decryption fails for an entry: mark it as `corrupted` in a transient in-memory state
- In the entry list: show the entry with a warning icon and "This entry could not be read"
- Do not crash; do not hide the entry; do not delete it
- Provide a "Delete this entry" option
- Log the decryption error with entry ID (not content)

---

## EC-DI-02: Entry Saved with Empty Text

**Trigger:** User opens a text entry, writes nothing (or only whitespace), and exits.  
**Risk:** Empty entries clutter the entry list.

**Handling:**
- On exit from an unsaved text entry: check if content is empty or whitespace-only
- If empty: discard silently (do not save; do not ask for confirmation)
- If the entry was previously saved and user cleared all text: prompt "Delete this entry?"

---

## EC-DI-03: Duplicate Entry ID Collision

**Trigger:** UUID v4 collision (astronomically unlikely but theoretically possible).  
**Risk:** One entry overwrites another.

**Handling:**
- Isar unique index on `id` will throw on collision
- Catch the exception in `saveEntry()`
- Retry with a freshly generated UUID (max 3 retries)
- If all 3 fail (practically impossible): surface a generic save error

---

## EC-DI-04: Entry List Loads Stale Data After Edit

**Trigger:** User edits an entry, returns to list; list shows old content.  
**Risk:** Confusing UX; user thinks save failed.

**Handling:**
- Entry list provider must watch the Isar collection reactively (Isar's `watchLazy` or invalidate the provider on return)
- Use Riverpod's `ref.invalidate()` after any successful mutation
- Test: edit entry → back → list shows updated timestamp

---

## EC-DI-05: Orphaned Audio Files (No DB Entry)

**Trigger:** DB entry deleted but audio file deletion failed (storage error); or app killed between DB delete and file delete.  
**Risk:** Storage waste accumulates silently.

**Handling:**
- On launch (after auth), run an async orphan cleanup job:
  1. List all `.m4a` files in the audio directory
  2. Query all audio paths from DB
  3. Delete files not referenced in DB (after 24-hour grace period to avoid racing with in-progress saves)
- This job runs in a low-priority isolate; does not block launch

---

## EC-DI-06: Clock Skew / Wrong Device Time

**Trigger:** User's device clock is wrong; entries get wrong timestamps.  
**Risk:** Entries sorted by date appear out of order; future-dated entries.

**Handling:**
- Store `createdAt` as UTC `DateTime` — never store local time
- Display in local time using `DateTime.toLocal()`
- No validation of device time — this is user's own data; their clock is their problem
- Sort is always by stored UTC timestamp; visual order matches what the device reported at creation time

---

## EC-DI-07: Very Large Text Entry

**Trigger:** User pastes or writes an extremely long entry (tens of thousands of words).  
**Risk:** Memory pressure; slow encryption; UI jank.

**Handling:**
- No character limit enforced
- Encrypt in a background isolate for entries > 50KB to avoid blocking the main thread
- Test with 100KB text entry: encryption, save, load, decrypt must complete within 500ms
- `TextField` must not lag with large content — use `maxLines: null` (unbounded) which is efficient in Flutter
