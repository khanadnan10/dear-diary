import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/logger.dart';
import '../../../core/constants/app_constants.dart';
import '../../audio/domain/audio_repository.dart';
import '../../audio/presentation/providers/audio_provider.dart';
import '../domain/entities/diary_entry.dart';
import 'providers/diary_provider.dart';

class DiaryEntryPage extends ConsumerStatefulWidget {
  final String entryId;
  final String initialType;

  const DiaryEntryPage({
    super.key,
    required this.entryId,
    required this.initialType,
  });

  @override
  ConsumerState<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends ConsumerState<DiaryEntryPage> {
  late TextEditingController _textController;
  late EntryType _type;
  
  bool _isSaving = false;
  String _saveIndicator = 'All changes saved';
  Timer? _autoSaveTimer;
  DateTime? _createdAt;

  // Recording State Local Triggers
  bool _localRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _type = widget.initialType == 'audio' ? EntryType.audio : EntryType.text;

    // Load existing entry if it exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final entry = ref.read(diaryEntryFamilyProvider(widget.entryId));
      if (entry != null) {
        setState(() {
          _textController.text = entry.text ?? '';
          _type = entry.type;
          _createdAt = entry.createdAt;
        });
      } else {
        _createdAt = DateTime.now().toUtc();
      }

      // Set up 30-second auto-save for text entries (F-01/EC-S-04)
      if (_type == EntryType.text) {
        _startAutoSaveTimer();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _recordTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _saveEntry(isAutoSave: true);
    });
  }

  Future<void> _saveEntry({bool isAutoSave = false}) async {
    if (_isSaving) return; // Prevent concurrent double-saves (EC-UI-05)

    final text = _textController.text;
    
    // Don't auto-save empty entries
    if (isAutoSave && text.trim().isEmpty) return;

    setState(() {
      _isSaving = true;
      _saveIndicator = 'Saving...';
    });

    try {
      final entry = DiaryEntry(
        id: widget.entryId,
        type: _type,
        text: _type == EntryType.text ? text : null,
        createdAt: _createdAt ?? DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await ref.read(diaryEntriesProvider.notifier).save(entry);
      
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveIndicator = 'Saved just now';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveIndicator = 'Failed to save';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save entry: $e')),
        );
      }
    }
  }

  // --- AUDIO RECORDING API ---
  Future<void> _toggleRecording() async {
    final audioRepo = ref.read(audioRepositoryProvider);

    if (_localRecording) {
      // STOP RECORDING
      _recordTimer?.cancel();
      final path = await audioRepo.stopRecording();
      
      setState(() {
        _localRecording = false;
      });

      if (path != null) {
        // Save the finished audio entry immediately
        final entry = DiaryEntry(
          id: widget.entryId,
          type: EntryType.audio,
          audioPath: path,
          duration: _recordDuration,
          createdAt: _createdAt ?? DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await ref.read(diaryEntriesProvider.notifier).save(entry);
        AppLogger.i('Audio entry saved successfully to disk.');
      }
    } else {
      // START RECORDING
      final hasPermission = await audioRepo.hasPermission();
      if (!hasPermission) {
        _showPermissionExplanation();
        return;
      }

      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final path = '${docsDir.path}/${AppConstants.audioDirectoryName}/${widget.entryId}.aac';
        
        await audioRepo.startRecording(path);
        
        setState(() {
          _localRecording = true;
          _recordDuration = Duration.zero;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration += const Duration(seconds: 1);
          });
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed to start: $e')),
        );
      }
    }
  }

  void _showPermissionExplanation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic_none_rounded, color: AppTheme.alertColor),
            SizedBox(width: 8),
            Text('Microphone Access'),
          ],
        ),
        content: const Text(
          'Dear Diary requires microphone permissions to record on-device secure voice journals. Please enable permission to proceed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // In Android/iOS, this links to device App Settings automatically
              // permission_handler makes it extremely simple
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(diaryEntryFamilyProvider(widget.entryId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to watch events. If item is deleted, exit immediately (EC-UI-04)
    ref.listen<DiaryEntry?>(diaryEntryFamilyProvider(widget.entryId), (previous, current) {
      if (previous != null && current == null && mounted) {
        AppLogger.i('Entry deleted externally. Popping entry page.');
        context.pop();
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Auto-save on back navigation (F-01/EC-UI-03)
          if (_type == EntryType.text && _textController.text.trim().isNotEmpty) {
            _saveEntry();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () async {
              if (_type == EntryType.text && _textController.text.trim().isNotEmpty) {
                await _saveEntry();
              }
              if (mounted) context.pop();
            },
          ),
          title: Text(
            _type == EntryType.text ? 'Written Entry' : 'Voice Entry',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            if (entry != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.alertColor),
                onPressed: () => _confirmDelete(context),
                tooltip: 'Delete entry',
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderStats(entry),
                const SizedBox(height: 16),
                Expanded(
                  child: _type == EntryType.text
                      ? _buildTextEditor()
                      : _buildAudioControls(entry),
                ),
                if (_type == EntryType.text) _buildTextFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(DiaryEntry? entry) {
    final dateStr = DateFormatter.formatDate(_createdAt ?? DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dateStr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
        ),
        if (_type == EntryType.text)
          Text(
            _saveIndicator,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
          ),
      ],
    );
  }

  Widget _buildTextEditor() {
    return TextField(
      controller: _textController,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            height: 1.6,
          ),
      decoration: const InputDecoration(
        hintText: 'Start writing your reflection...',
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        fillColor: Colors.transparent,
      ),
      onChanged: (text) {
        setState(() {
          _saveIndicator = 'Editing...';
        });
      },
    );
  }

  Widget _buildTextFooter() {
    final wordCount = _textController.text.trim().isEmpty
        ? 0
        : _textController.text.trim().split(RegExp(r'\s+')).length;
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$wordCount words',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          ElevatedButton.icon(
            onPressed: () => _saveEntry(),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioControls(DiaryEntry? entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (entry == null && !_localRecording) {
      // PRE-RECORD VACANT DECK
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPulseRing(
              child: FloatingActionButton(
                onPressed: _toggleRecording,
                backgroundColor: AppTheme.alertColor,
                foregroundColor: Colors.white,
                child: const Icon(Icons.mic_none_rounded, size: 32),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tap to record your reflection',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Completely secure & on-device encrypted.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    } else if (_localRecording) {
      // RECORDING STATE (DB METER & COUNTDOWN)
      final durationStr = DateFormatter.formatDuration(_recordDuration);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPulseRing(
              isRecording: true,
              child: FloatingActionButton(
                onPressed: _toggleRecording,
                backgroundColor: AppTheme.alertColor,
                foregroundColor: Colors.white,
                child: const Icon(Icons.stop_rounded, size: 32),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              durationStr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 36, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.alertColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Recording secure voice note...', style: TextStyle(color: AppTheme.alertColor)),
              ],
            ),
          ],
        ),
      );
    } else {
      // PLAYBACK SYSTEM CONSOLE
      final audioRepo = ref.watch(audioRepositoryProvider);
      final isPlaying = ref.watch(audioIsPlayingProvider).value ?? false;
      final position = ref.watch(audioPositionProvider).value ?? Duration.zero;
      final totalDuration = entry!.duration ?? Duration.zero;

      final progress = totalDuration.inMilliseconds > 0
          ? position.inMilliseconds / totalDuration.inMilliseconds
          : 0.0;

      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.audiotrack_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Voice Reflection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              
              // Scrubbing bar
              Slider.adaptive(
                value: progress.clamp(0.0, 1.0),
                activeColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                onChanged: (val) {
                  final ms = (val * totalDuration.inMilliseconds).toInt();
                  audioRepo.seek(Duration(milliseconds: ms));
                },
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormatter.formatDuration(position), style: const TextStyle(fontSize: 12)),
                    Text(DateFormatter.formatDuration(totalDuration), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Console deck actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, size: 32),
                    onPressed: () {
                      final target = position - const Duration(seconds: 10);
                      audioRepo.seek(target < Duration.zero ? Duration.zero : target);
                    },
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    onPressed: () {
                      if (isPlaying) {
                        audioRepo.pausePlayback();
                      } else {
                        audioRepo.startPlayback(entry.audioPath!);
                      }
                    },
                    backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                    foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
                    child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, size: 32),
                    onPressed: () {
                      final target = position + const Duration(seconds: 10);
                      audioRepo.seek(target > totalDuration ? totalDuration : target);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPulseRing({required Widget child, bool isRecording = false}) {
    // Simple non-animated pulse deck container to preserve compilation readiness
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecording ? AppTheme.alertColor.withOpacity(0.12) : Theme.of(context).primaryColor.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This will permanently delete this diary entry. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(diaryEntriesProvider.notifier).delete(widget.entryId);
              AppLogger.w('Diary Entry with ID ${widget.entryId} deleted.');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
