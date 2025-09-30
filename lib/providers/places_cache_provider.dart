import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Places Cache Notifier
/// 管理記憶體中的 Place ID 快取（地點名稱 -> Place ID）
class PlacesCacheNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    return {};
  }

  /// 新增或更新快取
  void addPlaceId(String locationName, String placeId) {
    state = {...state, locationName: placeId};
    debugPrint('Cached Place ID for $locationName: $placeId');
  }

  /// 批次新增快取
  void addMultiplePlaceIds(Map<String, String> placeIds) {
    state = {...state, ...placeIds};
    debugPrint('Cached ${placeIds.length} Place IDs');
  }

  /// 取得快取的 Place ID
  String? getPlaceId(String locationName) {
    return state[locationName];
  }

  /// 清除所有快取
  void clearCache() {
    state = {};
    debugPrint('Places cache cleared');
  }

  /// 取得快取統計資訊
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCached': state.length,
      'cachedLocations': state.keys.toList(),
    };
  }
}

/// Places Cache Provider
final placesCacheProvider =
    NotifierProvider<PlacesCacheNotifier, Map<String, String>>(
  PlacesCacheNotifier.new,
);
