import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:vault_trip/models/parsed_notes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vault_trip/views/location/location_item_detail_screen.dart';
import 'package:vault_trip/widgets/map/location_map_widget.dart';

class LocationDetailScreen extends ConsumerWidget {
  final LocationNote note;
  const LocationDetailScreen({super.key, required this.note});

  /// 【全新】輔助函式，從可能是 Markdown 格式的字串中提取出純 URL
  String? _extractUrl(String? rawString) {
    if (rawString == null || rawString.isEmpty) {
      return null;
    }
    // 正規表示式，用於匹配 [Link Text](URL) 格式並捕獲 URL
    final regex = RegExp(r'\[.*\]\((.*?)\)');
    final match = regex.firstMatch(rawString);

    if (match != null && match.groupCount >= 1) {
      // 如果匹配成功，回傳第一個捕獲組 (括號裡的內容)
      return match.group(1);
    }
    
    // 如果不符合 Markdown 格式，但看起來像一個 URL，就直接回傳
    if (rawString.trim().startsWith('http')) {
      return rawString.trim();
    }
    
    // 如果都失敗，回傳 null
    return null;
  }

  Future<void> _launchUrl(BuildContext context, String? urlString) async {
    final cleanUrl = _extractUrl(urlString);
    if (cleanUrl == null || cleanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有提供網址')),
      );
      return;
    }
    final Uri? uri = Uri.tryParse(cleanUrl);

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法開啟網址: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 從 note.data 中取得所有頂層的 keys (也就是 H2 分類標題)
    final categoryKeys = note.data.keys.toList();

    // 收集所有景點項目用於地圖顯示
    final List<Map<String, dynamic>> allItems = [];
    for (var categoryKey in categoryKeys) {
      final categoryValue = note.data[categoryKey];
      if (categoryValue is List) {
        allItems.addAll(categoryValue.cast<Map<String, dynamic>>());
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
      ),
      body: Column(
        children: [
          // 地圖區域 - 固定在頂部
          LocationListMapWidget(
            items: allItems,
            regionName: note.title,
            height: 300,
          ),
          // 可滾動的內容區域
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: categoryKeys.length,
              itemBuilder: (context, index) {
                final categoryKey = categoryKeys[index];
                final categoryValue = note.data[categoryKey];

                // --- 根據 value 的類型，動態決定要渲染的 Widget ---

                // Case 1: 如果 value 是一個 List，代表這是一個包含多個景點項目的分類
                if (categoryValue is List) {
                  final items = categoryValue.cast<Map<String, dynamic>>();

                  // 如果列表是空的，可以選擇不顯示或顯示提示
                  if (items.isEmpty) {
                      return const SizedBox.shrink();
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      key: PageStorageKey(categoryKey), // 幫助記住展開/收合狀態
                      initiallyExpanded: true, // 預設展開
                      title: Text(
                        categoryKey,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      children: items.map((item) {
                        // 從項目 Map 中讀取資料，key 對應模板中的 placeholder
                        final name = item['景點名稱'] ?? '無名稱';
                        final url = item['網址'];
                        final remarks = item['備註'];

                        return ListTile(
                          title: Text(name),
                          subtitle: remarks != null && remarks.isNotEmpty ? Text(remarks) : null,
                          trailing: (_extractUrl(url) != null)
                           ?
                            IconButton(icon: const Icon(Icons.link), selectedIcon: const Icon(Icons.link_outlined),
                              onPressed: () => _launchUrl(context, url),
                              tooltip: '開啟網址',
                            )
                           : null,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LocationItemDetailScreen(itemData: item),
                              ),
                            );
                            // 未來可以在這裡增加點擊後的互動，例如開啟網址或地圖
                          },
                        );
                      }).toList(),
                    ),
                  );
                }

                // Case 2: 如果 value 是 String，代表這是一個單純的文字內容區塊 (例如備註)
                if (categoryValue is String) {

                  // 如果字串是空的，不顯示
                  if (categoryValue.trim().isEmpty) {
                      return const SizedBox.shrink();
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryKey,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const Divider(height: 16),
                          // 直接使用 MarkdownBody 渲染文字內容
                          MarkdownBlock(
                            data: categoryValue,
                            selectable: true,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 如果遇到其他未知的資料類型，就不顯示
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}