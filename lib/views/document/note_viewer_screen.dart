import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vault_trip/providers/vault_provider.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:path/path.dart' as p;

class NoteViewerScreen extends StatelessWidget {
  const NoteViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VaultProvider>();
    return PopScope(
      onPopInvokedWithResult: (bool didPop, result) {
        if (didPop) {
          print('NoteViewerScreen: Popped, clearing selected note');
          context.read<VaultProvider>().clearSelectedNote();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            provider.selectedNotePath != null
              ? p.basename(provider.selectedNotePath!)
              : '讀取中',
          ),
        ),
        body: Builder(
          builder: (context) {
            if (provider.isNoteLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.selectedNoteContent == null) {
              return const Center(child: Text('沒有內容或讀取失敗'));
            }

            return MarkdownWidget(
              data: provider.selectedNoteContent!,
              padding: EdgeInsets.all(8.0),
            );
          } 
        )
      ),
    );
  }
}
