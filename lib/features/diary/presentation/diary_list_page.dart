import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/entities/diary_entry.dart';
import 'providers/diary_provider.dart';

class DiaryListPage extends ConsumerWidget {
  const DiaryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(diaryEntriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dear Diary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'serif',
                fontSize: 26,
              ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search entries',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildEntriesList(context, ref, entries);
        },
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (error, _) => _buildErrorState(context, ref, error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
        foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Entry', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => _showEntryTypeSelector(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.spa_outlined, // SPA icon feels extremely calm and premium
              size: 72,
              color: isDark ? AppTheme.darkPrimary.withOpacity(0.5) : AppTheme.lightPrimary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'A silent canvas awaits',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'serif',
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Capture your thoughts, ideas, or spoken words securely. Every entry you make here is fully encrypted on your device.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(BuildContext context, WidgetRef ref, List<DiaryEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: entries.length + 1, // +1 for the privacy shield notice at the top
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSecurityNotice(context);
        }
        final entry = entries[index - 1];
        return _buildEntryCard(context, ref, entry);
      },
    );
  }

  Widget _buildSecurityNotice(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_rounded,
            size: 18,
            color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your diary is protected with military-grade AES-256-GCM encryption.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, WidgetRef ref, DiaryEntry entry) {
    final isText = entry.type == EntryType.text;
    final dateStr = DateFormatter.formatDate(entry.createdAt);
    final timeStr = DateFormatter.formatDateWithTime(entry.createdAt).split('at').last.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/entry/${entry.id}?type=${isText ? 'text' : 'audio'}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isText ? Icons.edit_note_rounded : Icons.mic_none_rounded,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isText)
                Text(
                  entry.text != null && entry.text!.trim().isNotEmpty
                      ? entry.text!
                      : 'Empty journal entry...',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: entry.text != null && entry.text!.trim().isNotEmpty
                            ? null
                            : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                )
              else
                _buildAudioPreview(context, entry),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPreview(BuildContext context, DiaryEntry entry) {
    final durationStr = entry.duration != null ? DateFormatter.formatDuration(entry.duration!) : '00:00';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voice Recording', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              durationStr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.alertColor),
            const SizedBox(height: 16),
            const Text('Could not load entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(diaryEntriesProvider.notifier).load(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final id = const Uuid().v4();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like to create?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: 'serif'),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_note_rounded, color: Theme.of(context).primaryColor),
                  ),
                  title: const Text('Written Reflection', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Reflect and draft structured notes with rich typography'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/entry/$id?type=text');
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.mic_rounded, color: Theme.of(context).primaryColor),
                  ),
                  title: const Text('Spoken Entry', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Record audio with secure, on-device encryption'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/entry/$id?type=audio');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
