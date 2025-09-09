import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';


class VaultProvider with ChangeNotifier {
  // -- 狀態 --
  String? _vaultPath;
  String? get vaultPath => _vaultPath;

  // -- 導覽堆疊 --
  final List<String> _navigationStack = [];
  // 取得目前的路徑
  String? get currentPath => _navigationStack.isNotEmpty ? _navigationStack.last : null;

  bool get canNavigateBack => _navigationStack.length > 1;

  List<FileSystemEntity> _currentFiles = [];
  List<FileSystemEntity> get currentFiles => _currentFiles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Key for storing the vault path in shared preferences
  static const String _vaultPathKey = 'vault_path';

  VaultProvider() {
    loadVaultPath();
  }

  // -- 路徑管理 --
  // 載入儲存的路徑
  Future<void> loadVaultPath() async {
    _setLoading(true);
    final prefs = SharedPreferencesAsync();
    final savedPath = await prefs.getString(_vaultPathKey);
    if (savedPath != null && await Directory(savedPath).exists()) {
      _vaultPath = savedPath;
      initializeStackWithPath(_vaultPath!);
      await _updateFileList();
    }
    _setLoading(false);
  }

  // 讓使用者選擇資料夾
  Future<void> selectAndSaveVaultPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '選擇資料夾',
      lockParentWindow: true,
    );

    if (selectedDirectory != null) {
      _vaultPath = selectedDirectory;
      final prefs = SharedPreferencesAsync();
      await prefs.setString(_vaultPathKey, _vaultPath!);
      initializeStackWithPath(_vaultPath!);
      await _updateFileList();
    }
  }

  // -- 瀏覽邏輯 --
  Future<void> navigateToDirectory(String path) async {
    if (await FileSystemEntity.isDirectory(path)) {
      _navigationStack.add(path);
      await _updateFileList();
    }
  }

  // 向上瀏覽
  Future<void> navigateBack() async {
    if (canNavigateBack) {
      _navigationStack.removeLast();
      await _updateFileList();
    }
  }

  // 清除儲存的路徑
  Future<void> clearVaultPath() async {
    _vaultPath = null;
    _currentFiles = [];
    final prefs = SharedPreferencesAsync();
    await prefs.remove(_vaultPathKey);
    notifyListeners();
  }
  // 列出檔案
  Future<void> _updateFileList() async {
    if (currentPath == null) return;
    _setLoading(true);
    final directory = Directory(currentPath!);
    if (await directory.exists()) {
      final allEntities = await directory.list().toList();
      print('--- Debug: Raw entities found in $currentPath ---');
      if (allEntities.isEmpty) {
        print('Warning: The directory is empty or could not be read.');
      } else {
        for (var entity in allEntities) {
          print('Found: ${entity.path}, isDirectory: ${entity is Directory}');
        }
      }
      // 你可以在這裡做排序或過濾，例如只顯示 .md 檔案和資料夾
      // show only .md files and folders
      _currentFiles = allEntities.where((entity) {
        if (p.basename(entity.path).startsWith('.')) {
          return false;
        }
        return entity is Directory || entity.path.endsWith('.md');
      }).toList();
      _currentFiles.sort((a, b) {
          // 簡單排序：資料夾在前，檔案在後
          bool aIsDir = a is Directory;
          bool bIsDir = b is Directory;
          if (aIsDir != bIsDir) {
              return aIsDir ? -1 : 1;
          }
          return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
      });
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void initializeStackWithPath(String path) {
    _navigationStack.clear();
    _navigationStack.add(path);
  }

}