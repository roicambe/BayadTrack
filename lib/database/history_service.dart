import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_model.dart';
import 'transaction_model.dart';
import '../services/receipt_parser.dart';
import '../services/format_utils.dart';

/// HistoryService handles all read/write operations for [TransactionHistoryEntry]
/// records, persisted as a JSON list in SharedPreferences.
///
/// This is a debug/audit-only feature. It does not interact with the Isar
/// database and does not require code generation.
class HistoryService {
  static const _key = 'transaction_history_entries';

  // ── Currency formatter used in snapshots ───────────────────────────────────
  static final _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────────────────────────────────

  /// Appends a new [TransactionHistoryEntry] to the stored list.
  Future<void> saveEntry(TransactionHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.insert(0, entry.toJsonString()); // newest first
    await prefs.setStringList(_key, raw);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns all history entries, newest first.
  Future<List<TransactionHistoryEntry>> getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = <TransactionHistoryEntry>[];
    for (final s in raw) {
      try {
        entries.add(TransactionHistoryEntry.fromJson(jsonDecode(s)));
      } catch (_) {
        // Skip corrupted entries silently
      }
    }
    return entries;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CLEAR
  // ─────────────────────────────────────────────────────────────────────────

  /// Removes all stored history entries.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SNAPSHOT BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  static Map<String, String> _getReceiptFieldMap(ParsedReceipt receipt) {
    final fields = <String, String>{};
    if ((receipt.personName ?? '').isNotEmpty) {
      fields['Name'] = receipt.personName!;
    }
    if ((receipt.accountNumber ?? '').isNotEmpty) {
      fields['Account Number'] = receipt.accountNumber!;
    }
    if ((receipt.phoneNumber ?? '').isNotEmpty) {
      fields['Cellphone Number'] = receipt.phoneNumber!;
    }
    if (receipt.amount != null) {
      fields['Amount'] = _currency.format(receipt.amount);
    }
    if (receipt.fee != null) {
      fields['Service Fee'] = _currency.format(receipt.fee);
    }
    if ((receipt.referenceNumber ?? '').isNotEmpty) {
      fields['Reference Number'] = receipt.referenceNumber!;
    }
    if (receipt.transactionDate != null) {
      fields['Date'] = DateFormat('MMMM d, yyyy').format(receipt.transactionDate!);
      fields['Time'] = DateFormat('hh:mm a').format(receipt.transactionDate!);
    }
    if ((receipt.serviceProvider ?? '').isNotEmpty) {
      fields['Service Provider'] = receipt.serviceProvider!;
    }
    if (receipt.remainingBalance != null) {
      fields['Remaining Balance'] = _currency.format(receipt.remainingBalance);
    }
    fields['Transaction Type'] = _typeLabel(receipt.transactionType);
    fields['Platform'] = _platformLabel(receipt.platform);
    return fields;
  }

  static Map<String, String> _getRecordFieldMap(TransactionRecord r) {
    final fields = <String, String>{};
    if ((r.senderName ?? '').isNotEmpty) {
      fields['Name'] = r.senderName!;
    }
    if ((r.accountNumber ?? '').isNotEmpty) {
      fields['Account Number'] = r.accountNumber!;
    }
    if ((r.senderNumber ?? '').isNotEmpty) {
      fields['Cellphone Number'] = r.senderNumber!;
    }
    fields['Amount'] = _currency.format(r.amount);
    if (r.fee != null) {
      fields['Service Fee'] = _currency.format(r.fee);
    }
    fields['Reference Number'] = r.referenceNumber;
    fields['Date'] = DateFormat('MMMM d, yyyy').format(r.timestamp);
    fields['Time'] = DateFormat('hh:mm a').format(r.timestamp);
    if ((r.serviceProvider ?? '').isNotEmpty) {
      fields['Service Provider'] = r.serviceProvider!;
    }
    if (r.remainingBalance != null) {
      fields['Remaining Balance'] = _currency.format(r.remainingBalance);
    }
    fields['Transaction Type'] = _typeLabel(r.transactionType);
    fields['Platform'] = _platformLabel(r.platform);
    fields['Is Settled'] = r.isSettled ? 'Yes' : 'No';
    return fields;
  }

  static String buildStructuredSnapshot({
    required Map<String, String> fields,
    String? rawText,
  }) {
    final list = fields.entries.map((e) => {
      'label': e.key,
      'value': e.value,
    }).toList();

    final data = <String, dynamic>{
      'type': 'fields',
      'fields': list,
    };
    if (rawText != null) {
      data['rawText'] = rawText;
    }

    return jsonEncode(data);
  }

  static String buildReceiptSnapshot(ParsedReceipt receipt, {bool includeRawText = false}) {
    final fields = _getReceiptFieldMap(receipt);
    return buildStructuredSnapshot(
      fields: fields,
      rawText: includeRawText ? receipt.rawText : null,
    );
  }

  static String buildRecordSnapshot(TransactionRecord record) {
    final fields = _getRecordFieldMap(record);
    return buildStructuredSnapshot(fields: fields);
  }

  /// For shared text / paste — store the original raw text exactly as received.
  static String buildRawTextSnapshot(ParsedReceipt receipt) =>
      buildReceiptSnapshot(receipt, includeRawText: true);

  /// For manual input — build a structured snapshot from parsed receipt.
  static String buildManualSnapshot(ParsedReceipt receipt) =>
      buildReceiptSnapshot(receipt, includeRawText: false);

  /// For image upload — snapshot of the parsed fields shown in the confirm modal.
  static String buildImageUploadSnapshot(ParsedReceipt receipt) =>
      buildReceiptSnapshot(receipt, includeRawText: false);

  /// For delete — snapshot of the transaction record that was deleted.
  static String buildDeleteSnapshot(TransactionRecord record) =>
      buildRecordSnapshot(record);

  /// For edit — snapshot showing old and new values side-by-side.
  static String buildEditDiffSnapshot({
    required TransactionRecord before,
    required TransactionRecord after,
  }) {
    final beforeMap = _getRecordFieldMap(before);
    final afterMap = _getRecordFieldMap(after);

    final diffFields = <Map<String, String>>[];

    // Logical order of fields
    final allKeys = [
      'Name',
      'Account Number',
      'Cellphone Number',
      'Amount',
      'Service Fee',
      'Reference Number',
      'Date',
      'Time',
      'Service Provider',
      'Remaining Balance',
      'Transaction Type',
      'Platform',
      'Is Settled'
    ];

    for (final key in allKeys) {
      final beforeVal = beforeMap[key] ?? '';
      final afterVal = afterMap[key] ?? '';

      bool isChanged = beforeVal != afterVal;
      if (key == 'Cellphone Number' || key == 'Account Number' || key == 'Reference Number') {
        isChanged = FormatUtils.stripSpaces(beforeVal) != FormatUtils.stripSpaces(afterVal);
      }

      if (isChanged) {
        diffFields.add({
          'label': key,
          'before': beforeVal.isEmpty ? '(empty)' : beforeVal,
          'after': afterVal.isEmpty ? '(empty)' : afterVal,
        });
      }
    }

    // Capture the complete after record details as fields
    final fieldsList = afterMap.entries.map((e) => {
      'label': e.key,
      'value': e.value,
    }).toList();

    return jsonEncode({
      'type': 'edit_diff',
      'fields': fieldsList,
      'diff': diffFields,
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUMMARY BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds a short one-line summary for a ParsedReceipt (Add actions).
  static String buildReceiptSummary(ParsedReceipt receipt) {
    final parts = <String>[];
    if (receipt.amount != null) parts.add(_currency.format(receipt.amount));
    final name = receipt.personName;
    if (name != null && name.isNotEmpty) parts.add(name);
    return parts.isEmpty ? '(No details)' : parts.join(' • ');
  }

  /// Builds a short one-line summary for a TransactionRecord (Edit/Delete).
  static String buildRecordSummary(TransactionRecord record) {
    final parts = <String>[_currency.format(record.amount)];
    final name = record.senderName;
    if (name != null && name.isNotEmpty) parts.add(name);
    return parts.join(' • ');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ID GENERATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates a unique ID for a history entry using the current timestamp.
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  // ─────────────────────────────────────────────────────────────────────────
  // LABEL HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  static String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.sent:     return 'Sent';
      case TransactionType.received: return 'Received';
      case TransactionType.cashIn:   return 'Cash In';
      case TransactionType.cashOut:  return 'Cash Out';
      case TransactionType.payment:  return 'Payment';
    }
  }

  static String _platformLabel(Platform platform) {
    switch (platform) {
      case Platform.gcash:     return 'GCash';
      case Platform.maya:      return 'Maya Business';
      case Platform.grabpay:   return 'GrabPay';
      case Platform.shopeepay: return 'ShopeePay';
      case Platform.other:     return 'Other';
    }
  }
}
