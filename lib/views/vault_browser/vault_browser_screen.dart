import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../providers/vault_provider.dart';
import 'note_viewer_screen.dart';

class VaultBrowserScreen extends ConsumerWidget {
  final bool isSelectMode;
  const VaultBrowserScreen({
    super.key,
    this.isSelectMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);
    final vaultNotifier = ref.read(vaultProvider.notifier);
    // final provider = context.watch<VaultProvider>();
    return PopScope(
      canPop: !vaultState.canNavigateBack,
      onPopInvokedWithResult: (bool didPop, result) {
        if (!didPop) {
          vaultNotifier.navigateBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: vaultState.canNavigateBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => vaultNotifier.navigateBack(),
                )
              : null,
          title: Text(
            vaultState.currentPath != null
                ? p.basename(vaultState.currentPath!)
                : isSelectMode ? '選擇模板檔案' : '筆記瀏覽',
          ),
        ),
        body: vaultState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: vaultState.currentFiles.length,
                itemBuilder: (context, index) {
                  final entity = vaultState.currentFiles[index];
                  final isDirectory = entity is Directory;

                  return ListTile(
                    leading: Icon(
                      isDirectory ? Icons.folder : Icons.article_outlined,
                    ),
                    title: Text(p.basename(entity.path)), // 只顯示檔名
                    onTap: () {
                      if (isDirectory) {
                        // 如果是資料夾，呼叫導覽方法
                        vaultNotifier.navigateToDirectory(entity.path);
                      } else if (isSelectMode) {
                        Navigator.of(context).pop(entity.path);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NoteViewerScreen(filePath: entity.path),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
