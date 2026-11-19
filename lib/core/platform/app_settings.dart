import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('id.goldpay.concept/settings');

/// Opens the OS app-settings page. Used only when the camera permission was
/// denied permanently; there is no network and no other platform channel.
Future<void> openAppSettings() async {
  try {
    await _channel.invokeMethod<bool>('openAppSettings');
  } on MissingPluginException {
    // Widget tests and unsupported platforms: nothing to open.
  }
}
