import 'package:isar/isar.dart';

part 'fee_model.g.dart';

/// Represents a configured service fee for a given transaction amount range.
@Collection()
class FeeRange {
  /// Auto-generated unique ID
  Id id = Isar.autoIncrement;

  /// The minimum amount for this fee to apply
  late double minAmount;

  /// The maximum amount for this fee to apply
  late double maxAmount;

  /// The service fee for this range
  late double fee;
}
