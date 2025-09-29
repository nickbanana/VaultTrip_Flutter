import 'package:flutter/material.dart';
import 'package:markdown_widget/widget/all.dart';

class LocationItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> itemData;
  const LocationItemDetailScreen({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
    final name = itemData['景點名稱'] ?? '無名稱';
    // 取得所有 key 來動態顯示
    final keys = itemData.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: keys.map((key) {
          final value = itemData[key];
          if (value == null || value.toString().trim().isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                // 這裡我們也用 MarkdownBody 來渲染，以便未來支援連結等
                MarkdownBlock(
                  data: value.toString(),
                  selectable: true,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}