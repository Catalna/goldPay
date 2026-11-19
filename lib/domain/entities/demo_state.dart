import 'demo_transaction.dart';

/// Single persisted blob (docs/10 §2.1). Immutable value object.
final class DemoState {
  const DemoState({
    required this.schemaVersion,
    required this.appVersion,
    required this.balanceUnits,
    required this.pricingConfigVersion,
    required this.transactions,
    required this.lastUpdatedAt,
  });

  static const int currentSchemaVersion = 1;
  static const int maxTransactions = 200;

  final int schemaVersion;
  final String appVersion;
  final int balanceUnits;
  final String pricingConfigVersion;

  /// Newest first, maximum [maxTransactions].
  final List<DemoTransaction> transactions;
  final DateTime lastUpdatedAt;

  bool get isEmptyHistory => transactions.isEmpty;

  DemoState copyWith({
    int? balanceUnits,
    String? pricingConfigVersion,
    List<DemoTransaction>? transactions,
    DateTime? lastUpdatedAt,
  }) {
    return DemoState(
      schemaVersion: schemaVersion,
      appVersion: appVersion,
      balanceUnits: balanceUnits ?? this.balanceUnits,
      pricingConfigVersion: pricingConfigVersion ?? this.pricingConfigVersion,
      transactions: transactions ?? this.transactions,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
