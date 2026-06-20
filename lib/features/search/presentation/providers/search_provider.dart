import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../diary/presentation/providers/diary_provider.dart';
import '../../domain/search_usecase.dart';

final searchUseCaseProvider = Provider<SearchUseCase>((ref) {
  final repository = ref.watch(diaryRepositoryProvider);
  return SearchUseCase(repository);
});

class SearchState {
  final String query;
  final bool isLoading;
  final List<SearchResult> results;
  final String? error;

  SearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.error,
  });

  SearchState copyWith({
    String? query,
    bool? isLoading,
    List<SearchResult>? results,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error ?? this.error,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  late final SearchUseCase _useCase;
  Timer? _debounceTimer;

  @override
  SearchState build() {
    _useCase = ref.watch(searchUseCaseProvider);
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return SearchState();
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query, error: null);
    
    _debounceTimer?.cancel();

    if (query.trim().length < 2) {
      state = state.copyWith(isLoading: false, results: const []);
      return;
    }

    state = state.copyWith(isLoading: true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _useCase(query);
        state = state.copyWith(isLoading: false, results: results);
      } catch (e) {
        state = state.copyWith(isLoading: false, error: 'Search failed. Please try again.');
      }
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    state = SearchState();
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(() => SearchNotifier());
