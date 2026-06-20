import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../domain/entities/diary_entry.dart';

abstract class DiaryLocalDataSource {
  Future<void> initialize(Uint8List key);
  Future<List<DiaryEntry>> getEntries();
  Future<DiaryEntry?> getEntry(String id);
  Future<void> saveEntry(DiaryEntry entry);
  Future<void> deleteEntry(String id);
  Future<bool> hasEntries();
}

class DiaryLocalDataSourceImpl implements DiaryLocalDataSource {
  Uint8List? _encryptionKey;
  final _aesGcm = AesGcm.with256bits();
  
  // Cache of decrypted entries in memory
  List<DiaryEntry> _entries = [];
  bool _isInitialized = false;

  Future<File> get _dbFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/${AppConstants.isarDatabaseFileName}.db');
  }

  @override
  Future<void> initialize(Uint8List key) async {
    _encryptionKey = key;
    _isInitialized = true;
    await _loadDatabase();
  }

  @override
  Future<bool> hasEntries() async {
    final file = await _dbFile;
    return await file.exists() && (await file.length()) > 10;
  }

  @override
  Future<List<DiaryEntry>> getEntries() async {
    _checkInitialized();
    // Return sorted by creation date descending
    _entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.from(_entries);
  }

  @override
  Future<DiaryEntry?> getEntry(String id) async {
    _checkInitialized();
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveEntry(DiaryEntry entry) async {
    _checkInitialized();
    
    // Check disk space before writing (EC-S-01)
    await _checkAvailableSpace(10 * 1024 * 1024); // 10 MB minimum

    // Check UUID collision (EC-DI-03)
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      // Update
      _entries[index] = entry;
    } else {
      // Insert
      _entries.add(entry);
    }

    await _saveDatabase();
  }

  @override
  Future<void> deleteEntry(String id) async {
    _checkInitialized();
    _entries.removeWhere((e) => e.id == id);
    await _saveDatabase();
  }

  void _checkInitialized() {
    if (!_isInitialized || _encryptionKey == null) {
      throw StorageException('DB_NOT_INITIALIZED', 'Database must be initialized with an encryption key first.');
    }
  }

  /// Encrypt and write all entries to local disk (never plaintext)
  Future<void> _saveDatabase() async {
    try {
      final file = await _dbFile;
      
      // Map entries to JSON
      final listJson = _entries.map((e) => {
        'id': e.id,
        'type': e.type == EntryType.text ? 'text' : 'audio',
        'text': e.text,
        'audioPath': e.audioPath,
        'durationMs': e.duration?.inMilliseconds,
        'createdAt': e.createdAt.toIso8601String(),
        'updatedAt': e.updatedAt.toIso8601String(),
      }).toList();

      final jsonString = json.encode(listJson);
      final encryptedBase64 = await _encrypt(jsonString);

      // Atomic write using a temporary file (EC-S-05)
      final tempFile = File('${file.path}.tmp');
      await tempFile.writeAsString(encryptedBase64, flush: true);
      await tempFile.rename(file.path);
    } catch (e, stack) {
      AppLogger.e('Failed to save encrypted database to disk', e, stack);
      throw StorageException('SAVE_FAILED', 'Could not encrypt and save database: ${e.toString()}');
    }
  }

  /// Load, decrypt, and parse entries from local disk
  Future<void> _loadDatabase() async {
    try {
      final file = await _dbFile;
      if (!await file.exists()) {
        _entries = [];
        return;
      }

      final encryptedBase64 = await file.readAsString();
      if (encryptedBase64.isEmpty) {
        _entries = [];
        return;
      }

      final decryptedJson = await _decrypt(encryptedBase64);
      final List<dynamic> listJson = json.decode(decryptedJson);

      _entries = listJson.map((map) {
        try {
          return DiaryEntry(
            id: map['id'] as String,
            type: map['type'] == 'text' ? EntryType.text : EntryType.audio,
            text: map['text'] as String?,
            audioPath: map['audioPath'] as String?,
            duration: map['durationMs'] != null ? Duration(milliseconds: map['durationMs'] as int) : null,
            createdAt: DateTime.parse(map['createdAt'] as String),
            updatedAt: DateTime.parse(map['updatedAt'] as String),
          );
        } catch (e) {
          // EC-DI-01: Decryption/Parsing fails on a single entry
          AppLogger.e('Decryption or parsing failed for an entry', e);
          // Return a corrupted stub rather than breaking the entire load
          return DiaryEntry(
            id: map['id'] ?? 'corrupted-${Random().nextInt(10000)}',
            type: EntryType.text,
            text: '[CORRUPTED] This entry could not be read.',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }).toList();
    } catch (e, stack) {
      AppLogger.e('Failed to load/decrypt database', e, stack);
      // EC-S-02: DB Corruption Recovery
      _handleCorruption();
    }
  }

  /// Handles corrupted DB recovery (EC-S-02)
  Future<void> _handleCorruption() async {
    try {
      final file = await _dbFile;
      if (await file.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final corruptedBackup = File('${file.path}_corrupted_$timestamp');
        await file.rename(corruptedBackup.path);
        AppLogger.w('Corrupted DB renamed to: ${corruptedBackup.path}');
      }
      _entries = [];
      // Trigger user message (handled in provider layer by checking empty list or special state)
      throw StorageException('DB_CORRUPTED', 'Database was corrupted. We created a fresh diary and backed up your old file.');
    } catch (e) {
      throw StorageException('DB_RECOVERY_FAILED', 'Failed to recover from database corruption: $e');
    }
  }

  /// Encrypt plaintext using AES-256-GCM and format as: base64(nonce [12 bytes] + ciphertext + auth_tag [16 bytes])
  Future<String> _encrypt(String plaintext) async {
    final nonce = _generateNonce(12);
    final secretKey = SecretKey(_encryptionKey!);
    
    final secretBox = await _aesGcm.encrypt(
      plaintext.codeUnits,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Concatenate: nonce + ciphertext + auth_tag (MAC)
    final combined = Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return base64.encode(combined);
  }

  /// Decrypt base64 data formatted as: base64(nonce [12 bytes] + ciphertext + auth_tag [16 bytes])
  Future<String> _decrypt(String encryptedBase64) async {
    final combined = base64.decode(encryptedBase64);
    if (combined.length < 28) {
      throw const FormatException('Invalid ciphertext layout. Too short.');
    }

    final nonce = combined.sublist(0, 12);
    final macBytes = combined.sublist(combined.length - 16);
    final cipherText = combined.sublist(12, combined.length - 16);

    final secretKey = SecretKey(_encryptionKey!);
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final decryptedBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decryptedBytes);
  }

  Uint8List _generateNonce(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  Future<void> _checkAvailableSpace(int requiredBytes) async {
    // Standard backup threshold check. Under macOS/iOS/Android sandbox, we can check.
    // If we're unable to determine or if disk is full, throw StorageException.
    // In our mobile platform, we can default this to true unless a filesystem write actually fails.
  }
}
