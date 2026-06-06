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

  /// The service provider for Maya load/bills transactions (null if not found)
  final String? serviceProvider;

  /// Account number for Maya Business or bank transfer
  final String? accountNumber;

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
    this.serviceProvider,
    this.accountNumber,
  });

  /// True if the minimum required fields (amount + reference) were found.
  bool get isUsable => amount != null && referenceNumber != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// ReceiptParser — the core regex engine
// ─────────────────────────────────────────────────────────────────────────────

/// Parses raw receipt text (from OCR or clipboard) into a [ParsedReceipt].
class ReceiptParser {
  // ── Service Provider Normalization ─────────────────────────────────────

  /// Known Maya service providers mapped to their proper display format.
  /// Keys are lowercase for case-insensitive matching.
  static const _providerDisplayNames = <String, String>{
    'meralco': 'Meralco',
    'manila water': 'Manila Water',
    'pldt home': 'PLDT Home',
    'home credit': 'Home Credit',
    'converge': 'Converge',
    'easytrip rfid': 'Easytrip RFID',
    'tala': 'Tala',
    'maynilad': 'Maynilad',
    'smart': 'Smart',
    'globe': 'Globe',
    'cignal': 'Cignal',
    'sky cable': 'Sky Cable',
    'sss': 'SSS',
    'pag-ibig': 'Pag-IBIG',
    'philhealth': 'PhilHealth',
  };

  /// Normalizes a service provider name to its proper display format.
  /// Falls back to smart title-casing for unknown providers.
  static String normalizeProvider(String raw) {
    final lower = raw.trim().toLowerCase();

    // 1. Exact match in known providers
    if (_providerDisplayNames.containsKey(lower)) {
      return _providerDisplayNames[lower]!;
    }

    // 2. Partial/contains match for known providers
    for (final entry in _providerDisplayNames.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    // 3. Smart title case for unknown providers
    return _smartTitleCase(raw.trim());
  }

  /// Common acronyms that should stay uppercase during title-casing.
  static const _acronyms = {'rfid', 'pldt', 'sss', 'nbi', 'lto', 'nso', 'psa'};

  static String _smartTitleCase(String input) {
    return input.split(RegExp(r'\s+')).map((word) {
      final lower = word.toLowerCase();
      if (_acronyms.contains(lower)) return word.toUpperCase();
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  // ── Platform detection ──────────────────────────────────────────────────
  static Platform _detectPlatform(String text, {Platform? hint}) {
    final lower = text.toLowerCase();
    if (lower.contains('gcash'))     return Platform.gcash;
    if (lower.contains('maya') || lower.contains('paymaya')) return Platform.maya;
    
    // Check for Maya-specific formatting patterns
    if (lower.contains('and biller convenience fee') || 
        lower.contains('biller convenience fee') ||
        lower.contains('sold allnet') ||
        lower.contains('with account number') ||
        RegExp(r'\d{2}(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{2}:\d{2}', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'\d{2}\s+[a-z]{3}\s+\d{4}\s+\d{2}:\d{2}\s+[am|pm]+:', caseSensitive: false).hasMatch(lower)) {
      return Platform.maya;
    }
    
    if (lower.contains('grabpay'))   return Platform.grabpay;
    if (lower.contains('shopeepay') || lower.contains('spay')) return Platform.shopeepay;
    return hint ?? Platform.gcash; // default to hint, fallback to gcash
  }

  // ── Transaction type detection ──────────────────────────────────────────
  static TransactionType _detectType(String text) {
    final lower = text.toLowerCase();
    
    // Explicitly check for received patterns (Maya + GCash)
    if (lower.contains('you have received') ||
        lower.contains('you received') ||
        lower.contains('money received') ||
        lower.contains('received php') ||
        lower.contains('received from') ||
        RegExp(r'received\s*₱', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'received\s+(?:₱|php|p)\s*[0-9]', caseSensitive: false).hasMatch(lower)) {
      return TransactionType.received;
    }
    
    // Explicitly check for sent patterns (Maya + GCash)
    if (lower.contains('you have sent') ||
        lower.contains('successfully sent') ||
        RegExp(r'sent\s*₱', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'sent\s+(?:₱|php|p)\s*[0-9]', caseSensitive: false).hasMatch(lower)) {
      return TransactionType.sent;
    }

    if (lower.contains('cash in') ||
        lower.contains('cashin')) {
      return TransactionType.cashIn;
    }
    if (lower.contains('cash out') ||
        lower.contains('cashout')) {
      return TransactionType.cashOut;
    }
    
    // Maya specific payment patterns — must come before generic 'pay' checks
    if (lower.contains('paid php') || 
        lower.contains('biller convenience fee') ||
        lower.contains('with account number') ||
        RegExp(r'paid\s*₱', caseSensitive: false).hasMatch(lower) ||
        lower.contains('sold ')) {
      return TransactionType.payment;
    }

    // Default heuristics
    if (lower.contains('pay') || lower.contains('bought')) {
      return TransactionType.payment;
    }
    if (lower.contains('payment') ||
        lower.contains('paid to') ||
        lower.contains('you paid') ||
        lower.contains('bills payment')) {
      return TransactionType.payment;
    }
    
    // Default fallback
    return TransactionType.sent;
  }

  // ── Amount extraction ────────────────────────────────────────────────────
  static double? _extractAmount(String text) {
    // Maya Pay Bills Format: Paid ₱6,420.00 and biller convenience fee...
    final paidPesoMatch = RegExp(
      r'Paid\s*(?:₱|PHP|Php|P)\s*([0-9,]+\.[0-9]{2})',
      caseSensitive: false,
    ).firstMatch(text);
    if (paidPesoMatch != null) {
      return _parseAmount(paidPesoMatch.group(1)!);
    }

    // Maya Sent Format: Sent ₱500.00 to...
    final sentPesoMatch = RegExp(
      r'Sent\s*(?:₱|PHP|Php|P)\s*([0-9,]+\.[0-9]{2})',
      caseSensitive: false,
    ).firstMatch(text);
    if (sentPesoMatch != null) {
      return _parseAmount(sentPesoMatch.group(1)!);
    }

    // Maya Received Format: Received ₱1,000.00 from...
    final receivedPesoMatch = RegExp(
      r'Received\s*(?:₱|PHP|Php|P)\s*([0-9,]+\.[0-9]{2})',
      caseSensitive: false,
    ).firstMatch(text);
    if (receivedPesoMatch != null) {
      return _parseAmount(receivedPesoMatch.group(1)!);
    }

    // Maya Load Format: Sold ALLNET w/ FREE Landline 599 to +63...
    // Extract the amount directly from the promo name and round up if it ends in 9
    final loadMatch = RegExp(r'Sold\s+[\s\S]+?\s+(\d+)\s+to\s+(?:(?:\+?63|0)9)', caseSensitive: false).firstMatch(text);
    if (loadMatch != null) {
      double rawAmount = double.parse(loadMatch.group(1)!);
      if (rawAmount % 10 == 9) {
        rawAmount += 1;
      }
      return rawAmount;
    }

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

  // ── Reference Number extraction ──────────────────────────────────────────
  static final _refRe = RegExp(
    r'(?:ref(?:\.|erence)?\s*(?:no\.?|number)?|ref\s*id|transaction\s*(?:no\.?|number)?)\s*[:\-\n]?\s*([0-9a-fA-F][0-9a-fA-F\soOlLiI]{8,25}[0-9a-fA-FoOlLiI])',
    caseSensitive: false,
  );
  static final _refFallbackRe = RegExp(r'(?:^|\W)([0-9a-fA-F]{12,16})(?:\W|$)');

  static String? _extractReference(String text) {
    final match = _refRe.firstMatch(text);
    if (match != null) {
      return match.group(1)!
          .replaceAll(RegExp(r'[\s]'), '')
          .replaceAll(RegExp(r'[oO]', caseSensitive: false), '0')
          .replaceAll(RegExp(r'[lL|iI]', caseSensitive: false), '1');
    }
    final fallback = _refFallbackRe.firstMatch(text);
    if (fallback != null) {
      return fallback.group(1)!;
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
    r'(?:to|from|send to|sent to|recipient)[:\s]+((?!your\s+)(?!my\s+)[A-Za-z][A-Za-z *\.•●·\-]{3,40})',
    caseSensitive: false,
  );

  static String? _extractName(String text, String? foundPhone, String? serviceProvider) {
    String? rawName;
    final lines = text.split('\n').map((l) => l.trim()).toList();
    
    // Check if a potential name is just a UI label
    bool isForbiddenName(String name) {
      final n = name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      return n.isEmpty ||
             n == 'amount' ||
             n == 'date' ||
             n == 'time' ||
             n.contains('transactiondetail') ||
             n.contains('transferfrom') ||
             n.contains('mayabusiness') ||
             n == 'gcash' ||
             n == 'referencenumber';
    }

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

    // 2. Maya-specific patterns (Sent to / Paid to / Sold to)
    //    For pay bills, stop before "with Account Number" to avoid polluting the name field
    if (rawName == null) {
      final paidTo = RegExp(r'paid(?:.*?)\s+to\s+([A-Za-z0-9\s]+?)(?:\s+with\s+Account|\.|Convenience|\n|$)', caseSensitive: false).firstMatch(text);
      if (paidTo != null) {
        final candidate = paidTo.group(1)?.trim();
        // Don't use as name if it's a known service provider (it'll go to serviceProvider field)
        if (candidate != null && !_isKnownProvider(candidate)) {
          rawName = candidate;
        }
      }
    }
    // Maya sent: "Sent ₱500.00 to JUAN D." — extract person name after "to"
    if (rawName == null) {
      final sentTo = RegExp(r'Sent\s*(?:₱|PHP|P)?[0-9,.]+\s+to\s+([A-Za-z][A-Za-z *\.•●·\-]{2,40})', caseSensitive: false).firstMatch(text);
      if (sentTo != null) {
        rawName = sentTo.group(1)?.trim();
      }
    }
    // Maya received: "Received ₱1,000.00 from MARIA C."
    if (rawName == null) {
      final receivedFrom = RegExp(r'Received\s*(?:₱|PHP|P)?[0-9,.]+\s+from\s+([A-Za-z][A-Za-z *\.•●·\-]{2,40})', caseSensitive: false).firstMatch(text);
      if (receivedFrom != null) {
        rawName = receivedFrom.group(1)?.trim();
      }
    }
    if (rawName == null) {
      final promoMatch = RegExp(r'Sold\s+(.+?)\s+to\s+(?:\+?63|0)', caseSensitive: false).firstMatch(text);
      if (promoMatch != null) {
        rawName = promoMatch.group(1)?.trim();
      }
    }

    // 3. To/From labeling pattern
    if (rawName == null) {
      final toFrom = _toFromRe.firstMatch(text);
      if (toFrom != null) rawName = toFrom.group(1)!.trim();
    }

    // 4. Masked uppercase names pattern
    if (rawName == null) {
      final masked = _nameRe.firstMatch(text);
      if (masked != null) rawName = masked.group(1)!.trim();
    }

    if (rawName != null) {
      if (isForbiddenName(rawName)) {
        rawName = null;
      } else if (serviceProvider != null && rawName.toLowerCase().startsWith(serviceProvider.toLowerCase())) {
        // Prevent service provider from being duplicated into the person name field
        rawName = null;
      }
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

  // ── Fee extraction ────────────────────────────────────────────────────────
  static final _feeRe = RegExp(
    r'(?:fee|convenience fee)[\s:]*(?:₱|PHP|Php|P)?\s*([0-9,]+\.[0-9]{2})',
    caseSensitive: false,
  );

  static double? _extractFee(String text) {
    final match = _feeRe.firstMatch(text);
    if (match != null) {
      return _parseAmount(match.group(1)!);
    }
    return null;
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

  // ── Service Provider extraction ───────────────────────────────────────────
  static String? _extractServiceProvider(String text) {
    // Maya bills format: Paid ... to PROVIDER with Account Number ...
    final paidWithAcct = RegExp(
      r'to\s+([A-Za-z0-9\s]+?)\s+with\s+Account\s+Number',
      caseSensitive: false,
    ).firstMatch(text);
    if (paidWithAcct != null) {
      final raw = paidWithAcct.group(1)!.trim();
      if (raw.isNotEmpty) return normalizeProvider(raw);
    }

    // Pay bills format: Paid ... to [Provider]. Your...
    // Use (?s) or \s+ to handle newlines between 'to' and the provider name
    final paidMatch = RegExp(r'Paid[\s\S]*? to (.+?)\.\s*Your', caseSensitive: false).firstMatch(text);
    if (paidMatch != null) {
      final match = paidMatch.group(1)?.replaceAll('\n', ' ').trim();
      if (match != null && !RegExp(r'^\+?\d+$').hasMatch(match.replaceAll(RegExp(r'[ \-]'), ''))) {
        return normalizeProvider(match);
      }
    }
    
    // Load format: Sold [Provider/Promo] to +63...
    final soldMatch = RegExp(r'Sold ([\s\S]+?) to \s*(?:(?:\+?63|0)9)', caseSensitive: false).firstMatch(text);
    if (soldMatch != null) {
      return soldMatch.group(1)?.replaceAll('\n', ' ').trim();
    }
    
    return null;
  }

  /// Returns true if the given text matches a known service provider.
  static bool _isKnownProvider(String text) {
    final lower = text.trim().toLowerCase();
    for (final key in _providerDisplayNames.keys) {
      if (lower == key || lower.contains(key) || key.contains(lower)) {
        return true;
      }
    }
    return false;
  }

  // ── Account Number extraction ─────────────────────────────────────────────
  static String? _extractAccountNumber(String text) {
    // Maya format: "with Account Number ******9151"
    final match = RegExp(
      r'(?:Account\s*(?:No\.?|Number|#))\s*[:\s]?\s*([*\d][*\d\s-]+[\d*])',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1)?.trim();
  }

  // ── Date/time extraction ─────────────────────────────────────────────────

  // Maya compact format: 05Jun 08:32: (DDMon HH:MM — no year, infer current year)
  static final _mayaCompactDateRe = RegExp(
    r'(\d{2})(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{2}):(\d{2}):?',
    caseSensitive: false,
  );

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
    // Maya compact format: 05Jun 08:32: — infer current year
    final mayaCompact = _mayaCompactDateRe.firstMatch(text);
    if (mayaCompact != null) {
      try {
        final day = int.parse(mayaCompact.group(1)!);
        final monthStr = mayaCompact.group(2)!;
        final hour = int.parse(mayaCompact.group(3)!);
        final minute = int.parse(mayaCompact.group(4)!);
        final monthIndex = _monthFromAbbr(monthStr);
        if (monthIndex != null) {
          final now = DateTime.now();
          return DateTime(now.year, monthIndex, day, hour, minute);
        }
      } catch (_) {}
    }

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

  /// Helper: converts 3-letter month abbreviation to month number (1-12).
  static int? _monthFromAbbr(String abbr) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
      'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[abbr.toLowerCase()];
  }

  // ── Public API ───────────────────────────────────────────────────────────
  static ParsedReceipt parse(String rawText, {Platform? platformHint}) {
    final platform        = _detectPlatform(rawText, hint: platformHint);
    final transactionType = _detectType(rawText);
    final amount          = _extractAmount(rawText);
    final referenceNumber = _extractReference(rawText);
    final phoneNumber     = _extractPhone(rawText);
    final serviceProvider = _extractServiceProvider(rawText);
    final accountNumber   = _extractAccountNumber(rawText);
    final personName      = _extractName(rawText, phoneNumber, serviceProvider);
    final transactionDate = _extractDate(rawText);
    final remainingBalance = _extractBalance(rawText);
    // For Maya platform, skip the biller convenience fee from text —
    // BayadTrack uses its own configurable fee system from Settings.
    final fee = platform == Platform.maya ? null : _extractFee(rawText);

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
      fee:              fee,
      serviceProvider:  serviceProvider,
      accountNumber:    accountNumber,
    );
  }

  /// Parses a batch of text.
  /// For Maya text, first tries parsing the full text as a single receipt.
  /// If that produces a usable result, returns it directly (prevents a valid
  /// multi-line receipt from being split into partial single-line fragments).
  /// Only falls back to line-by-line splitting for truly tabular/batch data
  /// where the full text is not itself a parseable receipt.
  static List<ParsedReceipt> parseBatch(String rawText, {Platform? platformHint}) {
    final platform = _detectPlatform(rawText, hint: platformHint);

    // Maya: try full-text parse first before splitting by lines.
    // A real share from the Maya app is one multi-line receipt — splitting
    // it produces many partial fragments that trigger the multi-transaction error.
    if (platform == Platform.maya) {
      final fullParse = parse(rawText, platformHint: platformHint);
      if (fullParse.isUsable) {
        return [fullParse];
      }

      // Full text wasn't a parseable receipt — fall back to line-by-line splitting
      // for tabular/batch formats (e.g. exported CSV-like lists).
      final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      final List<ParsedReceipt> results = [];
      for (final line in lines) {
        final parsed = parse(line, platformHint: platformHint);
        if (parsed.amount != null || parsed.referenceNumber != null || parsed.transactionDate != null) {
          results.add(parsed);
        }
      }
      if (results.isNotEmpty) return results;
    }

    // Fallback: single receipt mode
    return [parse(rawText, platformHint: platformHint)];
  }
}
