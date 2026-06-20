# 02 — MVP Feature Specifications

## Feature List

---

### F-01: Text Journaling

**Description:** User can write a free-form text entry.  
**Acceptance Criteria:**
- Text is encrypted before being written to the database
- Auto-save triggers every 30 seconds and on app background
- No character limit enforced (handle large entries gracefully)
- Entry creation timestamp is stored in UTC; displayed in local time
- Edit mode available for existing entries

---

### F-02: Voice Recording Journaling

**Description:** User can record audio as a diary entry.  
**Acceptance Criteria:**
- Recording starts/stops via a single tap
- Pause and resume supported during a session
- Recording is stored in app-private directory (not in media gallery)
- `.nomedia` file placed in audio directory to prevent gallery indexing
- Duration is stored with the entry
- Playback available from entry detail view

---

### F-03: Biometric Lock

**Description:** App is locked behind biometric (fingerprint/face) authentication.  
**Acceptance Criteria:**
- Auth is required on every cold launch
- Auth is required after a configurable session timeout (default: 5 minutes)
- Falls back to device PIN/pattern if biometric unavailable
- If device has no lock screen, prompt user to set one (do not bypass)
- App content is never visible in app switcher (screenshot prevention)

---

### F-04: Local Encrypted Storage

**Description:** All data is stored locally and encrypted.  
**Acceptance Criteria:**
- Text entries encrypted with AES-256 before persistence
- Encryption key stored in `flutter_secure_storage` (Keychain on iOS, Keystore on Android)
- Key is never logged or exposed in plaintext
- Database file is stored in app-private directory
- Audio files stored in app-private directory

---

### F-05: Hide Recordings from Gallery

**Description:** Audio files must not appear in the device media library.  
**Acceptance Criteria:**
- `.nomedia` file present in all audio storage directories (Android)
- Audio stored in app-private directories (iOS sandbox handles this automatically)
- Validate this behavior on Android 10+

---

### F-06: Theme Mode (Light / Dark)

**Description:** User can switch between light and dark themes.  
**Acceptance Criteria:**
- Respects system-level dark mode by default
- Manual override available in settings
- Preference persisted across sessions
- Transitions are smooth (no harsh flicker)

---

### F-07: Search

**Description:** User can search across diary entries.  
**Acceptance Criteria:**
- Text entries are searchable by content
- Search is local-only; no external indexing
- Results show entry date and a snippet
- Minimum query: 2 characters
- Debounce: 300ms before triggering search

---

### F-08: Minimalist UI

**Description:** Interface is distraction-free and emotionally calm.  
**Acceptance Criteria:**
- No bottom navigation bars with more than 2 items
- No dashboard or home screen widgets
- Entry list is the home screen
- Typography is readable; adequate line height and font size
- No decorative icons or emoji overuse
