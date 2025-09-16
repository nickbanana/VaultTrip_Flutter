import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../../models/parsed_notes.dart';

/// 顯示單一、已解析的行程筆記的詳細內容
class ItineraryDetailScreen extends StatelessWidget {
  final ItineraryNote note;
  const ItineraryDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    // 從 note.data 中取得所有頂層的 keys (e.g., "📋 行程概要", "✈️ 航班資訊")
    final topLevelKeys = note.data.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: topLevelKeys.length,
        itemBuilder: (context, index) {
          final key = topLevelKeys[index];
          final value = note.data[key];

          // 根據 value 的類型，動態決定如何渲染
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 區塊標題 (H2)
                  Text(
                    key,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(height: 24),
                  
                  // --- 動態渲染區塊內容 ---
                  _buildSectionContent(value),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 根據 value 的類型 (List 或 String) 回傳對應的 Widget
  Widget _buildSectionContent(dynamic value) {
    // Case 1: value 是一個「行程單日」項目列表
    if (value is List) {
      final items = value.cast<Map<String, dynamic>>();
      if (items.isEmpty) {
        return const Text('此區塊沒有內容。', style: TextStyle(color: Colors.grey));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          final dateStr = "### 📆 ${item['月'] ?? '?'}/${item['日'] ?? '?'}（${item['星期幾'] ?? ''}）";
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            // 使用 Markdown 來渲染 H3 標題，保持樣式一致
            child: MarkdownBlock(data: dateStr, config: MarkdownConfig(
              configs: [
                H3Config(style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ]
            ))
          );
        }).toList(),
      );
    }

    // Case 2: value 是一個單純的 Markdown 字串區塊
    if (value is String && value.trim().isNotEmpty) {
      return MarkdownBlock(data: value);
    }
    
    // 如果區塊是空的或類型未知
    return const Text('此區塊沒有內容。', style: TextStyle(color: Colors.grey));
  }
}
