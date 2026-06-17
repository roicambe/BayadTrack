import 'dart:convert';
import '../database/transaction_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// The type of action that triggered this history entry.
enum HistoryActionType { add, edit, delete }

/// The source input method that produced the transaction being logged.
enum HistorySourceType {
  sharedText,   // Shared from GCash / Maya (raw notification text)
  pasteText,    // Paste Manual Text (raw pasted text)
  manualInput,  // Manual keyboard entry
  imageUpload,  // Image uploaded — snapshot of parsed OCR fields
  edit,         // Transaction edited — snapshot of post-save fields
  delete,       // Transaction deleted — snapshot of deleted fields
}

// ─────────────────────────────────────────────────────────────────────────────
// TransactionHistoryEntry
// ─────────────────────────────────────────────────────────────────────────────

/// A single audit/debug record in the transaction history log.
/// Stored as JSON inside SharedPreferences — NOT an Isar collection.
class TransactionHistoryEntry {
  /// Unique entry ID (millisecond timestamp as string).
  final String id;

  /// What action triggered this entry.
  final HistoryActionType action;

  /// What input method was used.
  final HistorySourceType sourceType;

  /// The e-wallet platform of the transaction.
  final Platform platform;

  /// When this history entry was recorded (i.e. when the save/delete happened).
  final DateTime recordedAt;

  /// The full preserved snapshot:
  ///   - For sharedText / pasteText: the raw original text.
  ///   - For manualInput / imageUpload / edit / delete: a formatted field list.
  final String snapshot;

  /// Brief one-line summary shown on the history card (e.g. "₱3,540.00 • CH••••N J. B.").
  final String summary;

  const TransactionHistoryEntry({
    required this.id,
    required this.action,
    required this.sourceType,
    required this.platform,
    required this.recordedAt,
    required this.snapshot,
    required this.summary,
  });

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action.index,
    'sourceType': sourceType.index,
    'platform': platform.index,
    'recordedAt': recordedAt.toIso8601String(),
    'snapshot': snapshot,
    'summary': summary,
  };

  factory TransactionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryEntry(
      id: json['id'] as String,
      action: HistoryActionType.values[json['action'] as int],
      sourceType: HistorySourceType.values[json['sourceType'] as int],
      platform: Platform.values[json['platform'] as int],
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      snapshot: json['snapshot'] as String,
      summary: json['summary'] as String,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}
