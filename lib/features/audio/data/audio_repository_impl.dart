import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../domain/audio_repository.dart';

class AudioRepositoryImpl implements AudioRepository {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  AudioActivity _currentActivity = AudioActivity.idle;
  final StreamController<AudioActivity> _activityController = StreamController<AudioActivity>.broadcast();

  String? _currentRecordingPath;
  StreamController<double>? _amplitudeController;
  Timer? _amplitudeTimer;

  AudioRepositoryImpl() {
    _activityController.add(AudioActivity.idle);
    
    // Listen to player playback state to reset idle when playback finishes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stopPlayback();
      }
    });
  }

  @override
  AudioActivity get currentActivity => _currentActivity;

  @override
  Stream<AudioActivity> get activityStream => _activityController.stream;

  @override
  bool get isRecording => _currentActivity == AudioActivity.recording;

  @override
  bool get isPlaying => _currentActivity == AudioActivity.playing && _player.playing;

  // Mutual exclusion (Mutex) check
  void _setActivity(AudioActivity activity) {
    _currentActivity = activity;
    _activityController.add(activity);
    AppLogger.d('Audio global activity changed to: $activity');
  }

  @override
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e, stack) {
      AppLogger.e('Error checking audio permission', e, stack);
      return false;
    }
  }

  @override
  Future<void> startRecording(String path) async {
    // F-03/EC-A-01: Global Mutex Check
    if (_currentActivity == AudioActivity.playing) {
      await stopPlayback();
    }
    if (_currentActivity == AudioActivity.recording) {
      throw AudioException('RECORDING_IN_PROGRESS', 'Already recording an entry.');
    }

    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw PermissionException('RECORD_PERMISSION_DENIED', 'Microphone permission is required.');
    }

    try {
      _currentRecordingPath = path;
      
      // Ensure parent directory exists and .nomedia is created on Android (EC-AS-01)
      final file = File(path);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      
      if (Platform.isAndroid) {
        final nomedia = File('${file.parent.path}/${AppConstants.nomediaFileName}');
        if (!await nomedia.exists()) {
          await nomedia.create();
          AppLogger.i('.nomedia file created at Android app sandbox: ${nomedia.path}');
        }
      }

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _setActivity(AudioActivity.recording);

      // Start decibel/amplitude stream
      _amplitudeController = StreamController<double>.broadcast();
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        if (_currentActivity == AudioActivity.recording) {
          final amp = await _recorder.getAmplitude();
          // Map amplitude value safely to decibels / display-friendly scale
          _amplitudeController?.add(amp.current);
        }
      });

    } catch (e, stack) {
      _setActivity(AudioActivity.idle);
      AppLogger.e('Failed to start recording', e, stack);
      throw AudioException('RECORD_START_FAILED', e.toString());
    }
  }

  @override
  Future<String?> stopRecording() async {
    if (_currentActivity != AudioActivity.recording) return null;

    try {
      _amplitudeTimer?.cancel();
      _amplitudeController?.close();
      _amplitudeController = null;

      final path = await _recorder.stop();
      _setActivity(AudioActivity.idle);
      AppLogger.i('Audio recording finished. Path: $path');
      return path;
    } catch (e, stack) {
      _setActivity(AudioActivity.idle);
      AppLogger.e('Failed to stop recording', e, stack);
      throw AudioException('RECORD_STOP_FAILED', e.toString());
    }
  }

  @override
  Stream<double> get amplitudeStream => _amplitudeController?.stream ?? const Stream.empty();

  @override
  Future<void> startPlayback(String path) async {
    // F-03/EC-A-01: Global Mutex Check
    if (_currentActivity == AudioActivity.recording) {
      throw AudioException('RECORDING_IN_PROGRESS', 'Cannot start playback while recording audio.');
    }

    try {
      // If already playing another file, stop first
      if (_currentActivity == AudioActivity.playing) {
        await stopPlayback();
      }

      final file = File(path);
      if (!await file.exists()) {
        throw AudioException('FILE_NOT_FOUND', 'Audio file does not exist at path.');
      }

      await _player.setFilePath(path);
      _setActivity(AudioActivity.playing);
      await _player.play();
    } catch (e, stack) {
      _setActivity(AudioActivity.idle);
      AppLogger.e('Playback failed to start', e, stack);
      throw AudioException('PLAYBACK_START_FAILED', e.toString());
    }
  }

  @override
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
    } catch (_) {}
    _setActivity(AudioActivity.idle);
  }

  @override
  Future<void> pausePlayback() async {
    if (_currentActivity == AudioActivity.playing) {
      await _player.pause();
    }
  }

  @override
  Future<void> resumePlayback() async {
    if (_currentActivity == AudioActivity.playing) {
      await _player.play();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration> get durationStream => _player.durationStream.map((d) => d ?? Duration.zero);

  @override
  Stream<bool> get isPlayingStream => _player.playingStream;
}
