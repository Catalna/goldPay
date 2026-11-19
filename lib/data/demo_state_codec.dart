import '../domain/entities/demo_state.dart';
import '../domain/entities/demo_transaction.dart';

/// Raised when stored data was written by a newer app version.
final class SchemaTooNewException implements Exception {
  const SchemaTooNewException(this.found);
  final int found;

  @override
  String toString() => 'SchemaTooNewException($found)';
}

Map<String, Object?> demoStateToJson(DemoState state) {
  return {
    'schemaVersion': state.schemaVersion,
    'appVersion': state.appVersion,
    'balanceUnits': state.balanceUnits,
    'pricingConfigVersion': state.pricingConfigVersion,
    'lastUpdatedAt': state.lastUpdatedAt.toUtc().toIso8601String(),
    'transactions': [
      for (final transaction in state.transactions)
        demoTransactionToJson(transaction),
    ],
  };
}

Map<String, Object?> demoTransactionToJson(DemoTransaction transaction) {
  return {
    'id': transaction.id,
    'attemptId': transaction.attemptId,
    'createdAt': transaction.createdAt.toUtc().toIso8601String(),
    'status': DemoTransaction.statusCompletedDemo,
    'paymentAmountIdr': transaction.paymentAmountIdr,
    'qrFeeIdr': transaction.qrFeeIdr,
    'totalIdr': transaction.totalIdr,
    'goldPriceDisplayIdrPerGram': transaction.goldPriceDisplayIdrPerGram,
    'goldBuybackPriceIdrPerGram': transaction.goldBuybackPriceIdrPerGram,
    'goldUnits': transaction.goldUnits,
    'goldValueIdr': transaction.goldValueIdr,
    'roundingIdr': transaction.roundingIdr,
    'balanceBeforeUnits': transaction.balanceBeforeUnits,
    'balanceAfterUnits': transaction.balanceAfterUnits,
    'merchantName': transaction.merchantName,
    'merchantCity': transaction.merchantCity,
    'merchantIssuerGui': transaction.merchantIssuerGui,
    'qrKind': transaction.qrKind,
    'crcValid': transaction.crcValid,
    'warningCodes': transaction.warningCodes,
    'source': transaction.source,
    'pricingConfigVersion': transaction.pricingConfigVersion,
    'disclosureVersion': transaction.disclosureVersion,
  };
}

DemoState demoStateFromJson(Map<String, Object?> json) {
  final schemaVersion = _int(json, 'schemaVersion');
  if (schemaVersion > DemoState.currentSchemaVersion) {
    throw SchemaTooNewException(schemaVersion);
  }
  if (schemaVersion < 1) {
    throw const FormatException('unsupported schema version');
  }

  final rawTransactions = json['transactions'];
  if (rawTransactions is! List) {
    throw const FormatException('transactions must be a list');
  }
  if (rawTransactions.length > DemoState.maxTransactions) {
    throw const FormatException('too many transactions');
  }

  final transactions = <DemoTransaction>[
    for (final raw in rawTransactions) demoTransactionFromJson(_map(raw)),
  ];

  return DemoState(
    schemaVersion: DemoState.currentSchemaVersion,
    appVersion: _string(json, 'appVersion'),
    balanceUnits: _int(json, 'balanceUnits'),
    pricingConfigVersion: _string(json, 'pricingConfigVersion'),
    transactions: transactions,
    lastUpdatedAt: _date(json, 'lastUpdatedAt'),
  );
}

DemoTransaction demoTransactionFromJson(Map<String, Object?> json) {
  final status = _string(json, 'status');
  if (status != DemoTransaction.statusCompletedDemo) {
    throw const FormatException('only completed_demo is persisted');
  }

  final rawWarnings = json['warningCodes'];
  if (rawWarnings is! List) {
    throw const FormatException('warningCodes must be a list');
  }

  return DemoTransaction(
    id: _string(json, 'id'),
    attemptId: _string(json, 'attemptId'),
    createdAt: _date(json, 'createdAt'),
    paymentAmountIdr: _int(json, 'paymentAmountIdr'),
    qrFeeIdr: _int(json, 'qrFeeIdr'),
    totalIdr: _int(json, 'totalIdr'),
    goldPriceDisplayIdrPerGram: _int(json, 'goldPriceDisplayIdrPerGram'),
    goldBuybackPriceIdrPerGram: _int(json, 'goldBuybackPriceIdrPerGram'),
    goldUnits: _int(json, 'goldUnits'),
    goldValueIdr: _int(json, 'goldValueIdr'),
    roundingIdr: _int(json, 'roundingIdr'),
    balanceBeforeUnits: _int(json, 'balanceBeforeUnits'),
    balanceAfterUnits: _int(json, 'balanceAfterUnits'),
    merchantName: _nullableString(json, 'merchantName'),
    merchantCity: _nullableString(json, 'merchantCity'),
    merchantIssuerGui: _nullableString(json, 'merchantIssuerGui'),
    qrKind: _string(json, 'qrKind'),
    crcValid: _bool(json, 'crcValid'),
    warningCodes: [
      for (final code in rawWarnings)
        if (code is String)
          code
        else
          throw const FormatException('warning code must be a string'),
    ],
    source: _string(json, 'source'),
    pricingConfigVersion: _string(json, 'pricingConfigVersion'),
    disclosureVersion: _string(json, 'disclosureVersion'),
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  throw const FormatException('expected an object');
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('$key must be a string');
}

String? _nullableString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null || value is String) return value as String?;
  throw FormatException('$key must be a string or null');
}

int _int(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('$key must be an int');
}

bool _bool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  throw FormatException('$key must be a bool');
}

DateTime _date(Map<String, Object?> json, String key) {
  final raw = _string(json, key);
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) throw FormatException('$key is not ISO-8601');
  return parsed.toUtc();
}
