# 06 — Audio System Design

## Overview

The audio system has two independent services:
- `RecordingService` — handles microphone capture
- `PlaybackService` — handles file playback

They are never coupled; the UI coordinates between them through Riverpod providers.

---

## RecordingService

**Package:** `record`

### Responsibilities
- Request and validate microphone permission before starting
- Start, pause, resume, stop recording
- Write output to app-private audio directory
- Return the final file path and duration on stop

### State Machine
```
IDLE → RECORDING → PAUSED → RECORDING → STOPPED
                              └─────────────────→ IDLE (after save)
```

### API
```dart
abstract class RecordingService {
  Future<void> start(String outputPath);
  Future<void> pause();
  Future<void> resume();
  Future<RecordingResult> stop();  // Returns path + duration
  Stream<RecordingState> get stateStream;
  Stream<Amplitude> get amplitudeStream;  // For waveform visualisation
  Future<void> dispose();
}
```

### Audio Format
| Setting | Value |
|---------|-------|
| Format | AAC (M4A container) |
| Sample rate | 44,100 Hz |
| Bit rate | 128 kbps |
| Channels | Mono (sufficient for voice) |

---

## PlaybackService

**Package:** `just_audio`

### Responsibilities
- Load an audio file by path
- Play, pause, seek
- Report current position and duration as streams
- Handle audio focus (duck/pause when interrupted by calls, other apps)

### API
```dart
abstract class PlaybackService {
  Future<void> load(String filePath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();
  Stream<PlaybackState> get stateStream;
  Stream<Duration> get positionStream;
  Duration? get totalDuration;
}
```

---

## Audio Focus & Interruptions

| Event | Behaviour |
|-------|-----------|
| Incoming phone call | Pause recording; surface "recording paused" message |
| Notification sound | Duck (reduce volume) during playback |
| Other app requests audio focus | Pause playback |
| Headphones unplugged mid-recording | Pause recording; notify user |
| Headphones unplugged mid-playback | Pause playback |

---

## File Management

- Audio files are **never deleted** automatically
- Deleting a diary entry deletes its associated audio file
- Orphan cleanup: on launch, scan audio directory for files with no matching DB entry and delete them
- File name: `<UUID>.m4a` — no personal info in filename

---

## Permissions

| Platform | Permission | Notes |
|----------|-----------|-------|
| Android | `RECORD_AUDIO` | Requested before first recording only |
| iOS | `NSMicrophoneUsageDescription` | Info.plist key + runtime request |

Permission is requested only when the user taps "Record". Never on launch.
