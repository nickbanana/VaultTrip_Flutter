import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:vault_trip/providers/vault_provider.dart';
import 'package:vault_trip/views/document/note_viewer_screen.dart';

class DocumentWidget extends StatelessWidget {
  const DocumentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VaultProvider>();
    return PopScope(
      canPop: !provider.canNavigateBack,
      onPopInvokedWithResult: (bool didPop, result) {
        if (!didPop) {
          provider.navigateBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: provider.canNavigateBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => provider.navigateBack(),
                )
              : null,
          title: Text(
            provider.currentPath != null
                ? p.basename(provider.currentPath!)
                : '筆記瀏覽',
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: provider.currentFiles.length,
                itemBuilder: (context, index) {
                  final entity = provider.currentFiles[index];
                  final isDirectory = entity is Directory;

                  return ListTile(
                    leading: Icon(
                      isDirectory ? Icons.folder : Icons.article_outlined,
                    ),
                    title: Text(p.basename(entity.path)), // 只顯示檔名
                    onTap: () {
                      if (isDirectory) {
                        // 如果是資料夾，呼叫導覽方法
                        provider.navigateToDirectory(entity.path);
                      } else {
                        context.read<VaultProvider>().loadNoteContent(
                          entity.path,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NoteViewerScreen(),
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
