# Edge Cases — 02: Audio

---

## EC-A-01: Phone Call Interrupts Active Recording

**Trigger:** Incoming call while user is recording an entry.  
**Risk:** Recording stops unexpectedly; user unaware; audio file may be incomplete.

**Handling:**
- Subscribe to `AppLifecycleState` changes in `RecordingService`
- On `paused`: automatically pause the recording (not stop)
- Show a persistent banner: "Recording paused — call in progress"
- On `resumed`: do NOT auto-resume — wait for user tap (they may not want to continue)
- The partial recording up to the pause point is preserved

---

## EC-A-02: Recording Stops Due to Audio Focus Loss

**Trigger:** Another app (music, video, navigation) requests audio focus.  
**Risk:** Recording silently stops or produces silence.

**Handling:**
- Handle `AudioInterruptionEvent` from the `record` package
- On focus loss: pause recording, show banner "Recording paused — another app is using audio"
- Same resume-on-user-tap rule applies

---

## EC-A-03: Microphone Permission Denied Mid-Session

**Trigger:** User revokes microphone permission in system settings while app is in background, then returns.  
**Risk:** Record button becomes non-functional with no explanation.

**Handling:**
- Re-check permission status on `AppLifecycleState.resumed`
- If permission was revoked: disable record button, show inline message "Microphone access is required to record. Enable it in Settings."
- Provide a deep-link button to app settings (`openAppSettings()` from `permission_handler`)

---

## EC-A-04: Headphones Unplugged During Recording

**Trigger:** User is recording with headphones; headphones are removed.  
**Risk:** On Android, audio routing changes may stop recording or cause distorted output.

**Handling:**
- Subscribe to audio output device change events
- On headphone removal during recording: pause recording
- Show banner: "Headphones disconnected. Recording paused."
- Allow user to resume on device speaker or reconnected headphones

---

## EC-A-05: Recording Produces Zero-Byte File

**Trigger:** Hardware issue, permission race condition, or codec failure results in an empty file.  
**Risk:** Entry saved with a broken audio reference.

**Handling:**
- After `RecordingService.stop()`, validate file size > 0 before saving to DB
- If file is empty or missing: show "Recording failed. Please try again."
- Delete the zero-byte file
- Do not create a DB entry for the failed recording

---

## EC-A-06: Storage Full During Recording

**Trigger:** Device runs out of space while a long recording is in progress.  
**Risk:** Recording truncated; codec may produce an unplayable file.

**Handling:**
- Monitor available storage every 30 seconds during recording
- When free space drops below 50MB: show persistent warning "Storage is almost full — recording may stop soon"
- When free space drops below 10MB: stop recording automatically, save whatever was captured
- Notify user: "Recording stopped — your device is out of storage. The recording up to this point has been saved."

---

## EC-A-07: Audio Entry Playback Fails (Codec Error)

**Trigger:** File exists but `just_audio` throws on load (corrupt file, unsupported codec on old device).  
**Risk:** App crashes or shows broken UI.

**Handling:**
- Catch all `just_audio` exceptions
- Show: "This recording could not be played. The file may be damaged."
- Offer "Delete recording" option
- Log the codec error for debugging

---

## EC-A-08: Very Long Recording (> 1 hour)

**Trigger:** User records an extended session.  
**Risk:** Memory pressure; file size issues; UI duration display overflow.

**Handling:**
- No hard limit enforced, but warn at 60 minutes: "You've been recording for 1 hour."
- Duration display must handle hours correctly (`HH:mm:ss` format)
- Validate that M4A container supports the file size (it does; max ~4GB)
- Test on low-end devices with 1GB RAM

---

## EC-A-09: Simultaneous Record + Playback Attempt

**Trigger:** User opens a second entry while recording; or taps Play on a different entry while one is already playing.  
**Risk:** Audio routing conflict; crashes.

**Handling:**
- Enforce a global audio mutex via a Riverpod provider (`ActiveAudioProvider`)
- Starting a new playback stops any active recording (with user confirmation if recording)
- Starting a new playback stops any active playback silently
- Only one active audio session at any time
