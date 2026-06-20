import '../repositories/diary_repository.dart';

class DeleteEntry {
  final DiaryRepository _repository;

  DeleteEntry(this._repository);

  Future<void> call(String id) async {
    await _repository.deleteEntry(id);
  }
}
