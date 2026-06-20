# Edge Cases — 03: Auth & Security

---

## EC-AS-01: Biometric Hardware Unavailable (No Enrollment)

**Trigger:** Device has a fingerprint sensor but no fingerprint enrolled; or device has no biometric at all.  
**Risk:** App is permanently locked to the user.

**Handling:**
- Use `local_auth.isDeviceSupported()` and `local_auth.getAvailableBiometrics()` on launch
- If device supports lock screen but has no biometrics enrolled: fall back to PIN/pattern automatically
- If device has no lock screen at all:
  - Show a blocking screen: "Dear Diary requires a device lock screen to protect your entries. Please set one up in your device settings."
  - Provide a button to open security settings
  - Do not allow the app to proceed without a lock screen

---

## EC-AS-02: Biometric Authentication Fails Repeatedly

**Trigger:** User fails biometric several times (dirty sensor, different finger).  
**Risk:** OS lockout; user can't access their journal.

**Handling:**
- `local_auth` with `stickyAuth: true` handles OS-level lockout gracefully
- After OS lockout fires, OS presents PIN/pattern fallback — do not intercept this
- Do not implement your own lockout counter — the OS manages this
- Provide a visible "Use PIN instead" button from the start, not just after failures

---

## EC-AS-03: Encryption Key Lost (Secure Storage Wiped)

**Trigger:** On some Android versions, a factory reset of the Keystore (e.g., after adding a new fingerprint) wipes `flutter_secure_storage`.  
**Risk:** Existing encrypted entries become permanently undecryptable.

**Handling:**
- This is a catastrophic, unrecoverable state — entries encrypted with the old key cannot be decrypted
- Detect: key is missing, but Isar DB and audio files still exist
- Show a dedicated screen: "Your diary's encryption key was reset by your device. Unfortunately, your previous entries can no longer be read. You can start fresh."
- Offer: "Delete all data and start fresh" (with confirmation) or "Keep old data" (entries remain but are unreadable)
- Do NOT silently generate a new key and show garbage decryption results
- Log the event with full diagnostic context (Android security level, OS version)

**Prevention note for future:** Consider storing an encrypted export before any key rotation — add to roadmap.

---

## EC-AS-04: App Reinstall on iOS (Keychain Key Survives)

**Trigger:** User deletes and reinstalls the app on iOS. Isar DB is gone, but the Keychain key persists.  
**Risk:** Key references entries that no longer exist; confusing state.

**Handling:**
- On first launch (empty DB detected), check if a key already exists in secure storage
- If DB is empty AND key exists: delete the stale key and generate a new one
- This is a normal first-launch state; show empty entry list

---

## EC-AS-05: Session Timeout Fires During Active Write

**Trigger:** User is mid-sentence in an entry; session timeout fires.  
**Risk:** Entry lost if unsaved; confusing UX interruption.

**Handling:**
- Auto-save current text entry state before triggering the lock screen
- On re-authentication, restore the user to the exact point they were at
- The lock overlay should be applied on top, not by navigating away
- Show lock overlay as a full-screen widget in the widget tree; do not pop the entry page

---

## EC-AS-06: App in Background — Content Visible in Switcher

**Trigger:** User background switches before the blur/secure overlay applies.  
**Risk:** Entry content visible in app switcher screenshot.

**Handling (Android):**
- `FLAG_SECURE` is set at Activity level — OS never captures a screenshot of a FLAG_SECURE window; app switcher shows a blank frame
- This is set permanently, not just when switching

**Handling (iOS):**
- Observe `UIApplication.willResignActiveNotification`
- On notification: add a full-screen blur overlay widget instantly
- On `didBecomeActiveNotification`: trigger re-auth, then remove overlay

---

## EC-AS-07: Multiple Biometric Prompts Stacking

**Trigger:** App goes to background and returns multiple times quickly; multiple auth prompts stack.  
**Risk:** OS prompt appears multiple times; confusing UX.

**Handling:**
- Use a boolean flag `_isAuthInProgress` in `AuthService`
- If auth is already in progress, do not trigger a new `authenticate()` call
- Cancel any pending auth on `AppLifecycleState.paused` before starting a new one on resume
