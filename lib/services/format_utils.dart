import 'package:flutter/services.dart';

/// FormatUtils — display-only number formatting helpers.
///
/// Rules:
/// - Formatting is COSMETIC only. The database always stores raw (stripped) values.
/// - Format on the way OUT  (populate TextEditingControllers in initState).
/// - Strip  on the way IN   (before saving to DB or comparing values).
///
/// Phone format (PH mobile):  XXXX XXX XXXX   e.g. 0921 528 8612
/// Group-of-4 format:          XXXX XXXX …     e.g. 6161 0096 8957
class FormatUtils {
  FormatUtils._(); // pure static utility — no instantiation

  // ── Phone Number ────────────────────────────────────────────────────────

  /// Formats a Philippine mobile number as [XXXX XXX XXXX].
  ///
  /// Handles both local format (09XX …) and international (+639XX …).
  /// Returns the original string unchanged if:
  ///  - [raw] is null or empty
  ///  - the string contains masking characters (*, •, ●) — keep as-is
  ///  - the cleaned digit string is not exactly 11 digits
  static String formatPhone(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    // Masked numbers pass through unchanged
    if (raw.contains('*') || raw.contains('•') || raw.contains('●')) {
      return raw;
    }

    // Strip to digits only
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');

    // Normalize +63 prefix → local 0-prefix (11 digits)
    String local = digits;
    if (local.startsWith('63') && local.length == 12) {
      local = '0${local.substring(2)}';
    }

    // Only format if exactly 11 digits starting with 09
    if (local.length == 11 && local.startsWith('09')) {
      return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
    }

    // Any other length/format — return original
    return raw;
  }

  /// Strips all whitespace from a phone number before storing or comparing.
  static String stripPhone(String raw) => raw.replaceAll(RegExp(r'\s+'), '');

  // ── Group-of-4 (Account Numbers & Maya Reference Numbers) ───────────────

  /// Formats any string into groups of 4 characters separated by spaces.
  ///
  /// Examples:
  ///   '616100968957'   → '6161 0096 8957'
  ///   '6be2f944253f'   → '6be2 f944 253f'
  ///   '7041804781046'  → '7041 8047 8104 6'
  ///   '***V2DY'        → '***V 2DY'
  ///   '********6416'   → '**** **** 6416'
  ///
  /// Returns empty string if [raw] is null or empty.
  /// Returns the original if it is already 4 chars or fewer.
  static String formatGroups4(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final s = raw.trim();
    if (s.length <= 4) return s;

    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Strips all whitespace — use before saving account/reference numbers.
  static String stripSpaces(String raw) => raw.replaceAll(RegExp(r'\s+'), '');
}

// ── Live-Typing Formatters ────────────────────────────────────────────────────

/// Applies XXXX XXX XXXX formatting as the user types a Philippine phone number.
///
/// Behaviour:
/// - Strips all non-digit characters first, then inserts spaces at positions 4 and 7.
/// - Only inserts spaces once enough digits are present (>4 for first space, >7 for second).
/// - Does NOT block input — any digit count is accepted; spaces are just added/removed live.
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip everything except digits
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Build formatted string, inserting spaces after position 4 and 7
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 4 || i == 7) buf.write(' ');
      buf.write(digits[i]);
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Applies groups-of-4 formatting as the user types an account number or
/// Maya reference number (e.g. 616100968957 → 6161 0096 8957).
///
/// Behaviour:
/// - Strips all spaces first, then re-inserts a space every 4 characters.
/// - Works for any alphanumeric string (digits, letters, asterisks).
class GroupOf4Formatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip existing spaces
    final raw = newValue.text.replaceAll(' ', '');

    // Re-insert a space every 4 characters
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(raw[i]);
    }

    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
