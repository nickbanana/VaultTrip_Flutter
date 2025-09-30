import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_trip/providers/note_provider.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:path/path.dart' as p;

class NoteViewerScreen extends ConsumerWidget {
  final String filePath;
  const NoteViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContent = ref.watch(noteContentProvider(filePath));
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(filePath)),
      ),
      body: asyncContent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('讀取檔案失敗:\n$error'),
          )
        ),
        data: (content) => MarkdownWidget(data: content, padding: EdgeInsets.all(8.0), selectable: true,),
      ),
    );
  }
}
