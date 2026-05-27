// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTransactionRecordCollection on Isar {
  IsarCollection<TransactionRecord> get transactionRecords => this.collection();
}

const TransactionRecordSchema = CollectionSchema(
  name: r'TransactionRecord',
  id: 5251947889243599499,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'fee': PropertySchema(
      id: 1,
      name: r'fee',
      type: IsarType.double,
    ),
    r'isSettled': PropertySchema(
      id: 2,
      name: r'isSettled',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 3,
      name: r'notes',
      type: IsarType.string,
    ),
    r'platform': PropertySchema(
      id: 4,
      name: r'platform',
      type: IsarType.string,
      enumMap: _TransactionRecordplatformEnumValueMap,
    ),
    r'recordedAt': PropertySchema(
      id: 5,
      name: r'recordedAt',
      type: IsarType.dateTime,
    ),
    r'referenceNumber': PropertySchema(
      id: 6,
      name: r'referenceNumber',
      type: IsarType.string,
    ),
    r'remainingBalance': PropertySchema(
      id: 7,
      name: r'remainingBalance',
      type: IsarType.double,
    ),
    r'senderName': PropertySchema(
      id: 8,
      name: r'senderName',
      type: IsarType.string,
    ),
    r'senderNumber': PropertySchema(
      id: 9,
      name: r'senderNumber',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 10,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'transactionType': PropertySchema(
      id: 11,
      name: r'transactionType',
      type: IsarType.string,
      enumMap: _TransactionRecordtransactionTypeEnumValueMap,
    )
  },
  estimateSize: _transactionRecordEstimateSize,
  serialize: _transactionRecordSerialize,
  deserialize: _transactionRecordDeserialize,
  deserializeProp: _transactionRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'senderNumber': IndexSchema(
      id: -6822599329568614336,
      name: r'senderNumber',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'senderNumber',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _transactionRecordGetId,
  getLinks: _transactionRecordGetLinks,
  attach: _transactionRecordAttach,
  version: '3.1.0+1',
);

int _transactionRecordEstimateSize(
  TransactionRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.platform.name.length * 3;
  bytesCount += 3 + object.referenceNumber.length * 3;
  {
    final value = object.senderName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.senderNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.transactionType.name.length * 3;
  return bytesCount;
}

void _transactionRecordSerialize(
  TransactionRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeDouble(offsets[1], object.fee);
  writer.writeBool(offsets[2], object.isSettled);
  writer.writeString(offsets[3], object.notes);
  writer.writeString(offsets[4], object.platform.name);
  writer.writeDateTime(offsets[5], object.recordedAt);
  writer.writeString(offsets[6], object.referenceNumber);
  writer.writeDouble(offsets[7], object.remainingBalance);
  writer.writeString(offsets[8], object.senderName);
  writer.writeString(offsets[9], object.senderNumber);
  writer.writeDateTime(offsets[10], object.timestamp);
  writer.writeString(offsets[11], object.transactionType.name);
}

TransactionRecord _transactionRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TransactionRecord();
  object.amount = reader.readDouble(offsets[0]);
  object.fee = reader.readDoubleOrNull(offsets[1]);
  object.id = id;
  object.isSettled = reader.readBool(offsets[2]);
  object.notes = reader.readStringOrNull(offsets[3]);
  object.platform = _TransactionRecordplatformValueEnumMap[
          reader.readStringOrNull(offsets[4])] ??
      Platform.gcash;
  object.recordedAt = reader.readDateTimeOrNull(offsets[5]);
  object.referenceNumber = reader.readString(offsets[6]);
  object.remainingBalance = reader.readDoubleOrNull(offsets[7]);
  object.senderName = reader.readStringOrNull(offsets[8]);
  object.senderNumber = reader.readStringOrNull(offsets[9]);
  object.timestamp = reader.readDateTime(offsets[10]);
  object.transactionType = _TransactionRecordtransactionTypeValueEnumMap[
          reader.readStringOrNull(offsets[11])] ??
      TransactionType.sent;
  return object;
}

P _transactionRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (_TransactionRecordplatformValueEnumMap[
              reader.readStringOrNull(offset)] ??
          Platform.gcash) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (_TransactionRecordtransactionTypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          TransactionType.sent) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TransactionRecordplatformEnumValueMap = {
  r'gcash': r'gcash',
  r'maya': r'maya',
  r'grabpay': r'grabpay',
  r'shopeepay': r'shopeepay',
  r'other': r'other',
};
const _TransactionRecordplatformValueEnumMap = {
  r'gcash': Platform.gcash,
  r'maya': Platform.maya,
  r'grabpay': Platform.grabpay,
  r'shopeepay': Platform.shopeepay,
  r'other': Platform.other,
};
const _TransactionRecordtransactionTypeEnumValueMap = {
  r'sent': r'sent',
  r'received': r'received',
  r'cashIn': r'cashIn',
  r'cashOut': r'cashOut',
  r'payment': r'payment',
};
const _TransactionRecordtransactionTypeValueEnumMap = {
  r'sent': TransactionType.sent,
  r'received': TransactionType.received,
  r'cashIn': TransactionType.cashIn,
  r'cashOut': TransactionType.cashOut,
  r'payment': TransactionType.payment,
};

Id _transactionRecordGetId(TransactionRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _transactionRecordGetLinks(
    TransactionRecord object) {
  return [];
}

void _transactionRecordAttach(
    IsarCollection<dynamic> col, Id id, TransactionRecord object) {
  object.id = id;
}

extension TransactionRecordQueryWhereSort
    on QueryBuilder<TransactionRecord, TransactionRecord, QWhere> {
  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TransactionRecordQueryWhere
    on QueryBuilder<TransactionRecord, TransactionRecord, QWhereClause> {
  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhereClause>
      senderNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'senderNumber',
        value: [null],
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhereClause>
      senderNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'senderNumber',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhereClause>
      senderNumberEqualTo(String? senderNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'senderNumber',
        value: [senderNumber],
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterWhereClause>
      senderNumberNotEqualTo(String? senderNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'senderNumber',
              lower: [],
              upper: [senderNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'senderNumber',
              lower: [senderNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'senderNumber',
              lower: [senderNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'senderNumber',
              lower: [],
              upper: [senderNumber],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TransactionRecordQueryFilter
    on QueryBuilder<TransactionRecord, TransactionRecord, QFilterCondition> {
  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      feeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fee',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      feeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fee',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      feeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      feeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      feeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fee',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      feeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fee',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      isSettledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSettled',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformEqualTo(
    Platform value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformGreaterThan(
    Platform value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformLessThan(
    Platform value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformBetween(
    Platform lower,
    Platform upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'platform',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'platform',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'platform',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      platformIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'platform',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      recordedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recordedAt',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      recordedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recordedAt',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      recordedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      recordedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recordedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      recordedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recordedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      recordedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recordedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'referenceNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'referenceNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'referenceNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referenceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      referenceNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referenceNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      remainingBalanceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remainingBalance',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      remainingBalanceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remainingBalance',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      remainingBalanceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      remainingBalanceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      remainingBalanceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      remainingBalanceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingBalance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'senderName',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'senderName',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'senderName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'senderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'senderName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderName',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'senderName',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'senderNumber',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'senderNumber',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'senderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'senderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'senderNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'senderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'senderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'senderNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'senderNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'senderNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      senderNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'senderNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeEqualTo(
    TransactionType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeGreaterThan(
    TransactionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeLessThan(
    TransactionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeBetween(
    TransactionType lower,
    TransactionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transactionType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transactionType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transactionType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transactionType',
        value: '',
      ));
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterFilterCondition>
      transactionTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transactionType',
        value: '',
      ));
    });
  }
}

extension TransactionRecordQueryObject
    on QueryBuilder<TransactionRecord, TransactionRecord, QFilterCondition> {}

extension TransactionRecordQueryLinks
    on QueryBuilder<TransactionRecord, TransactionRecord, QFilterCondition> {}

extension TransactionRecordQuerySortBy
    on QueryBuilder<TransactionRecord, TransactionRecord, QSortBy> {
  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy> sortByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByIsSettled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSettled', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByIsSettledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSettled', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByRecordedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAt', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByRecordedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAt', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByReferenceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNumber', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByReferenceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNumber', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByRemainingBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingBalance', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByRemainingBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingBalance', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortBySenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderName', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortBySenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderName', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortBySenderNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderNumber', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortBySenderNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderNumber', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      sortByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }
}

extension TransactionRecordQuerySortThenBy
    on QueryBuilder<TransactionRecord, TransactionRecord, QSortThenBy> {
  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy> thenByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByFeeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fee', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByIsSettled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSettled', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByIsSettledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSettled', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByRecordedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAt', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByRecordedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordedAt', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByReferenceNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNumber', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByReferenceNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceNumber', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByRemainingBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingBalance', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByRemainingBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingBalance', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenBySenderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderName', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenBySenderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderName', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenBySenderNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderNumber', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenBySenderNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'senderNumber', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByTransactionType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.asc);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QAfterSortBy>
      thenByTransactionTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transactionType', Sort.desc);
    });
  }
}

extension TransactionRecordQueryWhereDistinct
    on QueryBuilder<TransactionRecord, TransactionRecord, QDistinct> {
  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctByFee() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fee');
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctByIsSettled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSettled');
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctByPlatform({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'platform', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctByRecordedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordedAt');
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctByReferenceNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctByRemainingBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingBalance');
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctBySenderName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'senderName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctBySenderNumber({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'senderNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<TransactionRecord, TransactionRecord, QDistinct>
      distinctByTransactionType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transactionType',
          caseSensitive: caseSensitive);
    });
  }
}

extension TransactionRecordQueryProperty
    on QueryBuilder<TransactionRecord, TransactionRecord, QQueryProperty> {
  QueryBuilder<TransactionRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TransactionRecord, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<TransactionRecord, double?, QQueryOperations> feeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fee');
    });
  }

  QueryBuilder<TransactionRecord, bool, QQueryOperations> isSettledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSettled');
    });
  }

  QueryBuilder<TransactionRecord, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<TransactionRecord, Platform, QQueryOperations>
      platformProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'platform');
    });
  }

  QueryBuilder<TransactionRecord, DateTime?, QQueryOperations>
      recordedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordedAt');
    });
  }

  QueryBuilder<TransactionRecord, String, QQueryOperations>
      referenceNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceNumber');
    });
  }

  QueryBuilder<TransactionRecord, double?, QQueryOperations>
      remainingBalanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingBalance');
    });
  }

  QueryBuilder<TransactionRecord, String?, QQueryOperations>
      senderNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'senderName');
    });
  }

  QueryBuilder<TransactionRecord, String?, QQueryOperations>
      senderNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'senderNumber');
    });
  }

  QueryBuilder<TransactionRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<TransactionRecord, TransactionType, QQueryOperations>
      transactionTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transactionType');
    });
  }
}
