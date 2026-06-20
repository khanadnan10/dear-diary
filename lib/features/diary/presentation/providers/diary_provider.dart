import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/diary_local_datasource.dart';
import '../../data/diary_repository_impl.dart';
import '../../domain/entities/diary_entry.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../domain/usecases/create_entry.dart';
import '../../domain/usecases/update_entry.dart';
import '../../domain/usecases/delete_entry.dart';
import '../../domain/usecases/get_entries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';

final diaryLocalDataSourceProvider = Provider<DiaryLocalDataSource>((ref) {
  return DiaryLocalDataSourceImpl();
});

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final dataSource = ref.watch(diaryLocalDataSourceProvider);
  return DiaryRepositoryImpl(dataSource);
});

final getEntriesUseCaseProvider = Provider<GetEntries>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return GetEntries(repository);
});

final createEntryUseCaseProvider = Provider<CreateEntry>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return CreateEntry(repository);
});

final updateEntryUseCaseProvider = Provider<UpdateEntry>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return UpdateEntry(repository);
});

final deleteEntryUseCaseProvider = Provider<DeleteEntry>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return DeleteEntry(repository);
});

class DiaryEntriesNotifier extends Notifier<AsyncValue<List<DiaryEntry>>> {
  @override
  AsyncValue<List<DiaryEntry>> build() {
    _initialize();
    return const AsyncValue.loading();
  }

  Future<void> _initialize() async {
    try {
      final auth = ref.read(authStateProvider.notifier);
      final dataSource = ref.read(diaryLocalDataSourceProvider);
      
      // Load or generate key
      final dbExists = await dataSource.hasEntries();
      final key = await auth.loadEncryptionKey(dbExists);
      
      await dataSource.initialize(key);
      await load();
    } catch (e, stack) {
      AppLogger.e('Failed to initialize diary datasource', e, stack);
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final getEntries = ref.read(getEntriesUseCaseProvider);
      final list = await getEntries();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> save(DiaryEntry entry) async {
    try {
      final createEntry = ref.read(createEntryUseCaseProvider);
      await createEntry(entry);
      await load(); // Reactive list reload (EC-DI-04)
    } catch (e, stack) {
      AppLogger.e('Error saving entry', e, stack);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final deleteEntry = ref.read(deleteEntryUseCaseProvider);
      await deleteEntry(id);
      await load(); // Reactive list reload
    } catch (e, stack) {
      AppLogger.e('Error deleting entry', e, stack);
      rethrow;
    }
  }
}

final diaryEntriesProvider = NotifierProvider<DiaryEntriesNotifier, AsyncValue<List<DiaryEntry>>>(() => DiaryEntriesNotifier());

/// Specific entry provider to watch detailed state of a single entry (EC-UI-04)
final diaryEntryFamilyProvider = Provider.family<DiaryEntry?, String>((ref, id) {
  final entriesAsync = ref.watch(diaryEntriesProvider);
  return entriesAsync.when(
    data: (list) {
      try {
        return list.firstWhere((e) => e.id == id);
      } catch (_) {
        return null; // Triggers automatic pop/navigation back when watch fires null (EC-UI-04)
      }
    },
    error: (_, __) => null,
    loading: () => null,
  );
});
