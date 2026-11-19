import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/demo_config.dart';
import '../core/errors/result.dart';
import '../data/prefs_demo_repository.dart';
import '../domain/entities/demo_state.dart';
import '../domain/entities/demo_transaction.dart';
import '../domain/transaction/demo_payment_orchestrator.dart';

/// Override this provider in tests to use different prices or balances.
final demoConfigProvider = Provider<DemoPricingConfig>(
  (ref) => DemoPricingConfig.standard,
);

/// Injected in `main()` so storage is ready before the first frame.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

/// Shown on the receipt for diagnostics only.
final appVersionProvider = Provider<String>((ref) => '0.1.0+1');

DemoState buildInitialDemoState({
  required DemoPricingConfig config,
  required String appVersion,
  required DateTime now,
}) {
  return DemoState(
    schemaVersion: DemoState.currentSchemaVersion,
    appVersion: appVersion,
    balanceUnits: config.initialBalanceUnits,
    pricingConfigVersion: config.version,
    transactions: const <DemoTransaction>[],
    lastUpdatedAt: now.toUtc(),
  );
}

final demoRepositoryProvider = Provider<DemoRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final config = ref.watch(demoConfigProvider);
  final appVersion = ref.watch(appVersionProvider);
  return PrefsDemoRepository(
    prefs,
    () => buildInitialDemoState(
      config: config,
      appVersion: appVersion,
      now: DateTime.now(),
    ),
  );
});

final demoPaymentOrchestratorProvider = Provider<DemoPaymentOrchestrator>(
  (ref) => DemoPaymentOrchestrator(ref.watch(demoRepositoryProvider)),
);

final demoStateProvider = AsyncNotifierProvider<DemoStateController, DemoState>(
  DemoStateController.new,
);

/// Owns the single persisted blob. Mutations always go through the repository.
final class DemoStateController extends AsyncNotifier<DemoState> {
  @override
  Future<DemoState> build() async {
    final result = await ref.watch(demoRepositoryProvider).load();
    return switch (result) {
      Ok(value: final state) => state,
      Err(failure: final failure) => throw DemoStorageException(failure.code),
    };
  }

  /// Mirrors the state the repository confirmed after a commit.
  void applyCommitted(DemoState state) {
    this.state = AsyncData(state);
  }

  Future<void> reset() async {
    final config = ref.read(demoConfigProvider);
    final fresh = buildInitialDemoState(
      config: config,
      appVersion: ref.read(appVersionProvider),
      now: DateTime.now(),
    );
    final result = await ref.read(demoRepositoryProvider).resetTo(fresh);
    switch (result) {
      case Ok(value: final saved):
        state = AsyncData(saved);
      case Err(failure: final failure):
        throw DemoStorageException(failure.code);
    }
  }

  Future<void> addGold(int units) async {
    if (units <= 0) return;
    final current = state.value;
    if (current == null) throw const DemoStorageException('STATE_UNAVAILABLE');

    final next = current.copyWith(
      balanceUnits: current.balanceUnits + units,
      lastUpdatedAt: DateTime.now().toUtc(),
    );
    final result = await ref
        .read(demoRepositoryProvider)
        .writeAtomic(previous: current, next: next);
    switch (result) {
      case Ok(value: final saved):
        state = AsyncData(saved);
      case Err(failure: final failure):
        throw DemoStorageException(failure.code);
    }
  }
}

/// Storage failure surfaced to the UI as a message, never as "success".
final class DemoStorageException implements Exception {
  const DemoStorageException(this.code);
  final String code;

  @override
  String toString() => 'DemoStorageException($code)';
}
