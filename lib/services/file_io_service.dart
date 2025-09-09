import 'dart:io';

class FileIOService {
  // 判斷路徑是否存在
  Future<bool> isPathExists(String path) async {
    try {
      final isExists = await Directory(path).exists();
      return isExists;
    } catch (e) {
      return false;
    }
  }

  // 判斷檔案是否存在
  Future<bool> isFileExists(String path) async {
    try {
      final isExists = await File(path).exists();
      return isExists;
    } catch (e) {
      return false;
    }
  }
}