import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/parsed_notes.dart';
import '../../providers/itinerary_provider.dart';
import 'itinerary_detail_screen.dart';

class ItineraryListScreen extends ConsumerWidget {
  const ItineraryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryState = ref.watch(itineraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('行程導覽')),
      body: Builder(
        builder: (context) {
          if (itineraryState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (itineraryState.notes.isEmpty) {
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

          // 如果有筆記，就用 ListView 顯示
          return ListView.builder(
            itemCount: itineraryState.notes.length,
            itemBuilder: (context, index) {
              final ItineraryNote note = itineraryState.notes[index];
              // 嘗試從 data Map 中獲取行程概要
              final summary = note.data['📋 行程概要'];
              final dayCount = (summary is List) ? summary.length : 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.flight_takeoff, size: 32),
                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 呼叫 Notifier 的方法來觸發掃描和解析
          ref.read(itineraryProvider.notifier).loadAll();
        },
        icon: const Icon(Icons.refresh),
        label: const Text('掃描 Vault'),
      ),
    );
  }
}