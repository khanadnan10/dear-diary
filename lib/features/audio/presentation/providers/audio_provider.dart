import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/audio_repository_impl.dart';
import '../../domain/audio_repository.dart';

final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final repo = AudioRepositoryImpl();
  ref.onDispose(() {
    repo.stopPlayback();
    repo.stopRecording();
  });
  return repo;
});

final audioActivityProvider = StreamProvider<AudioActivity>((ref) {
  return ref.watch(audioRepositoryProvider).activityStream;
});

final audioPositionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioRepositoryProvider).positionStream;
});

final audioDurationProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioRepositoryProvider).durationStream;
});

final audioIsPlayingProvider = StreamProvider<bool>((ref) {
  return ref.watch(audioRepositoryProvider).isPlayingStream;
});
