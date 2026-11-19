import '../../../domain/entities/qris_parse_result.dart';
import '../../../domain/qris/qris_parser.dart';
import '../../../domain/transaction/transaction_state.dart';

sealed class DraftResult {
  const DraftResult();
}

final class DraftReady extends DraftResult {
  const DraftReady(this.draft);
  final PaymentDraft draft;
}

final class DraftInvalid extends DraftResult {
  const DraftInvalid(this.code);
  final QrisErrorCode code;
}

/// Reads a payload into a draft. No merchant field is invented: anything the
/// QR does not carry stays null (AGENTS.md constraint 4).
DraftResult buildDraft(String payload, {required String source}) {
  final parsed = parseQris(payload);
  return switch (parsed) {
    QrisFailure(:final code) => DraftInvalid(code),
    QrisSuccess(
      :final kind,
      :final amountIdr,
      :final qrFeeIdr,
      :final merchantName,
      :final merchantCity,
      :final merchantIssuerGui,
      :final crcValid,
      :final warnings,
      :final isAmountReadOnly,
    ) =>
      DraftReady(
        PaymentDraft(
          source: source,
          qrKind: kind.wireName,
          merchantName: merchantName,
          merchantCity: merchantCity,
          merchantIssuerGui: merchantIssuerGui,
          crcValid: crcValid,
          warningCodes: [for (final warning in warnings) warning.code],
          paymentAmountIdr: amountIdr ?? 0,
          qrFeeIdr: qrFeeIdr,
          amountReadOnly: isAmountReadOnly,
        ),
      ),
  };
}
