import 'package:flutter/foundation.dart';

/// 所有已解析筆記的基礎抽象類別
@immutable
abstract class ParsedNote {
  final String filePath;
  final String title;
  ParsedNote({required this.filePath, required this.title});
}

/// 代表一個已解析的「行程筆記」
/// 它的結構由對應的行程模板決定
@immutable
class ItineraryNote extends ParsedNote {
  // 直接儲存解析器產出的 Map
  final Map<String, dynamic> data;
  final String type = 'itinerary';
  ItineraryNote({
    required super.filePath,
    required super.title,
    required this.data,
  });
}

/// 代表一個已解析的「景點筆記」
/// 它的結構由對應的景點清單模板決定
@immutable
class LocationNote extends ParsedNote {
  // 直接儲存解析器產出的 Map
  final Map<String, dynamic> data;
  final String type = 'location';
  LocationNote({
    required super.filePath,
    required super.title,
    required this.data,
  });
}

/// 代表不符合任何模板的通用筆記
@immutable
class GenericNote extends ParsedNote {
    final String rawContent;
    final String type = 'generic';
    GenericNote({required super.filePath, required super.title, required this.rawContent});
}