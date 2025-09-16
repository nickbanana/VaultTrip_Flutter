import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart'; // 需要 vaultPath

/// 遞迴地掃描 Vault 路徑，並回傳一份包含所有 File 物件的平面化列表
final allVaultFilesProvider = FutureProvider<List<File>>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final vaultPath = settings.vaultPath;
  // 如果 vaultPath 尚未設定，回傳空列表
  if (vaultPath == null || vaultPath.isEmpty) {
    return [];
  }

  final List<File> allFiles = [];
  final rootDir = Directory(vaultPath);

  if (!await rootDir.exists()) {
    return [];
  }
  
  // 使用 Dart 的遞迴列表功能
  final Stream<FileSystemEntity> entities = rootDir.list(recursive: true, followLinks: false);
  
  await for (final entity in entities) {
    // 我們只關心檔案，並且過濾掉隱藏檔案/資料夾中的內容
    if (entity is File && !entity.path.contains('/.')) {
      allFiles.add(entity);
    }
  }
  
  return allFiles;
});