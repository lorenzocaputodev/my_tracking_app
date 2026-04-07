import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

enum BackupFileReadStatus { success, cancelled, unsupported }

enum BackupFileSaveStatus { success, cancelled, unsupported }

class BackupFileReadResult {
  final BackupFileReadStatus status;
  final String? content;
  final String? path;

  const BackupFileReadResult._({
    required this.status,
    this.content,
    this.path,
  });

  const BackupFileReadResult.success({
    required String content,
    required String path,
  }) : this._(
          status: BackupFileReadStatus.success,
          content: content,
          path: path,
        );

  const BackupFileReadResult.cancelled()
      : this._(status: BackupFileReadStatus.cancelled);

  const BackupFileReadResult.unsupported()
      : this._(status: BackupFileReadStatus.unsupported);
}

class BackupFileSaveResult {
  final BackupFileSaveStatus status;
  final String? path;

  const BackupFileSaveResult._({
    required this.status,
    this.path,
  });

  const BackupFileSaveResult.success(String path)
      : this._(status: BackupFileSaveStatus.success, path: path);

  const BackupFileSaveResult.cancelled()
      : this._(status: BackupFileSaveStatus.cancelled);

  const BackupFileSaveResult.unsupported()
      : this._(status: BackupFileSaveStatus.unsupported);
}

class BackupFileService {
  static const XTypeGroup _csvTypeGroup = XTypeGroup(
    label: 'CSV',
    extensions: <String>['csv'],
    mimeTypes: <String>[
      'text/csv',
      'application/csv',
      'text/comma-separated-values',
    ],
  );

  static bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isSupported => _isWindows || _isAndroid;

  static Future<BackupFileReadResult> pickCsvFile() async {
    if (_isWindows) {
      final file = await openFile(
        acceptedTypeGroups: const <XTypeGroup>[_csvTypeGroup],
        confirmButtonText: 'Apri CSV',
      );
      if (file == null) {
        return const BackupFileReadResult.cancelled();
      }
      final content = await file.readAsString();
      return BackupFileReadResult.success(content: content, path: file.path);
    }

    if (_isAndroid) {
      final path = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(
          fileExtensionsFilter: <String>['csv'],
          mimeTypesFilter: <String>[
            'text/csv',
            'application/csv',
            'text/comma-separated-values',
          ],
          localOnly: true,
          copyFileToCacheDir: true,
        ),
      );
      if (path == null || path.trim().isEmpty) {
        return const BackupFileReadResult.cancelled();
      }
      final content = await File(path).readAsString(encoding: utf8);
      return BackupFileReadResult.success(content: content, path: path);
    }

    return const BackupFileReadResult.unsupported();
  }

  static Future<BackupFileSaveResult> saveCsvFile({
    required String fileName,
    required String content,
  }) async {
    if (_isWindows) {
      final initialDirectory = (await getApplicationDocumentsDirectory()).path;
      final location = await getSaveLocation(
        acceptedTypeGroups: const <XTypeGroup>[_csvTypeGroup],
        initialDirectory: initialDirectory,
        suggestedName: fileName,
        confirmButtonText: 'Salva CSV',
      );
      if (location == null) {
        return const BackupFileSaveResult.cancelled();
      }
      final file = File(location.path);
      await file.writeAsString(content, encoding: utf8, flush: true);
      return BackupFileSaveResult.success(file.path);
    }

    if (_isAndroid) {
      final tempDir = await getTemporaryDirectory();
      final tempFile =
          File('${tempDir.path}${Platform.pathSeparator}$fileName');
      try {
        await tempFile.writeAsString(content, encoding: utf8, flush: true);
        final savedPath = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            sourceFilePath: tempFile.path,
            fileName: fileName,
            mimeTypesFilter: const <String>['text/csv'],
            localOnly: true,
          ),
        );
        if (savedPath == null || savedPath.trim().isEmpty) {
          return const BackupFileSaveResult.cancelled();
        }
        return BackupFileSaveResult.success(savedPath);
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    }

    return const BackupFileSaveResult.unsupported();
  }
}
