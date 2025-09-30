import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/places_service.dart';
import '../services/config_service.dart';

/// API Key Provider
/// 從 native 端讀取 Google Maps API 金鑰
final apiKeyProvider = FutureProvider<String?>((ref) async {
  return await ConfigService.getGoogleMapsApiKey();
});

/// Places Service Provider
/// 提供 PlacesService 實例，會從 native 端讀取 API 金鑰
final placesServiceProvider = Provider<PlacesService?>((ref) {
  final apiKeyAsync = ref.watch(apiKeyProvider);

  return apiKeyAsync.when(
    data: (apiKey) {
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return PlacesService(apiKey: apiKey);
    },
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});