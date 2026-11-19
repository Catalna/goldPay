import '../../core/constants/demo_config.dart';
import '../../core/errors/result.dart';
import '../../data/prefs_demo_repository.dart';
import '../entities/conversion_quote.dart';
import '../entities/demo_state.dart';
import '../entities/demo_transaction.dart';
import '../pricing/quote_validator.dart';
import 'transaction_state.dart';

/// Result of a simulated payment attempt (docs/11 §1).
sealed class DemoCommitOutcome {
  const DemoCommitOutcome();
}

final class DemoCommitted extends DemoCommitOutcome {
  const DemoCommitted(
    this.transaction,
    this.state, {
    this.recoveredAttempt = false,
  });

  /// Built from the record that was actually persisted, never from UI state.
  final DemoTransaction transaction;

  /// State the repository confirmed, so the UI can mirror storage exactly.
  final DemoState state;

  /// True when the same [DemoTransaction.attemptId] was already committed.
  final bool recoveredAttempt;
}

final class DemoRejected extends DemoCommitOutcome {
  const DemoRejected(this.code, {this.detailForDev});

  /// Stable code, e.g. `INSUFFICIENT_BALANCE`, `QUOTE_EXPIRED`,
  /// `FORCED_FAILURE`, or a `STORAGE_*` failure from the repository.
  final String code;
  final String? detailForDev;
}

/// Turns a confirmed quote into one immutable `completed_demo` record.
///
/// The only write path in the app: balance and history change together or not
/// at all (docs/08 §7, docs/10 §5). Nothing here can claim a real payment.
final class DemoPaymentOrchestrator {
  const DemoPaymentOrchestrator(this._repository);

  final DemoRepository _repository;

  Future<DemoCommitOutcome> commit({
    required ConversionQuote quote,
    required PaymentDraft draft,
    required DemoState currentState,
    required DemoPricingConfig config,
    required String attemptId,
    required DateTime now,
    bool forceFailure = false,
  }) async {
    // Idempotency: a retried submit after a successful write must not deduct
    // twice (docs/11 §4).
    for (final existing in currentState.transactions) {
      if (existing.attemptId == attemptId) {
        return DemoCommitted(existing, currentState, recoveredAttempt: true);
      }
    }

    final issue = validateQuote(
      quote: quote,
      config: config,
      balanceUnits: currentState.balanceUnits,
      now: now,
    );
    if (issue != null) {
      return DemoRejected(issue.code);
    }

    if (forceFailure) {
      return const DemoRejected('FORCED_FAILURE');
    }

    final transaction = DemoTransaction(
      id: quote.quoteId,
      attemptId: attemptId,
      createdAt: now.toUtc(),
      paymentAmountIdr: quote.paymentAmountIdr,
      qrFeeIdr: quote.qrFeeIdr,
      totalIdr: quote.totalIdr,
      goldPriceDisplayIdrPerGram: quote.goldPriceDisplayIdrPerGram,
      goldBuybackPriceIdrPerGram: quote.goldBuybackPriceIdrPerGram,
      goldUnits: quote.goldUnits,
      goldValueIdr: quote.goldValueIdr,
      roundingIdr: quote.roundingIdr,
      balanceBeforeUnits: currentState.balanceUnits,
      balanceAfterUnits: currentState.balanceUnits - quote.goldUnits,
      merchantName: draft.merchantName,
      merchantCity: draft.merchantCity,
      merchantIssuerGui: draft.merchantIssuerGui,
      qrKind: draft.qrKind,
      crcValid: draft.crcValid,
      warningCodes: draft.warningCodes,
      source: draft.source,
      pricingConfigVersion: quote.pricingConfigVersion,
      disclosureVersion: quote.disclosureVersion,
    );

    final nextState = currentState.copyWith(
      balanceUnits: transaction.balanceAfterUnits,
      transactions: _withRecord(currentState.transactions, transaction),
      lastUpdatedAt: now.toUtc(),
    );

    final writeResult = await _repository.writeAtomic(
      previous: currentState,
      next: nextState,
    );

    return switch (writeResult) {
      Ok(value: final saved) => DemoCommitted(
        _find(saved, transaction.id),
        saved,
      ),
      Err(failure: final failure) => DemoRejected(
        failure.code,
        detailForDev: failure.detailForDev,
      ),
    };
  }

  static List<DemoTransaction> _withRecord(
    List<DemoTransaction> current,
    DemoTransaction transaction,
  ) {
    final next = <DemoTransaction>[transaction, ...current];
    if (next.length <= DemoState.maxTransactions) return next;
    return next.sublist(0, DemoState.maxTransactions);
  }

  /// Reads the committed record back from the state the repository returned.
  static DemoTransaction _find(DemoState state, String id) {
    for (final transaction in state.transactions) {
      if (transaction.id == id) return transaction;
    }
    throw StateError('committed transaction missing from stored state');
  }
}
