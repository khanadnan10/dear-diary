# Edge Cases — 04: Permissions

---

## EC-P-01: Microphone Permission Permanently Denied

**Trigger:** User taps "Don't ask again" on the microphone permission dialog (Android).  
**Risk:** App shows a misleading state — the record button appears but does nothing.

**Handling:**
- Check permission status before showing the record button: `Permission.microphone.status`
- If `permanentlyDenied`: hide the record button, show inline text: "Enable microphone access in Settings to record audio."
- Show a tappable "Open Settings" link
- Re-check permission status on every `AppLifecycleState.resumed`
- On iOS, permission can only be requested once — same pattern applies after first denial

---

## EC-P-02: Microphone Permission Denied on First Request

**Trigger:** User denies the mic permission when first asked.  
**Risk:** Record button appears broken; no explanation.

**Handling:**
- If denied (not permanently): show a dialog explaining why the permission is needed — "Microphone access lets you record audio diary entries. Without it, you can still write text entries."
- Do not re-request immediately — wait until the user taps Record again
- The second tap: show rationale dialog, then request permission again
- Max 2 requests before treating as permanently denied

---

## EC-P-03: Storage Permission (Android < 10)

**Trigger:** On Android 9 and below, `WRITE_EXTERNAL_STORAGE` may be required for app-private directories on certain OEMs.  
**Risk:** File writes fail silently.

**Handling:**
- Target API 29+ (`requestLegacyExternalStorage` is false)
- Use `getApplicationDocumentsDirectory()` which does NOT require storage permission on API 29+
- For Android < 10 support (if in scope): request `WRITE_EXTERNAL_STORAGE` at runtime
- If denied on Android < 10: text entries still work; audio recording is disabled with explanation

---

## EC-P-04: Notification Permission (Android 13+)

**Trigger:** Android 13+ requires explicit `POST_NOTIFICATIONS` permission for foreground service notifications.  
**Risk:** If a foreground service is used for recording, no notification shown = OS kills recording in background.

**Handling:**
- Do not use a foreground service for recording (keep recording in foreground only)
- Recording is only active when app is in foreground — no background recording
- If user backgrounds the app during recording: auto-pause (see EC-A-01)
- This removes the need for notification permission entirely

---

## EC-P-05: All Permissions Denied (Nuclear Case)

**Trigger:** User has denied all optional permissions; opens app for the first time.  
**Risk:** App appears broken.

**Handling:**
- Microphone denied: text journaling works fully; audio tab/button hidden or shows inline explanation
- App must be fully usable for text journaling with zero permissions
- Permissions are optional enhancements, not requirements for core function
