import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:vault_trip/models/parsed_notes.dart';
import 'package:vault_trip/providers/parsed_notes_provider.dart';
import 'package:vault_trip/views/location/location_detail_screen.dart';

class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsedNotesAsync = ref.watch(parsedNotesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('景點導覽')),
      body: Builder(
        builder: (context) {
          return parsedNotesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            data: (states) {
              if (states.notes.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '沒有找到景點筆記。\n請確保您的筆記符合景點清單模板的結構。',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final locationNotes = states.notes
                  .whereType<LocationNote>()
                  .toList();
              locationNotes.sort(
                (a, b) =>
                    p.basename(a.filePath).compareTo(p.basename(b.filePath)),
              );
              return RefreshIndicator(
                onRefresh: () => ref.read(parsedNotesProvider.notifier).updateNotes(),
                child: ListView.builder(
                  itemCount: locationNotes.length,
                  itemBuilder: (context, index) {
                    final LocationNote note = locationNotes[index];
                    final totalItemCount = note.data.values
                      .whereType<List>()
                      .map((l) => l.length)
                      .fold(0, (a, b) => a + b);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.map, size: 32),
                        title: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('共 $totalItemCount 個景點'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // 點擊後，導航到詳細頁面，並將整個 note 物件傳過去
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LocationDetailScreen(note: note),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
            error: (e, s) => Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('發生錯誤：$e', textAlign: TextAlign.center),
              ),
            ),
          );
        },
      )
    );
  }
}