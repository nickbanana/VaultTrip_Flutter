import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// noteContentProvider
/// - `FutureProvider`: 因為讀取檔案是一個非同步操作。
/// - `.family<String, String>`:
///   - 第一個 `String`: 代表 Provider 成功時回傳的資料類型 (檔案內容)。
///   - 第二個 `String`: 代表傳入的參數類型 (檔案路徑)。
final noteContentProvider = FutureProvider.family<String, String>((ref, filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      throw Exception('File not found.');
    }
  } catch (e) {
    // 向上拋出錯誤，讓 UI 層的 .when() 可以捕捉到
    rethrow;
  }
});