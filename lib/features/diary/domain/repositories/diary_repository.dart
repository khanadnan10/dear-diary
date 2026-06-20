import '../entities/diary_entry.dart';

abstract class DiaryRepository {
  Future<List<DiaryEntry>> getEntries();
  Future<DiaryEntry?> getEntry(String id);
  Future<void> saveEntry(DiaryEntry entry);
  Future<void> deleteEntry(String id);
  Future<bool> hasEntries();
}
