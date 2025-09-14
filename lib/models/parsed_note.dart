abstract class ParsedNote {
  final String filePath;
  final String title;
  final String rawContent;

  ParsedNote({
    required this.filePath,
    required this.title,
    required this.rawContent,
  });
}

/// 代表一個完整的行程筆記檔案
class ItineraryNote extends ParsedNote {
  final List<ItineraryDay> days;

  ItineraryNote({
    required super.filePath,
    required super.title,
    required super.rawContent,
    required this.days,
  });
}

/// 代表行程中的一天
class ItineraryDay {
  final String dayTitle;
  final DateTime? date;
  final List<String> events;

  ItineraryDay({required this.dayTitle, this.date, required this.events});
}

// ============ 景點 Models ============

/// 代表一個完整的景點筆記檔案 (e.g., "大阪景點.md")
class LocationNote extends ParsedNote {
  final List<LocationCategory> categories; // 一個景點筆記包含多個「分類」
  LocationNote({
    required super.filePath,
    required super.title,
    required super.rawContent,
    this.categories = const [],
  });
}

/// 代表景點中的一個分類 (e.g., "## 餐廳")
class LocationCategory {
  final String name; // 例如 "餐廳"
  final List<LocationItem> items; // 一個分類包含多個「項目」
  LocationCategory({required this.name, this.items = const []});
}

/// 代表一個景點項目 (e.g., "### 一蘭拉麵")
class LocationItem {
  final String name; // 例如 "一蘭拉麵 道頓堀店"
  String? url;
  String? coordinates;
  String? remarks;
  LocationItem({required this.name, this.url, this.coordinates, this.remarks});
}

/// ============ 其他通用筆記 Model ============
class GenericNote extends ParsedNote {
  GenericNote({
    required super.filePath,
    required super.title,
    required super.rawContent,
  });
}
