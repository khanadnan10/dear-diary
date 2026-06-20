import 'dart:async';

enum AudioActivity { idle, recording, playing }

abstract class AudioRepository {
  AudioActivity get currentActivity;
  Stream<AudioActivity> get activityStream;

  // Recording API
  Future<bool> hasPermission();
  Future<void> startRecording(String path);
  Future<String?> stopRecording();
  Stream<double> get amplitudeStream;
  bool get isRecording;

  // Playback API
  Future<void> startPlayback(String path);
  Future<void> stopPlayback();
  Future<void> pausePlayback();
  Future<void> resumePlayback();
  Future<void> seek(Duration position);
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<bool> get isPlayingStream;
  bool get isPlaying;
}
