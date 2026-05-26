import 'package:intl/intl.dart';
import '../database/transaction_model.dart';

/// The structured result of parsing a GCash (or Maya) receipt text block.
///
/// All fields except [rawText] are nullable — the parser fills what it can find.
class ParsedReceipt {
  /// The full raw text that was scanned / pasted (kept for debugging)
  final String rawText;

  /// Detected platform (defaults to GCash when "gcash" appears in the text)
  final Platform platform;

  /// Detected transaction type (sent / received / payment / cashIn / cashOut)
  final TransactionType transactionType;

  /// Transaction amount in PHP (null if not found)
  final double? amount;

  /// Reference number / trace number (null if not found)
  final String? referenceNumber;

  /// Sender or recipient name as it appears on the receipt (may be masked)
  final String? personName;

  /// Phone number found in the receipt (null if not found)
  final String? phoneNumber;

  /// Date/time of the transaction (null if not found)
  final DateTime? transactionDate;

  /// Wallet remaining balance if visible (null if not found)
  final double? remainingBalance;

  /// Service fee if applicable (null if not found)
  final double? fee;

  const ParsedReceipt({
    required this.rawText,
    required this.platform,
    required this.transactionType,
    this.amount,
    this.referenceNumber,
    this.personName,
    this.phoneNumber,
    this.transactionDate,
    this.remainingBalance,
    this.fee,
  });

  /// True if the minimum required fields (amount + reference) were found.
  bool get isUsable => amount != null && referenceNumber != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// ReceiptParser — the core regex engine
// ─────────────────────────────────────────────────────────────────────────────

/// Parses raw receipt text (from OCR or clipboard) into a [ParsedReceipt].
class ReceiptParser {
  // ── Platform detection ──────────────────────────────────────────────────
  static Platform _detectPlatform(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('gcash'))     return Platform.gcash;
    if (lower.contains('maya') || lower.contains('paymaya')) return Platform.maya;
    if (lower.contains('grabpay'))   return Platform.grabpay;
    if (lower.contains('shopeepay') || lower.contains('spay')) return Platform.shopeepay;
    return Platform.gcash; // default: most common usage
  }

  // ── Transaction type detection ──────────────────────────────────────────
  static TransactionType _detectType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('you received') ||
        lower.contains('money received') ||
        lower.contains('received from')) {
      return TransactionType.received;
    }
    if (lower.contains('cash in') ||
        lower.contains('cashin')) {
      return TransactionType.cashIn;
    }
    if (lower.contains('cash out') ||
        lower.contains('cashout')) {
      return TransactionType.cashOut;
    }
    if (lower.contains('payment') ||
        lower.contains('paid to') ||
        lower.contains('bills payment')) {
      return TransactionType.payment;
    }
    return TransactionType.sent;
  }

  // ── Amount extraction ────────────────────────────────────────────────────
  static double? _extractAmount(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      
      // If line contains amount/sent/received
      if (lower.contains('amount') || lower.contains('sent') || lower.contains('received')) {
        // 1. Try to find a number in the SAME line first (with peso / P / php / none)
        final sameLineMatch = RegExp(r'(?:₱|PHP|Php|P)?\s*([0-9,]+\.[0-9]{2})', caseSensitive: false).firstMatch(line);
        if (sameLineMatch != null) {
          final val = _parseAmount(sameLineMatch.group(1)!);
          if (val != null && val > 0) return val;
        }
        
        // 2. Lookahead: Check the NEXT line for a standalone number (handling split-line OCR)
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          final nextLineMatch = RegExp(r'^(?:₱|PHP|Php|P)?\s*([0-9,]+\.[0-9]{2})$', caseSensitive: false).firstMatch(nextLine);
          if (nextLineMatch != null) {
            final val = _parseAmount(nextLineMatch.group(1)!);
            if (val != null && val > 0) return val;
          }
        }
      }
    }

    // Fallback 1: Any number with a peso/P/php prefix anywhere in the text
    final pesoMatch = RegExp(r'(?:₱|PHP|Php|P)\s*([0-9,]+\.[0-9]{2})', caseSensitive: false).firstMatch(text);
    if (pesoMatch != null) {
      return _parseAmount(pesoMatch.group(1)!);
    }

    // Fallback 2: Any standalone 2-decimal number in the text (often the raw amount)
    final numbers = RegExp(r'\b([0-9,]+\.[0-9]{2})\b').allMatches(text);
    for (final m in numbers) {
      final val = _parseAmount(m.group(1)!);
      if (val != null && val > 0 && val < 1000000) {
        return val;
      }
    }

    return null;
  }

  static double? _parseAmount(String s) {
    final cleaned = s.replaceAll(',', '');
    return double.tryParse(cleaned);
  }

  // ── Reference number extraction ─────────────────────────────────────────
  static final _refRe = RegExp(
    r'(?:ref(?:erence)?\.?\s*(?:no\.?|num(?:ber)?\.?|#)?[\s:]*)'
    r'([0-9][0-9 ]{8,20}[0-9])',
    caseSensitive: false,
  );

  static final _refFallbackRe = RegExp(r'\b([0-9]{4}\s[0-9]{3}\s[0-9]{6})\b');

  static String? _extractReference(String text) {
    final match = _refRe.firstMatch(text);
    if (match != null) {
      return match.group(1)!.replaceAll(' ', '');
    }
    final fallback = _refFallbackRe.firstMatch(text);
    if (fallback != null) {
      return fallback.group(1)!.replaceAll(' ', '');
    }
    return null;
  }

  // ── Phone number extraction ──────────────────────────────────────────────
  // Matches +63 9XX XXX XXXX or 09XX XXX XXXX (also allowing asterisks/dots like 09** *** ****)
  static final _phoneRe = RegExp(
    r'(?:\+?63|0)\s*9[0-9*•●]{2}[\s\-]?[0-9*•●]{3}[\s\-]?[0-9*•●]{4}',
  );

  static String? _extractPhone(String text) {
    final match = _phoneRe.firstMatch(text);
    return _formatPhone(match?.group(0));
  }

  static String? _formatPhone(String? raw) {
    if (raw == null) return null;
    var cleaned = raw.replaceAll(RegExp(r'[^\d*•●]'), '');
    if (cleaned.startsWith('63')) {
      cleaned = '0${cleaned.substring(2)}';
    } else if (!cleaned.startsWith('0')) {
      cleaned = '0$cleaned';
    }
    if (cleaned.length >= 11) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    }
    return raw;
  }

  // ── Person name extraction ───────────────────────────────────────────────
  // Supports masked names like JO***A T. or JO•••A T.
  static final _nameRe = RegExp(
    r'\b([A-Z][A-Z*•●·\.\-]{2,}\s+(?:[A-Z][A-Z*•●·\.\-]*\.?\s*)+)',
  );

  static final _toFromRe = RegExp(
    r'(?:to|from|send to|sent to|recipient)[:\s]+([A-Za-z][A-Za-z *\.•●·\-]{3,40})',
    caseSensitive: false,
  );

  static String? _extractName(String text, String? foundPhone) {
    String? rawName;
    final lines = text.split('\n').map((l) => l.trim()).toList();
    
    // 1. Line directly above phone number (extremely reliable for Express Send screen)
    if (foundPhone != null) {
      final cleanFound = foundPhone.replaceAll(RegExp(r'[^\d*•●]'), '');
      final foundSuffix = cleanFound.length >= 9 ? cleanFound.substring(cleanFound.length - 9) : cleanFound;

      for (int i = 0; i < lines.length; i++) {
        final cleanLine = lines[i].replaceAll(RegExp(r'[^\d*•●]'), '');
        final lineSuffix = cleanLine.length >= 9 ? cleanLine.substring(cleanLine.length - 9) : '';

        if (foundSuffix.isNotEmpty && lineSuffix == foundSuffix) {
          // Look up for the first non-empty line that isn't layout text
          for (int j = i - 1; j >= 0; j--) {
            final above = lines[j];
            if (above.isNotEmpty && 
                !above.toLowerCase().contains('express send') && 
                !above.toLowerCase().contains('sent via') &&
                !above.toLowerCase().contains('gcash') &&
                !above.toLowerCase().contains('successful') &&
                !above.toLowerCase().contains('download') &&
                !above.toLowerCase().contains('share')) {
              rawName = above;
              break;
            }
          }
        }
        if (rawName != null) break;
      }
    }

    // 2. To/From labeling pattern
    if (rawName == null) {
      final toFrom = _toFromRe.firstMatch(text);
      if (toFrom != null) rawName = toFrom.group(1)!.trim();
    }

    // 3. Masked uppercase names pattern
    if (rawName == null) {
      final masked = _nameRe.firstMatch(text);
      if (masked != null) rawName = masked.group(1)!.trim();
    }

    return rawName != null ? _cleanMaskedName(rawName) : null;
  }

  /// Fixes common OCR errors in masked names (e.g. converting "JO•oA" to "JO••A")
  static String _cleanMaskedName(String name) {
    var cleaned = name;
    
    // Replace all masking characters (including common OCR misrecognitions like commas, quotes, degrees, o, 0)
    // situated strictly between uppercase letters with the equivalent number of standard bullets.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([A-Z])([*•●·\.\-\,\x27`°o0]+)([A-Z])'), 
      (m) => '${m.group(1)}${'•' * m.group(2)!.length}${m.group(3)}'
    );
    
    // Unify any other stray stand-alone masking characters (except trailing period in initials like "T.")
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\b([A-Z])([*●·\-]+)\b'),
      (m) => '${m.group(1)}${'•' * m.group(2)!.length}'
    );
    
    return cleaned;
  }

  // ── Remaining balance extraction ──────────────────────────────────────────
  static final _balanceRe = RegExp(
    r'(?:balance|bal\.?|remaining\s+balance)(?:\s+is)?[:\s]*(?:₱|PHP|Php|P)?\s*([0-9,]+\.[0-9]{2})',
    caseSensitive: false,
  );

  static double? _extractBalance(String text) {
    final match = _balanceRe.firstMatch(text);
    if (match != null) {
      return _parseAmount(match.group(1)!);
    }
    return null;
  }

  // ── Date/time extraction ─────────────────────────────────────────────────
  static final _gcashDateRe = RegExp(
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)'
    r'[\s.]+(\d{1,2})[,\s]+(\d{4})'
    r'(?:[,\s]+(\d{1,2}):(\d{2})\s*(AM|PM))?',
    caseSensitive: false,
  );

  static final _smsDateRe = RegExp(
    r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[,\s]+(\d{4})'
    r'(?:[,\s]+(\d{1,2}):(\d{2})\s*(AM|PM))?',
    caseSensitive: false,
  );

  static final _mmddyyyyDateRe = RegExp(
    r'(\d{2})-(\d{2})-(\d{4})(?:\s+(\d{1,2}):(\d{2})\s*(AM|PM))?',
    caseSensitive: false,
  );

  static final _isoDateRe = RegExp(
    r'(\d{4})-(\d{2})-(\d{2})(?:\s+(\d{2}):(\d{2}))?',
  );

  static DateTime? _extractDate(String text) {
    final gcash = _gcashDateRe.firstMatch(text);
    if (gcash != null) {
      try {
        final raw = gcash.group(0)!;
        final normalised = raw
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(',', '');
        final formats = [
          DateFormat('MMM d yyyy h:mm a', 'en_US'),
          DateFormat('MMM d yyyy', 'en_US'),
        ];
        for (final fmt in formats) {
          try { return fmt.parse(normalised); } catch (_) {}
        }
      } catch (_) {}
    }

    final sms = _smsDateRe.firstMatch(text);
    if (sms != null) {
      try {
        final d = sms.group(1)!;
        final m = sms.group(2)!;
        final y = sms.group(3)!;
        final timeStr = sms.group(4) != null ? '${sms.group(4)}:${sms.group(5)} ${sms.group(6)}' : '';
        final raw = '$m $d $y $timeStr'.trim();
        final formats = [
          DateFormat('MMM d yyyy h:mm a', 'en_US'),
          DateFormat('MMM d yyyy', 'en_US'),
        ];
        for (final fmt in formats) {
          try { return fmt.parse(raw); } catch (_) {}
        }
      } catch (_) {}
    }

    final mmdd = _mmddyyyyDateRe.firstMatch(text);
    if (mmdd != null) {
      try {
        final mo = int.parse(mmdd.group(1)!);
        final d = int.parse(mmdd.group(2)!);
        final y = int.parse(mmdd.group(3)!);
        int h = mmdd.group(4) != null ? int.parse(mmdd.group(4)!) : 0;
        final mi = mmdd.group(5) != null ? int.parse(mmdd.group(5)!) : 0;
        final ampm = mmdd.group(6)?.toUpperCase();
        if (ampm == 'PM' && h < 12) h += 12;
        if (ampm == 'AM' && h == 12) h = 0;
        return DateTime(y, mo, d, h, mi);
      } catch (_) {}
    }

    final iso = _isoDateRe.firstMatch(text);
    if (iso != null) {
      try {
        final y  = int.parse(iso.group(1)!);
        final mo = int.parse(iso.group(2)!);
        final d  = int.parse(iso.group(3)!);
        final h  = iso.group(4) != null ? int.parse(iso.group(4)!) : 0;
        final mi = iso.group(5) != null ? int.parse(iso.group(5)!) : 0;
        return DateTime(y, mo, d, h, mi);
      } catch (_) {}
    }
    return null;
  }

  // ── Public API ───────────────────────────────────────────────────────────
  static ParsedReceipt parse(String rawText) {
    final platform        = _detectPlatform(rawText);
    final transactionType = _detectType(rawText);
    final amount          = _extractAmount(rawText);
    final referenceNumber = _extractReference(rawText);
    final phoneNumber     = _extractPhone(rawText);
    final personName      = _extractName(rawText, phoneNumber);
    final transactionDate = _extractDate(rawText);
    final remainingBalance = _extractBalance(rawText);

    return ParsedReceipt(
      rawText:          rawText,
      platform:         platform,
      transactionType:  transactionType,
      amount:           amount,
      referenceNumber:  referenceNumber,
      personName:       personName,
      phoneNumber:      phoneNumber,
      transactionDate:  transactionDate,
      remainingBalance: remainingBalance,
    );
  }
}
