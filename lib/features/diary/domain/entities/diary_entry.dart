class DiaryEntry {
  final String id;
  final EntryType type;
  final String? text;
  final String? audioPath;
  final Duration? duration;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry({
    required this.id,
    required this.type,
    this.text,
    this.audioPath,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });

  DiaryEntry copyWith({
    String? id,
    EntryType? type,
    String? text,
    String? audioPath,
    Duration? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum EntryType { text, audio }
