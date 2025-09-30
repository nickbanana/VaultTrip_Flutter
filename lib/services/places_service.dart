import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Google Places API Service
/// 用於根據地點名稱和座標搜尋 Place ID
class PlacesService {
  final String apiKey;

  PlacesService({required this.apiKey});

  /// 根據地點名稱和座標搜尋 Place ID
  ///
  /// [name] 地點名稱
  /// [lat] 緯度
  /// [lng] 經度
  /// [radius] 搜尋半徑（公尺），預設 100
  ///
  /// 返回 Place ID，如果找不到則返回 null
  Future<String?> searchPlaceId({
    required String name,
    required double lat,
    required double lng,
    int radius = 100,
  }) async {
    try {
      // 使用 Text Search (New) API
      // https://developers.google.com/maps/documentation/places/web-service/text-search
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.location',
        },
        body: jsonEncode({
          'textQuery': name,
          'locationBias': {
            'circle': {
              'center': {
                'latitude': lat,
                'longitude': lng,
              },
              'radius': radius.toDouble(),
            }
          },
          'maxResultCount': 1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['places'] != null && (data['places'] as List).isNotEmpty) {
          final place = data['places'][0];
          final placeId = place['id'] as String?;

          if (placeId != null) {
            debugPrint('Found Place ID for $name: $placeId');
            return placeId;
          }
        }
      } else {
        debugPrint('Places API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error searching place: $e');
    }

    return null;
  }

  /// 批次搜尋多個地點的 Place ID
  ///
  /// [locations] 地點列表，每個地點包含 name, lat, lng
  ///
  /// 返回 Map<地點名稱, Place ID>
  Future<Map<String, String>> batchSearchPlaceIds(
    List<Map<String, dynamic>> locations,
  ) async {
    final results = <String, String>{};

    for (final location in locations) {
      final name = location['景點名稱'] ?? location['name'];
      final lat = _parseDouble(location['緯度'] ?? location['latitude']);
      final lng = _parseDouble(location['經度'] ?? location['longitude']);

      if (name != null && lat != null && lng != null) {
        final placeId = await searchPlaceId(
          name: name,
          lat: lat,
          lng: lng,
        );

        if (placeId != null) {
          results[name] = placeId;
        }

        // 避免過快呼叫 API
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return results;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}