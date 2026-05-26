import 'package:isar/isar.dart';

// This tells the code generator to create transaction_model.g.dart
part 'transaction_model.g.dart';

/// Enum for supported e-wallet platforms
enum Platform {
  gcash,
  maya,
  grabpay,
  shopeepay,
  other,
}

/// Enum for transaction types
enum TransactionType {
  sent,
  received,
  cashIn,
  cashOut,
  payment,
}

/// The @Collection annotation marks this class as an Isar database table.
/// Isar will automatically create an `id` field (auto-increment) for us.
@Collection()
class TransactionRecord {
  /// Auto-generated unique ID by Isar (required)
  Id id = Isar.autoIncrement;

  /// The e-wallet platform (GCash, Maya, etc.)
  @Enumerated(EnumType.name)
  late Platform platform;

  /// The type of transaction (sent, received, etc.)
  @Enumerated(EnumType.name)
  late TransactionType transactionType;

  /// Transaction amount in Philippine Peso
  late double amount;

  /// Unique reference number from the receipt
  late String referenceNumber;

  /// When the transaction happened
  late DateTime timestamp;

  /// Optional: name of sender (for received transactions)
  String? senderName;

  /// Optional: phone number of sender
  @Index()
  String? senderNumber;

  /// Optional: remaining balance of e-wallet
  double? remainingBalance;

  /// Optional: the exact date and time the transaction was recorded in the database
  DateTime? recordedAt;

  /// Optional: any extra notes you want to add
  String? notes;

  /// Optional: the computed service fee for this transaction
  double? fee;
}
