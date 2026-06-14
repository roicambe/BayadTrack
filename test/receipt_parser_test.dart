// test/receipt_parser_test.dart
//
// Regression tests for ReceiptParser.
//
// Rules:
// • NEVER delete or weaken an existing test — only add or extend.
// • When a new format is supported, add a new test group here.
// • Run with: flutter test test/receipt_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:bayadtrack/services/receipt_parser.dart';
import 'package:bayadtrack/services/format_utils.dart';
import 'package:bayadtrack/database/transaction_model.dart';


void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Maya Business — Pay Bills
  // ─────────────────────────────────────────────────────────────────────────
  group('Maya Business — Pay Bills (account number digits only)', () {
    const text =
        '10Jun 08:25: Paid ₱1,000.00 and biller convenience fee of ₱12.00 '
        'to Easytrip RFID with Account Number ********6416. '
        'Ref. No. 6161 0096 8957';

    late ParsedReceipt result;
    setUpAll(() => result = ReceiptParser.parse(text));

    test('platform is Maya', () => expect(result.platform, Platform.maya));
    test('transaction type is payment', () => expect(result.transactionType, TransactionType.payment));
    test('amount is 1000.00', () => expect(result.amount, 1000.00));
    test('service provider is Easytrip RFID', () => expect(result.serviceProvider, 'Easytrip RFID'));
    test('reference number extracted', () => expect(result.referenceNumber, isNotNull));
    // BUG FIX: account number with digits-only masked ending must be preserved
    test('account number is ********6416', () => expect(result.accountNumber, '********6416'));
    // Date: 10Jun — compact Maya format, infers current year
    test('transaction date day is 10', () => expect(result.transactionDate?.day, 10));
    test('transaction date month is 6 (June)', () => expect(result.transactionDate?.month, 6));
    test('transaction time hour is 8', () => expect(result.transactionDate?.hour, 8));
    test('transaction time minute is 25', () => expect(result.transactionDate?.minute, 25));
  });

  group('Maya Business — Pay Bills (account number alphanumeric masked)', () {
    const text =
        '10Jun 07:06: Paid ₱15,421.00 and biller convenience fee of ₱5.00 '
        'to TALA with Account Number ***********V2DY. '
        'Ref. No. 6161 1114 6041';

    late ParsedReceipt result;
    setUpAll(() => result = ReceiptParser.parse(text));

    test('platform is Maya', () => expect(result.platform, Platform.maya));
    test('transaction type is payment', () => expect(result.transactionType, TransactionType.payment));
    test('amount is 15421.00', () => expect(result.amount, 15421.00));
    test('service provider is Tala', () => expect(result.serviceProvider, 'Tala'));
    test('reference number extracted', () => expect(result.referenceNumber, isNotNull));
    // BUG FIX: account number with alphanumeric masked ending must be preserved exactly
    test('account number is ***********V2DY', () => expect(result.accountNumber, '***********V2DY'));
    test('transaction date day is 10', () => expect(result.transactionDate?.day, 10));
    test('transaction date month is 6 (June)', () => expect(result.transactionDate?.month, 6));
    test('transaction time hour is 7', () => expect(result.transactionDate?.hour, 7));
    test('transaction time minute is 6', () => expect(result.transactionDate?.minute, 6));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GCash — Express Send (full month name date) — REGRESSION BUG FIX
  // ─────────────────────────────────────────────────────────────────────────
  group('GCash Express Send — full month name date (regression fix)', () {
    const text =
        '13 June 2026, 07:43 AM Express Send Notification '
        'You have received PHP 3540.00 from CH******N J** B. '
        '+639309719532 w/ MSG: . '
        'Your new balance is PHP 35217.91. Ref. No. 7041804781046.';

    late ParsedReceipt result;
    setUpAll(() => result = ReceiptParser.parse(text));

    test('platform is GCash', () => expect(result.platform, Platform.gcash));
    test('transaction type is received', () => expect(result.transactionType, TransactionType.received));
    test('amount is 3540.00', () => expect(result.amount, 3540.00));
    test('reference number is 7041804781046', () => expect(result.referenceNumber, '7041804781046'));
    test('remaining balance is 35217.91', () => expect(result.remainingBalance, 35217.91));

    // BUG FIX: date must come from the message, NOT from import/current time
    test('transaction date year is 2026', () => expect(result.transactionDate?.year, 2026));
    test('transaction date month is 6 (June)', () => expect(result.transactionDate?.month, 6));
    test('transaction date day is 13', () => expect(result.transactionDate?.day, 13));
    test('transaction time hour is 7 (07:43 AM)', () => expect(result.transactionDate?.hour, 7));
    test('transaction time minute is 43', () => expect(result.transactionDate?.minute, 43));
    // Ensure date is NOT today's date (regression guard)
    test('date is not current time', () {
      final now = DateTime.now();
      final txDate = result.transactionDate;
      expect(txDate, isNotNull);
      // If the parsed date equals "now" to within 1 minute, it's using import time — fail.
      final diff = now.difference(txDate!).abs();
      expect(diff.inMinutes, greaterThan(1),
          reason: 'Transaction date should come from the message text, not from the current timestamp');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // GCash — Express Send (abbreviated month — existing format guard)
  // ─────────────────────────────────────────────────────────────────────────
  group('GCash Express Send — abbreviated month date (regression guard)', () {
    const text =
        'Jun 5, 2026, 10:30 AM GCash Express Send '
        'You have received PHP 500.00 from JU*** D. '
        '+639171234567 w/ MSG: Thanks. '
        'Your new balance is PHP 1500.00. Ref. No. 1234567890123.';

    late ParsedReceipt result;
    setUpAll(() => result = ReceiptParser.parse(text));

    test('transaction type is received', () => expect(result.transactionType, TransactionType.received));
    test('amount is 500.00', () => expect(result.amount, 500.00));
    test('date year is 2026', () => expect(result.transactionDate?.year, 2026));
    test('date month is 6', () => expect(result.transactionDate?.month, 6));
    test('date day is 5', () => expect(result.transactionDate?.day, 5));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Maya — Sent (regression guard)
  // ─────────────────────────────────────────────────────────────────────────
  group('Maya Sent — regression guard', () {
    const text =
        '05Jun 08:32: Sent ₱500.00 to JUAN D. '
        'Reference No. 123456789012';

    late ParsedReceipt result;
    setUpAll(() => result = ReceiptParser.parse(text));

    test('platform is Maya', () => expect(result.platform, Platform.maya));
    test('transaction type is sent', () => expect(result.transactionType, TransactionType.sent));
    test('amount is 500.00', () => expect(result.amount, 500.00));
    test('date day is 5', () => expect(result.transactionDate?.day, 5));
    test('date month is 6', () => expect(result.transactionDate?.month, 6));
    test('date hour is 8', () => expect(result.transactionDate?.hour, 8));
    test('date minute is 32', () => expect(result.transactionDate?.minute, 32));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Maya — Load (regression guard)
  // ─────────────────────────────────────────────────────────────────────────
  group('Maya Load — regression guard', () {
    const text =
        '03Jun 14:10: Sold ALLNET 299 to +639171234567 '
        'Ref. No. 987654321098';

    late ParsedReceipt result;
    setUpAll(() => result = ReceiptParser.parse(text));

    test('platform is Maya', () => expect(result.platform, Platform.maya));
    test('transaction type is payment', () => expect(result.transactionType, TransactionType.payment));
    // Load promo amounts ending in 9 are rounded up
    test('amount is 300.00 (299 rounded up)', () => expect(result.amount, 300.00));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FormatUtils — display-only number formatting
  // ─────────────────────────────────────────────────────────────────────────
  group('FormatUtils.formatPhone', () {
    test('formats 11-digit PH mobile (09XX)', () =>
        expect(FormatUtils.formatPhone('09215288612'), '0921 528 8612'));

    test('formats 11-digit PH mobile (09XX) — another number', () =>
        expect(FormatUtils.formatPhone('09309719532'), '0930 971 9532'));

    test('formats 11-digit PH mobile (09XX) — third number', () =>
        expect(FormatUtils.formatPhone('09174430589'), '0917 443 0589'));

    test('normalizes +63 prefix before formatting', () =>
        expect(FormatUtils.formatPhone('+639215288612'), '0921 528 8612'));

    test('leaves 10-digit number unchanged', () =>
        expect(FormatUtils.formatPhone('0921528861'), '0921528861'));

    test('leaves masked number unchanged', () =>
        expect(FormatUtils.formatPhone('09** *** ****'), '09** *** ****'));

    test('returns empty string for null', () =>
        expect(FormatUtils.formatPhone(null), ''));

    test('returns empty string for empty', () =>
        expect(FormatUtils.formatPhone(''), ''));
  });

  group('FormatUtils.formatGroups4', () {
    test('groups 12-char string into 3 groups of 4', () =>
        expect(FormatUtils.formatGroups4('616100968957'), '6161 0096 8957'));

    test('groups hex account number', () =>
        expect(FormatUtils.formatGroups4('6be2f944253f'), '6be2 f944 253f'));

    test('handles 13-char reference number (leftover group)', () =>
        expect(FormatUtils.formatGroups4('7041804781046'), '7041 8047 8104 6'));

    test('groups masked account number with asterisks', () =>
        expect(FormatUtils.formatGroups4('********6416'), '**** **** 6416'));

    test('groups partial masked account with letters', () =>
        expect(FormatUtils.formatGroups4('***V2DY'), '***V 2DY'));

    test('leaves 4-char string unchanged', () =>
        expect(FormatUtils.formatGroups4('1234'), '1234'));

    test('leaves short string unchanged', () =>
        expect(FormatUtils.formatGroups4('AB'), 'AB'));

    test('returns empty string for null', () =>
        expect(FormatUtils.formatGroups4(null), ''));

    test('returns empty string for empty', () =>
        expect(FormatUtils.formatGroups4(''), ''));
  });

  group('FormatUtils.stripSpaces', () {
    test('strips spaces from formatted reference number', () =>
        expect(FormatUtils.stripSpaces('6161 0096 8957'), '616100968957'));

    test('strips spaces from formatted account number', () =>
        expect(FormatUtils.stripSpaces('**** **** 6416'), '********6416'));

    test('leaves string without spaces unchanged', () =>
        expect(FormatUtils.stripSpaces('616100968957'), '616100968957'));
  });

  group('FormatUtils.stripPhone', () {
    test('strips spaces from formatted phone', () =>
        expect(FormatUtils.stripPhone('0921 528 8612'), '09215288612'));

    test('leaves unformatted phone unchanged', () =>
        expect(FormatUtils.stripPhone('09215288612'), '09215288612'));
  });
}

