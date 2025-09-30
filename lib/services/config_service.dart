import 'package:flutter/services.dart';

/// Config Service
/// 用於從 native 端讀取配置資訊（如 API Keys）
class ConfigService {
  static const platform = MethodChannel('com.example.vault_trip/config');

  /// 從 Android Manifest 讀取 Google Maps API Key
  static Future<String?> getGoogleMapsApiKey() async {
    try {
      final String? apiKey = await platform.invokeMethod('getGoogleMapsApiKey');
      return apiKey;
    } on PlatformException catch (e) {
      print("Failed to get API Key: '${e.message}'.");
      return null;
    }
  }
}
