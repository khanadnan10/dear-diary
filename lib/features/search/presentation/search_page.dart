import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import 'providers/search_provider.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          autofocus: true,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'Search your entries...',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            fillColor: Colors.transparent,
          ),
          onChanged: (val) => ref.read(searchProvider.notifier).onQueryChanged(val),
        ),
        actions: [
          if (searchState.query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                ref.read(searchProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: _buildSearchResultsBody(context, searchState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsBody(BuildContext context, SearchState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.query.trim().length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_rounded,
                size: 64,
                color: isDark ? AppTheme.darkPrimary.withOpacity(0.3) : AppTheme.lightPrimary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Search Securely',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Type at least 2 characters. Matches are decrypted on-device for absolute privacy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Text(state.error!, style: const TextStyle(color: AppTheme.alertColor)),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No matches for "${state.query}"',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Double check your spelling or search term.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final result = state.results[index];
        final dateStr = DateFormatter.formatDate(result.entry.createdAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/entry/${result.entry.id}?type=text'),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${result.matchCount} ${result.matchCount == 1 ? 'match' : 'matches'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Snippet text with highlighted match term (case insensitive)
                  _buildRichSnippet(context, result.snippet, state.query),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRichSnippet(BuildContext context, String snippet, String query) {
    final textTheme = Theme.of(context).textTheme.bodyMedium;
    final primaryColor = Theme.of(context).primaryColor;

    final escapedQuery = RegExp.escape(query);
    final regExp = RegExp(escapedQuery, caseSensitive: false);
    final matches = regExp.allMatches(snippet);

    if (matches.isEmpty) {
      return Text(snippet, style: textTheme);
    }

    final List<TextSpan> spans = [];
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: snippet.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: snippet.substring(match.start, match.end),
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          backgroundColor: primaryColor.withOpacity(0.12),
        ),
      ));
      start = match.end;
    }

    if (start < snippet.length) {
      spans.add(TextSpan(text: snippet.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: textTheme?.copyWith(fontSize: 14, height: 1.5),
        children: spans,
      ),
    );
  }
}
