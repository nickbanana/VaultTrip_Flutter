import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_trip/providers/parsed_notes_provider.dart';
import 'package:path/path.dart' as p;
import '../../models/parsed_notes.dart';
import 'itinerary_detail_screen.dart';

class ItineraryListScreen extends ConsumerWidget {
  const ItineraryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsedNotesAsync = ref.watch(parsedNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('行程導覽'),
      ),
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
                      '沒有找到行程筆記。\n請確保您的筆記符合行程模板的結構。',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final itineraryNotes = states.notes
                  .whereType<ItineraryNote>()
                  .toList();
              itineraryNotes.sort(
                (a, b) =>
                    p.basename(a.filePath).compareTo(p.basename(b.filePath)),
              );
              return RefreshIndicator(
                onRefresh: () => ref.read(parsedNotesProvider.notifier).updateNotes(),
                child: ListView.builder(
                  itemCount: itineraryNotes.length,
                  itemBuilder: (context, index) {
                    final ItineraryNote note = itineraryNotes[index];
                    // 嘗試從 data Map 中獲取行程概要（唯一其data.values 是一個 List）
                    final summaryList = note.data.values.firstWhere(
                      (value) => value is List,
                      orElse: () => [], // 如果沒找到，回傳一個空列表以避免錯誤
                    );
                    final dayCount = (summaryList as List).length;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const Icon(Icons.flight_takeoff, size: 24),
                        title: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('共 $dayCount 天行程'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // 點擊後，導航到詳細頁面，並將整個 note 物件傳過去
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ItineraryDetailScreen(note: note),
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
      ),
    );
  }
}
