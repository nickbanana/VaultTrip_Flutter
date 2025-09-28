import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'settings_provider.dart';

@immutable
class VaultState {
  final bool isLoading;
  final List<String> navigationStack;
  final List<FileSystemEntity> currentFiles;
  String? get currentPath =>
      navigationStack.isNotEmpty ? navigationStack.last : null;
  bool get canNavigateBack => navigationStack.length > 1;
  const VaultState({
    required this.isLoading,
    required this.navigationStack,
    required this.currentFiles,
  });

  factory VaultState.initial() {
    return const VaultState(
      isLoading: false,
      navigationStack: [],
      currentFiles: [],
    );
  }

  VaultState copyWith({
    bool? isLoading,
    List<String>? navigationStack,
    List<FileSystemEntity>? currentFiles,
  }) {
    return VaultState(
      isLoading: isLoading ?? this.isLoading,
      navigationStack: navigationStack ?? this.navigationStack,
      currentFiles: currentFiles ?? this.currentFiles,
    );
  }
}

class VaultNotifier extends Notifier<VaultState> {
  @override
  VaultState build() {
    final settings = ref.watch(settingsProvider);
    return settings.when(
      data: (settings) {
        final vaultPath = settings.vaultPath;
        if (vaultPath != null && vaultPath.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {  
            _updateFileList();  
          });
          return VaultState.initial().copyWith(navigationStack: [vaultPath]);
        }
        return VaultState.initial();
      },
      loading: () => VaultState.initial().copyWith(isLoading: true),
      error: (e, s) => VaultState.initial().copyWith(isLoading: false),
    );
  }

  Future<void> navigateToDirectory(String directoryPath) async {
    if (await FileSystemEntity.isDirectory(directoryPath)) {
      final newStack = List<String>.from(state.navigationStack)
        ..add(directoryPath);
      state = state.copyWith(navigationStack: newStack);
      await _updateFileList();
    }
  }

  Future<void> navigateBack() async {
    if (state.canNavigateBack) {
      final newStack = List<String>.from(state.navigationStack)..removeLast();
      state = state.copyWith(navigationStack: newStack);
      await _updateFileList();
    }
  }

  Future<void> _updateFileList() async {
    if (state.currentPath == null) return;

    state = state.copyWith(isLoading: true);
    List<FileSystemEntity> files = [];
    try {
      final directory = Directory(state.currentPath!);
      if (await directory.exists()) {
        final allEntities = await directory.list().toList();
        files = allEntities.where((entity) {
          if (p.basename(entity.path).startsWith('.')) return false;
          return entity is Directory || entity.path.endsWith('.md');
        }).toList();

        files.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
          return p
              .basename(a.path)
              .toLowerCase()
              .compareTo(p.basename(b.path).toLowerCase());
        });
      }
    } catch (e) {
      print('Error updating file list: $e');
      // 可以考慮在這裡設定一個錯誤狀態
    }
    state = state.copyWith(isLoading: false, currentFiles: files);
  }
}

final vaultProvider = NotifierProvider<VaultNotifier, VaultState>(
  VaultNotifier.new,
);
