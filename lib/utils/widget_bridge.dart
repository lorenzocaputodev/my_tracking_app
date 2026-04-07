import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WidgetBridge {
  static const MethodChannel _channel =
      MethodChannel('com.example.my_tracking_app/widget');

  static Future<void> updateWidgets() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('updateWidgets');
    } catch (_) {}
  }
}
