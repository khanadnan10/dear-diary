import '../domain/entities/diary_entry.dart';
import '../domain/repositories/diary_repository.dart';
import 'diary_local_datasource.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryLocalDataSource _localDataSource;

  DiaryRepositoryImpl(this._localDataSource);

  @override
  Future<List<DiaryEntry>> getEntries() async {
    return await _localDataSource.getEntries();
  }

  @override
  Future<DiaryEntry?> getEntry(String id) async {
    return await _localDataSource.getEntry(id);
  }

  @override
  Future<void> saveEntry(DiaryEntry entry) async {
    await _localDataSource.saveEntry(entry);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _localDataSource.deleteEntry(id);
  }

  @override
  Future<bool> hasEntries() async {
    return await _localDataSource.hasEntries();
  }
}
