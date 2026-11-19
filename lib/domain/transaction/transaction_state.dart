/// Transaction states from docs/11 §1. Only [completedDemo] is persisted.
enum TxState {
  draft,
  quoted,
  expired,
  confirming,
  processingDemo,
  completedDemo,
  failedDemo,
  cancelled,
}

/// Scan/paste result plus the chosen amount, before a quote exists.
final class PaymentDraft {
  const PaymentDraft({
    required this.source,
    required this.qrKind,
    required this.merchantName,
    required this.merchantCity,
    required this.merchantIssuerGui,
    required this.crcValid,
    required this.warningCodes,
    required this.paymentAmountIdr,
    required this.qrFeeIdr,
    required this.amountReadOnly,
  });

  final String source;
  final String qrKind;
  final String? merchantName;
  final String? merchantCity;
  final String? merchantIssuerGui;
  final bool crcValid;
  final List<String> warningCodes;
  final int paymentAmountIdr;
  final int qrFeeIdr;
  final bool amountReadOnly;

  PaymentDraft copyWith({int? paymentAmountIdr}) {
    return PaymentDraft(
      source: source,
      qrKind: qrKind,
      merchantName: merchantName,
      merchantCity: merchantCity,
      merchantIssuerGui: merchantIssuerGui,
      crcValid: crcValid,
      warningCodes: warningCodes,
      paymentAmountIdr: paymentAmountIdr ?? this.paymentAmountIdr,
      qrFeeIdr: qrFeeIdr,
      amountReadOnly: amountReadOnly,
    );
  }
}
