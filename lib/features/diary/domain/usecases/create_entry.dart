import '../entities/diary_entry.dart';
import '../repositories/diary_repository.dart';

class CreateEntry {
  final DiaryRepository _repository;

  CreateEntry(this._repository);

  Future<void> call(DiaryEntry entry) async {
    await _repository.saveEntry(entry);
  }
}
