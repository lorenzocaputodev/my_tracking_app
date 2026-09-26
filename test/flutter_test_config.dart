import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _families = <String, List<String>>{
  'DM Sans': [
    'assets/fonts/DMSans-Regular.ttf',
    'assets/fonts/DMSans-Medium.ttf',
    'assets/fonts/DMSans-SemiBold.ttf',
    'assets/fonts/DMSans-Bold.ttf',
    'assets/fonts/DMSans-ExtraBold.ttf',
    'assets/fonts/DMSans-Black.ttf',
  ],
  'Nunito': [
    'assets/fonts/Nunito-Bold.ttf',
  ],
};

Future<void> _loadFamilies() async {
  for (final entry in _families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      final bytes = await File(path).readAsBytes();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

Future<void> _loadMaterialIcons() async {
  try {
    final loader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await loader.load();
  } catch (_) {}
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFamilies();
  await _loadMaterialIcons();
  await testMain();
}
