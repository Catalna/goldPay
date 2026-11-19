import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:goldpay_demo/domain/entities/qris_parse_result.dart';
import 'package:goldpay_demo/domain/qris/crc16.dart';
import 'package:goldpay_demo/domain/qris/qris_parser.dart';

const String f01 =
    '00020101021126720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR01630482C5';
const String f02 =
    '00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR0154061500006304555C';
const String f03 =
    '00020101021126720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Café Kenangan6007Jakarta61051234562110707KASIR016304E595';
const String f04 =
    '00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR01540610000055020357020563046ADF';
const String f05 =
    '00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153038405802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR01540510.006304DEFF';
const String f06 =
    '00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR01540615000063045550';
const String f07 =
    '00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR0154071500.5063048154';
const String f08 =
    '00020101021126720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID630436FA';
const String f09 = '00020101021126560016ID.CO.BANKCONTOH.WWW019993600014012345';
const String f10 = 'https://example.com/promo?utm=demo';

String tlv(String tag, String value) {
  final length = utf8.encode(value).length.toString().padLeft(2, '0');
  return '$tag$length$value';
}

String finish(String body) {
  final withHeader = '${body}6304';
  return '$withHeader${crc16Hex(utf8.encode(withHeader))}';
}

String payloadWith(String tag, String value, {String kind = '11'}) {
  return finish(
    tlv('00', '01') +
        tlv('01', kind) +
        tlv('53', '360') +
        tlv('58', 'ID') +
        tlv('59', 'Warung Uji') +
        tlv('60', 'Bandung') +
        tlv(tag, value),
  );
}

QrisSuccess success(String payload) {
  final result = parseQris(payload);
  expect(result, isA<QrisSuccess>(), reason: 'expected a successful parse');
  return result as QrisSuccess;
}

QrisErrorCode failureCode(String payload) {
  final result = parseQris(payload);
  expect(result, isA<QrisFailure>(), reason: 'expected a failure');
  return (result as QrisFailure).code;
}

void main() {
  group('fixtures F01-F10', () {
    test('F01 static, no amount, full merchant data, CRC valid', () {
      final qr = success(f01);
      expect(qr.kind, QrKind.staticQr);
      expect(qr.amountIdr, isNull);
      expect(qr.qrFeeIdr, 0);
      expect(qr.merchantName, 'Warung Bu Tini');
      expect(qr.merchantCity, 'Jakarta');
      expect(qr.merchantIssuerGui, 'ID.CO.BANKCONTOH.WWW');
      expect(qr.terminalLabel, 'KASIR01');
      expect(qr.crcValid, isTrue);
      expect(qr.warnings, isEmpty);
      expect(qr.isAmountReadOnly, isFalse);
    });

    test('F02 dynamic with Rp150.000 read-only', () {
      final qr = success(f02);
      expect(qr.kind, QrKind.dynamicQr);
      expect(qr.amountIdr, 150000);
      expect(qr.qrFeeIdr, 0);
      expect(qr.crcValid, isTrue);
      expect(qr.isAmountReadOnly, isTrue);
    });

    test('F03 counts TLV length in UTF-8 bytes, not characters', () {
      final qr = success(f03);
      expect(qr.merchantName, 'Café Kenangan');
      expect(qr.merchantName!.length, 13);
      expect(utf8.encode(qr.merchantName!).length, 14);
      expect(qr.crcValid, isTrue);
    });

    test('F04 reads 5% tip as Rp5.000', () {
      final qr = success(f04);
      expect(qr.amountIdr, 100000);
      expect(qr.qrFeeIdr, 5000);
      expect(qr.warnings, isEmpty);
      expect(qr.crcValid, isTrue);
    });

    test('F05 rejects non-IDR currency', () {
      expect(failureCode(f05), QrisErrorCode.unsupportedCurrency);
    });

    test('F06 CRC mismatch is a soft failure with a warning', () {
      final qr = success(f06);
      expect(qr.crcValid, isFalse);
      expect(qr.warnings, contains(QrisWarning.crcMismatch));
      expect(qr.merchantName, 'Warung Bu Tini');
    });

    test('F07 rejects decimal amount on IDR instead of rounding', () {
      expect(failureCode(f07), QrisErrorCode.invalidAmount);
    });

    test('F08 missing merchant name produces a warning, not a failure', () {
      final qr = success(f08);
      expect(qr.merchantName, isNull);
      expect(qr.merchantCity, isNull);
      expect(qr.warnings, contains(QrisWarning.missingMerchantName));
      expect(qr.crcValid, isTrue);
    });

    test('F09 truncated TLV is rejected', () {
      expect(failureCode(f09), QrisErrorCode.truncatedValue);
    });

    test('F10 plain URL is an unsupported format', () {
      expect(failureCode(f10), QrisErrorCode.unsupportedFormat);
    });
  });

  group('payload boundaries', () {
    test('empty and whitespace-only payloads are rejected', () {
      expect(failureCode(''), QrisErrorCode.emptyPayload);
      expect(failureCode('   \n\t '), QrisErrorCode.emptyPayload);
    });

    test('1024 bytes is allowed through the size gate, 1025 is not', () {
      final atLimit = '00${'0' * 1022}';
      expect(atLimit.length, 1024);
      expect(failureCode(atLimit), isNot(QrisErrorCode.payloadTooLarge));

      final overLimit = '00${'0' * 1023}';
      expect(overLimit.length, 1025);
      expect(failureCode(overLimit), QrisErrorCode.payloadTooLarge);
    });

    test('length must use UTF-8 bytes', () {
      final body =
          tlv('00', '01') +
          tlv('01', '11') +
          tlv('53', '360') +
          tlv('59', 'Café');
      final qr = success(finish(body));
      expect(qr.merchantName, 'Café');
    });
  });

  group('TLV rules', () {
    test('non-digit tag after the format tag is malformed', () {
      expect(failureCode('000A0200'), QrisErrorCode.malformedTlv);
    });

    test('duplicate critical tag is fatal', () {
      final body = tlv('00', '01') + tlv('00', '01') + tlv('53', '360');
      expect(failureCode(finish(body)), QrisErrorCode.duplicateCriticalTag);
    });

    test('duplicate non-critical tag keeps the first value and warns', () {
      final body =
          tlv('00', '01') +
          tlv('01', '11') +
          tlv('53', '360') +
          tlv('59', 'Pertama') +
          tlv('59', 'Kedua');
      final qr = success(finish(body));
      expect(qr.merchantName, 'Pertama');
      expect(qr.warnings, contains(QrisWarning.duplicateNonCriticalTag));
    });

    test('unknown tags warn but do not block', () {
      final body =
          tlv('00', '01') +
          tlv('01', '11') +
          tlv('53', '360') +
          tlv('59', 'Warung Uji') +
          tlv('80', 'rahasia');
      final qr = success(finish(body));
      expect(qr.warnings, contains(QrisWarning.unknownTagPresent));
    });

    test('CRC tag not at the end is reported and not verified', () {
      final head = '6304ABCD';
      final body =
          tlv('00', '01') +
          tlv('01', '11') +
          tlv('53', '360') +
          tlv('59', 'Warung Uji');
      final payload = '$body$head${tlv('60', 'Bandung')}';
      final qr = success(payload);
      expect(qr.crcValid, isFalse);
      expect(qr.warnings, contains(QrisWarning.crcNotLast));
    });

    test('missing CRC warns and reports crcValid false', () {
      final body =
          tlv('00', '01') +
          tlv('01', '11') +
          tlv('53', '360') +
          tlv('59', 'Warung Uji');
      final qr = success(body);
      expect(qr.crcValid, isFalse);
      expect(qr.warnings, contains(QrisWarning.crcMissing));
    });

    test('country other than ID warns', () {
      final body =
          tlv('00', '01') +
          tlv('01', '11') +
          tlv('53', '360') +
          tlv('58', 'SG') +
          tlv('59', 'Warung Uji');
      final qr = success(finish(body));
      expect(qr.warnings, contains(QrisWarning.unexpectedCountry));
    });

    test('payload format other than 01 is unsupported', () {
      final body = tlv('00', '02') + tlv('01', '11') + tlv('53', '360');
      expect(failureCode(finish(body)), QrisErrorCode.unsupportedFormat);
    });
  });

  group('amount validation', () {
    test('accepts whole rupiah and .00 decimals', () {
      expect(
        success(payloadWith('54', '150000', kind: '12')).amountIdr,
        150000,
      );
      expect(success(payloadWith('54', '1500.00', kind: '12')).amountIdr, 1500);
    });

    test('rejects zero in any spelling', () {
      expect(
        failureCode(payloadWith('54', '0', kind: '12')),
        QrisErrorCode.amountOutOfRange,
      );
      expect(
        failureCode(payloadWith('54', '0.00', kind: '12')),
        QrisErrorCode.amountOutOfRange,
      );
    });

    test('rejects decimals, scientific notation, comma and sloppy input', () {
      for (final raw in [
        '1500.50',
        '1e3',
        '1,000',
        ' 100',
        '100.',
        '.5',
        '99999999999999',
      ]) {
        expect(
          failureCode(payloadWith('54', raw, kind: '12')),
          QrisErrorCode.invalidAmount,
          reason: 'amount "$raw" must not be accepted',
        );
      }
    });

    test('dynamic without amount becomes unknown with a warning', () {
      final qr = success(payloadWith('59', 'Warung Uji', kind: '12'));
      expect(qr.kind, QrKind.unknown);
      expect(qr.amountIdr, isNull);
      expect(qr.isAmountReadOnly, isFalse);
      expect(qr.warnings, contains(QrisWarning.dynamicWithoutAmount));
    });

    test('unknown tag 01 with amount stays read-only', () {
      final qr = success(payloadWith('54', '5000', kind: '99'));
      expect(qr.kind, QrKind.unknown);
      expect(qr.amountIdr, 5000);
      expect(qr.isAmountReadOnly, isFalse);
    });
  });

  group('tip indicator', () {
    test('prompt tip is ignored with a warning', () {
      final body =
          tlv('00', '01') +
          tlv('01', '12') +
          tlv('53', '360') +
          tlv('54', '10000') +
          tlv('55', '01') +
          tlv('59', 'Warung Uji');
      final qr = success(finish(body));
      expect(qr.qrFeeIdr, 0);
      expect(qr.warnings, contains(QrisWarning.tipPromptIgnored));
    });

    test('fixed fee rounds up to whole rupiah', () {
      final body =
          tlv('00', '01') +
          tlv('01', '12') +
          tlv('53', '360') +
          tlv('54', '10000') +
          tlv('55', '02') +
          tlv('56', '2500.01') +
          tlv('59', 'Warung Uji');
      final qr = success(finish(body));
      expect(qr.qrFeeIdr, 2501);
    });

    test('percentage fee uses ceil', () {
      final body =
          tlv('00', '01') +
          tlv('01', '12') +
          tlv('53', '360') +
          tlv('54', '333') +
          tlv('55', '03') +
          tlv('57', '0.5') +
          tlv('59', 'Warung Uji');
      final qr = success(finish(body));
      // 333 x 0.5% = 1.665 -> 2
      expect(qr.qrFeeIdr, 2);
    });

    test('incomplete tip rules warn and charge zero', () {
      final body =
          tlv('00', '01') +
          tlv('01', '12') +
          tlv('53', '360') +
          tlv('54', '10000') +
          tlv('55', '03') +
          tlv('59', 'Warung Uji');
      final qr = success(finish(body));
      expect(qr.qrFeeIdr, 0);
      expect(qr.warnings, contains(QrisWarning.tipIncomplete));
    });

    test('fee tags without an indicator warn', () {
      final body =
          tlv('00', '01') +
          tlv('01', '12') +
          tlv('53', '360') +
          tlv('54', '10000') +
          tlv('56', '1000') +
          tlv('59', 'Warung Uji');
      final qr = success(finish(body));
      expect(qr.warnings, contains(QrisWarning.tipIncomplete));
    });
  });

  group('sanitisation', () {
    test('strips control and bidi characters, collapses whitespace', () {
      final name = '  Warung\u0000 Bu\n\tTini\u202E  ';
      final body =
          tlv('00', '01') +
          tlv('01', '11') +
          tlv('53', '360') +
          tlv('59', name);
      final qr = success(finish(body));
      expect(qr.merchantName, 'Warung Bu Tini');
    });

    test('keeps a 64-character name intact, ellipsis belongs to the UI', () {
      final name = 'A' * 64;
      final body =
          tlv('00', '01') +
          tlv('01', '11') +
          tlv('53', '360') +
          tlv('59', name);
      final qr = success(finish(body));
      expect(qr.merchantName, name);
    });

    test('replacement character in a name becomes a warning', () {
      final body =
          tlv('00', '01') +
          tlv('01', '11') +
          tlv('53', '360') +
          tlv('59', 'Warung \uFFFD Uji');
      final qr = success(finish(body));
      expect(qr.warnings, contains(QrisWarning.nonAsciiValue));
    });
  });

  group('robustness', () {
    test('10.000 random payloads never throw', () {
      final random = Random(20260119);
      const alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.-:/';
      for (var i = 0; i < 10000; i++) {
        final length = random.nextInt(160);
        final buffer = StringBuffer();
        if (random.nextBool()) buffer.write('000201');
        for (var j = 0; j < length; j++) {
          buffer.write(alphabet[random.nextInt(alphabet.length)]);
        }
        final input = buffer.toString();
        try {
          final result = parseQris(input);
          expect(result, isA<QrisParseResult>());
        } catch (error) {
          fail('parse threw at fuzz index $i: $error');
        }
      }
    });
  });
}
