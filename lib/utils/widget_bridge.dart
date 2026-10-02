import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WidgetBridge {
  static const MethodChannel _channel =
      MethodChannel('dev.lorenzocaputo.mytrackingapp/widget');

  static Future<void> updateWidgets() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('updateWidgets');
    } catch (_) {}
  }
}
