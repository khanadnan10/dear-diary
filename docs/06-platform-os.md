# Edge Cases — 06: Platform & OS

---

## EC-PL-01: App Update Breaks Isar Schema

**Trigger:** New app version ships with a modified `DiaryEntryIsar` model without a migration.  
**Risk:** Isar throws on open; all data inaccessible.

**Handling:**
- Isar detects schema mismatch at open time and throws `IsarError`
- Always bump `schemaVersion` in `Isar.open()` config when model changes
- Write a migration function for every schema change before shipping
- Automated test: open DB with old schema, run migration, verify data

---

## EC-PL-02: Android OEM Battery Optimization Kills Audio

**Trigger:** Aggressive OEM battery management (Xiaomi, Huawei, Samsung) restricts background processing; audio recording may be interrupted.  
**Risk:** Recording stops mid-session without user action.

**Handling:**
- App only records in the foreground — document this constraint
- On affected OEMs, show a one-time message: "Your device's battery settings may interrupt recordings. If recordings stop unexpectedly, whitelist Dear Diary in battery settings."
- Detect OEM via `Platform.operatingSystemVersion` or `device_info_plus` — prompt only on known aggressive OEMs
- Provide Settings deep-link

---

## EC-PL-03: iOS Background App Refresh Disabled

**Trigger:** User disables Background App Refresh for the app on iOS.  
**Risk:** No impact for this app (no background tasks); document for future use.

**Handling:**
- No current impact — app has no background tasks
- Note for future: if transcription or export is added, this setting must be respected

---

## EC-PL-04: OS Upgrade Invalidates Keychain / Keystore

**Trigger:** Major OS upgrade (rarely, but documented to occur on Android security patch changes) resets Keystore keys.  
**Risk:** Same as EC-AS-03: existing entries undecryptable.

**Handling:**
- Same flow as EC-AS-03
- Detect on launch: attempt to read the key; if it throws a `PlatformException`, treat as key loss
- Present the key-loss screen (preserve data, start fresh option)

---

## EC-PL-05: Flutter Engine Upgrade Changes Behavior

**Trigger:** Flutter engine or package upgrade changes serialization, widget behavior, or platform channel behavior.  
**Risk:** Regression in encryption, storage, or audio.

**Handling:**
- Pin critical package versions in `pubspec.yaml` (no `^` on `isar`, `flutter_secure_storage`, `record`, `just_audio`)
- Only upgrade after explicit testing
- Maintain a regression test suite covering: save/load/decrypt entry, record/play audio, biometric auth flow

---

## EC-PL-06: App Running on Emulator / Non-Secure Device

**Trigger:** Developer or tester runs the app on an emulator without biometric hardware.  
**Risk:** Auth loop that can't be completed; blocks development.

**Handling:**
- In debug mode: add a `kDebugMode` bypass for biometric auth (must be removed in release builds, enforced by CI lint check)
- Emulators support soft biometric enrollment via the extended controls panel — document this in the developer README
- Never ship a release build with auth bypass

---

## EC-PL-07: App Installed on Work Profile (Android)

**Trigger:** App installed in an Android work profile with MDM restrictions.  
**Risk:** `flutter_secure_storage` may not have access to hardware-backed Keystore.

**Handling:**
- If Keystore is unavailable: `flutter_secure_storage` falls back to software encryption
- Log a warning: "Hardware-backed key storage unavailable — using software fallback"
- App remains functional; security posture is slightly reduced
- Surface no user-facing warning (the user cannot fix this; informing them only causes anxiety)
