import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/constants/demo_config.dart';
import '../../../domain/entities/conversion_quote.dart';
import '../../../domain/entities/demo_transaction.dart';
import '../../../domain/pricing/gold_conversion_calculator.dart';
import '../../../domain/transaction/demo_payment_orchestrator.dart';
import '../../../domain/transaction/transaction_state.dart';

const Uuid _uuid = Uuid();

/// Cosmetic processing delay (docs/08 §7 step 5). Tests override it to zero.
final checkoutDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 900),
);

/// "Paksa gagal transaksi berikutnya" (D-44). One-shot and memory-only.
final forceFailureProvider = NotifierProvider<ForceFailureController, bool>(
  ForceFailureController.new,
);

final class ForceFailureController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;

  /// Consumed after one attempt so the next demo run succeeds normally.
  void consume() => state = false;
}

final checkoutProvider = NotifierProvider<CheckoutController, CheckoutState>(
  CheckoutController.new,
);

final class CheckoutState {
  const CheckoutState({
    this.draft,
    this.quote,
    this.attemptId,
    this.isCommitting = false,
    this.transaction,
    this.failureCode,
  });

  final PaymentDraft? draft;
  final ConversionQuote? quote;
  final String? attemptId;
  final bool isCommitting;

  /// Only set after a successful commit, built from the stored record.
  final DemoTransaction? transaction;
  final String? failureCode;

  bool get hasQuote => quote != null;
  bool get hasResult => transaction != null;

  CheckoutState copyWith({
    PaymentDraft? draft,
    ConversionQuote? quote,
    String? attemptId,
    bool? isCommitting,
    DemoTransaction? transaction,
    String? failureCode,
    bool clearQuote = false,
    bool clearAttemptId = false,
    bool clearFailure = false,
  }) {
    return CheckoutState(
      draft: draft ?? this.draft,
      quote: clearQuote ? null : (quote ?? this.quote),
      attemptId: clearAttemptId ? null : (attemptId ?? this.attemptId),
      isCommitting: isCommitting ?? this.isCommitting,
      transaction: transaction ?? this.transaction,
      failureCode: clearFailure ? null : (failureCode ?? this.failureCode),
    );
  }
}

final class CheckoutController extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  /// Begins a new draft; any previous quote or result is discarded.
  void start(PaymentDraft draft) {
    state = CheckoutState(draft: draft);
  }

  void setAmount(int amountIdr) {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(
      draft: draft.copyWith(paymentAmountIdr: amountIdr),
      clearQuote: true,
      clearAttemptId: true,
      clearFailure: true,
    );
  }

  /// [now] exists so tests can build an already-expired quote without waiting.
  ConversionQuote? createQuote({
    required DemoPricingConfig config,
    required int balanceUnits,
    DateTime? now,
  }) {
    final draft = state.draft;
    if (draft == null) return null;

    final quote = buildConversionQuote(
      config: config,
      quoteId: _uuid.v4(),
      paymentAmountIdr: draft.paymentAmountIdr,
      qrFeeIdr: draft.qrFeeIdr,
      balanceBeforeUnits: balanceUnits,
      now: now ?? DateTime.now(),
    );
    state = state.copyWith(
      quote: quote,
      clearAttemptId: true,
      clearFailure: true,
    );
    return quote;
  }

  /// Keeps the draft, creates a fresh quote with a new id.
  ConversionQuote? refreshQuote({
    required DemoPricingConfig config,
    required int balanceUnits,
    DateTime? now,
  }) {
    return createQuote(config: config, balanceUnits: balanceUnits, now: now);
  }

  void cancel() {
    state = const CheckoutState();
  }

  /// Commits at most once per tap; the synchronous [isCommitting] flag makes a
  /// double tap a no-op (docs/08 §7, docs/11 §4).
  Future<DemoCommitOutcome?> confirm({
    required DemoPricingConfig config,
  }) async {
    final snapshot = state;
    final draft = snapshot.draft;
    final quote = snapshot.quote;
    if (draft == null || quote == null || snapshot.isCommitting) return null;

    final attemptId = snapshot.attemptId ?? _uuid.v4();
    final forced = ref.read(forceFailureProvider);
    state = snapshot.copyWith(
      attemptId: attemptId,
      isCommitting: true,
      clearFailure: true,
    );

    final demoState = ref.read(demoStateProvider).value;
    if (demoState == null) {
      state = state.copyWith(
        isCommitting: false,
        failureCode: 'STATE_UNAVAILABLE',
      );
      return const DemoRejected('STATE_UNAVAILABLE');
    }

    DemoCommitOutcome outcome;
    try {
      final delay = ref.read(checkoutDelayProvider);
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      outcome = await ref
          .read(demoPaymentOrchestratorProvider)
          .commit(
            quote: quote,
            draft: draft,
            currentState: demoState,
            config: config,
            attemptId: attemptId,
            now: DateTime.now(),
            forceFailure: forced,
          );
    } catch (error) {
      outcome = DemoRejected('STORAGE_ERROR', detailForDev: '$error');
    }

    if (forced) ref.read(forceFailureProvider.notifier).consume();

    switch (outcome) {
      case final DemoCommitted committed:
        ref.read(demoStateProvider.notifier).applyCommitted(committed.state);
        state = CheckoutState(transaction: committed.transaction);
      case DemoRejected(:final code):
        state = state.copyWith(
          isCommitting: false,
          clearAttemptId: true,
          failureCode: code,
        );
    }
    return outcome;
  }
}
