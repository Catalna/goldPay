import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors/result.dart';
import '../domain/entities/demo_state.dart';
import 'demo_state_codec.dart';

abstract interface class DemoRepository {
  /// Loads state, recovering from `_prev` when the main blob is corrupt.
  Future<Result<DemoState>> load();

  /// Writes `_prev` first, then the main blob, and verifies the readback.
  Future<Result<DemoState>> writeAtomic({
    required DemoState previous,
    required DemoState next,
  });

  /// Writes the same blob to both keys (used by first run and reset).
  Future<Result<DemoState>> resetTo(DemoState state);
}

final class PrefsDemoRepository implements DemoRepository {
  PrefsDemoRepository(this._prefs, this._initialState);

  static const String mainKey = 'goldpay_state_v1';
  static const String prevKey = 'goldpay_state_prev_v1';

  final SharedPreferences _prefs;
  final DemoState Function() _initialState;

  @override
  Future<Result<DemoState>> load() async {
    final main = _prefs.getString(mainKey);
    if (main == null) {
      return resetTo(_initialState());
    }

    final decoded = _decode(main);
    if (decoded is _Decoded) return Ok(decoded.state);
    if (decoded is _TooNew) {
      return Err(Failure('SCHEMA_TOO_NEW'));
    }

    final previous = _prefs.getString(prevKey);
    if (previous != null) {
      final recovered = _decode(previous);
      if (recovered is _Decoded) {
        final rewritten = await resetTo(recovered.state);
        if (rewritten is Err<DemoState>) return rewritten;
        return Ok(recovered.state);
      }
    }
    return Err(Failure('STORAGE_CORRUPT'));
  }

  @override
  Future<Result<DemoState>> writeAtomic({
    required DemoState previous,
    required DemoState next,
  }) async {
    final prevEncoded = jsonEncode(demoStateToJson(previous));
    final nextEncoded = jsonEncode(demoStateToJson(next));

    final wrotePrev = await _prefs.setString(prevKey, prevEncoded);
    if (!wrotePrev) return Err(Failure('STORAGE_PREV_WRITE_FAILED'));

    final wroteMain = await _prefs.setString(mainKey, nextEncoded);
    if (!wroteMain) return Err(Failure('STORAGE_WRITE_FAILED'));

    if (_prefs.getString(mainKey) == nextEncoded) return Ok(next);

    // One retry, then report failure. The caller never shows success.
    final retried = await _prefs.setString(mainKey, nextEncoded);
    if (retried && _prefs.getString(mainKey) == nextEncoded) return Ok(next);
    return Err(Failure('STORAGE_VERIFY_FAILED'));
  }

  @override
  Future<Result<DemoState>> resetTo(DemoState state) async {
    final encoded = jsonEncode(demoStateToJson(state));
    final wrotePrev = await _prefs.setString(prevKey, encoded);
    if (!wrotePrev) return Err(Failure('STORAGE_PREV_WRITE_FAILED'));
    final wroteMain = await _prefs.setString(mainKey, encoded);
    if (!wroteMain) return Err(Failure('STORAGE_WRITE_FAILED'));
    return Ok(state);
  }
}

sealed class _DecodeOutcome {
  const _DecodeOutcome();
}

final class _Decoded extends _DecodeOutcome {
  const _Decoded(this.state);
  final DemoState state;
}

final class _TooNew extends _DecodeOutcome {
  const _TooNew();
}

final class _Corrupt extends _DecodeOutcome {
  const _Corrupt();
}

_DecodeOutcome _decode(String raw) {
  try {
    final json = jsonDecode(raw);
    if (json is! Map<String, Object?>) return const _Corrupt();
    return _Decoded(demoStateFromJson(json));
  } on SchemaTooNewException {
    return const _TooNew();
  } catch (_) {
    return const _Corrupt();
  }
}
