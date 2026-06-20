import '../../diary/domain/entities/diary_entry.dart';
import '../../diary/domain/repositories/diary_repository.dart';

class SearchResult {
  final DiaryEntry entry;
  final String snippet;
  final int matchCount;

  SearchResult({
    required this.entry,
    required this.snippet,
    required this.matchCount,
  });
}

class SearchUseCase {
  final DiaryRepository _repository;

  SearchUseCase(this._repository);

  Future<List<SearchResult>> call(String query) async {
    final sanitizedQuery = query.trim().toLowerCase();
    if (sanitizedQuery.length < 2) {
      return [];
    }

    final entries = await _repository.getEntries();
    final List<SearchResult> results = [];

    for (final entry in entries) {
      if (entry.type == EntryType.text && entry.text != null) {
        final text = entry.text!;
        final textLower = text.toLowerCase();

        if (textLower.contains(sanitizedQuery)) {
          // Count occurrences
          int matchCount = 0;
          int index = 0;
          while ((index = textLower.indexOf(sanitizedQuery, index)) != -1) {
            matchCount++;
            index += sanitizedQuery.length;
          }

          // Build context snippet (~100 chars around match)
          final firstMatchIdx = textLower.indexOf(sanitizedQuery);
          final startIdx = (firstMatchIdx - 40).clamp(0, text.length);
          final endIdx = (firstMatchIdx + sanitizedQuery.length + 50).clamp(0, text.length);

          String snippet = text.substring(startIdx, endIdx);
          if (startIdx > 0) snippet = '...$snippet';
          if (endIdx < text.length) snippet = '$snippet...';

          results.add(SearchResult(
            entry: entry,
            snippet: snippet,
            matchCount: matchCount,
          ));
        }
      }
    }

    return results;
  }
}
