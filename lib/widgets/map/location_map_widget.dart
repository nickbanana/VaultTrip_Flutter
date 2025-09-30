import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// 單一景點地圖 Widget
class LocationItemMapWidget extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final double height;

  const LocationItemMapWidget({
    super.key,
    required this.itemData,
    this.height = 250,
  });

  @override
  State<LocationItemMapWidget> createState() => _LocationItemMapWidgetState();
}

class _LocationItemMapWidgetState extends State<LocationItemMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _coordinates;

  @override
  void initState() {
    super.initState();
    _extractCoordinates();
  }

  /// 從 itemData 中提取經緯度
  /// 支援的格式:
  /// 1. 分開的欄位: '經度' 和 '緯度'
  /// 2. 組合欄位: '座標' 格式 "lat,lng" 或 "緯度,經度"
  /// 3. Google Maps 連結
  void _extractCoordinates() {
    // 方式 1: 直接的經緯度欄位
    final lat = _parseDouble(widget.itemData['緯度'] ?? widget.itemData['latitude']);
    final lng = _parseDouble(widget.itemData['經度'] ?? widget.itemData['longitude']);

    if (lat != null && lng != null) {
      _coordinates = LatLng(lat, lng);
      return;
    }

    // 方式 2: 組合座標欄位
    final coordString = widget.itemData['座標'] ?? widget.itemData['coordinates'];
    if (coordString != null && coordString.toString().contains(',')) {
      final parts = coordString.toString().split(',');
      if (parts.length == 2) {
        final parsedLat = _parseDouble(parts[0].trim());
        final parsedLng = _parseDouble(parts[1].trim());
        if (parsedLat != null && parsedLng != null) {
          _coordinates = LatLng(parsedLat, parsedLng);
          return;
        }
      }
    }

    // 方式 3: 從 Google Maps URL 提取
    final url = widget.itemData['網址'] ?? widget.itemData['url'];
    if (url != null) {
      final coords = _extractCoordinatesFromUrl(url.toString());
      if (coords != null) {
        _coordinates = coords;
        return;
      }
    }
  }

  /// 從 Google Maps URL 提取座標
  /// 支援格式: https://maps.google.com/?q=25.0330,121.5654
  LatLng? _extractCoordinatesFromUrl(String url) {
    final regex = RegExp(r'[?&]q=(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final match = regex.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// 在 Google Maps App 中開啟
  Future<void> _openInGoogleMaps() async {
    if (_coordinates == null) return;

    final name = widget.itemData['景點名稱'] ?? widget.itemData['name'] ?? '';
    final lat = _coordinates!.latitude;
    final lng = _coordinates!.longitude;

    // 使用 geo: URI scheme (Universal Link)
    final Uri mapsUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: 使用 https 連結
      final Uri webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // Dark mode map style
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#6b9a76"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca5b3"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2835"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f3d19c"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#515c6d"}]},
  {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#17263c"}]}
]
''';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_coordinates == null) {
      return SizedBox(
        height: widget.height,
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('無地圖資料', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    final name = widget.itemData['景點名稱'] ?? widget.itemData['name'] ?? '景點位置';

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _coordinates!,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: MarkerId(name),
                position: _coordinates!,
                infoWindow: InfoWindow(title: name),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  isDarkMode ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
                ),
              ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
              if (isDarkMode) {
                controller.setMapStyle(_darkMapStyle);
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // 右上角按鈕：在 Google Maps 中開啟
          Positioned(
            top: 10,
            right: 10,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _openInGoogleMaps,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '開啟地圖',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

/// 多個景點地圖 Widget (用於 LocationDetailScreen)
class LocationListMapWidget extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String regionName;
  final double height;

  const LocationListMapWidget({
    super.key,
    required this.items,
    required this.regionName,
    this.height = 300,
  });

  @override
  State<LocationListMapWidget> createState() => _LocationListMapWidgetState();
}

class _LocationListMapWidgetState extends State<LocationListMapWidget> {
  GoogleMapController? _mapController;
  final List<Marker> _markers = [];
  LatLng? _centerPosition;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers({bool isDarkMode = false}) {
    final List<LatLng> positions = [];
    _markers.clear();

    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final coords = _extractCoordinates(item);

      if (coords != null) {
        positions.add(coords);
        final name = item['景點名稱'] ?? item['name'] ?? '景點 ${i + 1}';

        _markers.add(
          Marker(
            markerId: MarkerId('marker_$i'),
            position: coords,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isDarkMode ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    // 計算中心點
    if (positions.isNotEmpty) {
      double totalLat = 0;
      double totalLng = 0;
      for (var pos in positions) {
        totalLat += pos.latitude;
        totalLng += pos.longitude;
      }
      _centerPosition = LatLng(
        totalLat / positions.length,
        totalLng / positions.length,
      );
    }
  }

  LatLng? _extractCoordinates(Map<String, dynamic> itemData) {
    // 方式 1: 直接的經緯度欄位
    final lat = _parseDouble(itemData['緯度'] ?? itemData['latitude']);
    final lng = _parseDouble(itemData['經度'] ?? itemData['longitude']);

    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }

    // 方式 2: 組合座標欄位
    final coordString = itemData['座標'] ?? itemData['coordinates'];
    if (coordString != null && coordString.toString().contains(',')) {
      final parts = coordString.toString().split(',');
      if (parts.length == 2) {
        final parsedLat = _parseDouble(parts[0].trim());
        final parsedLng = _parseDouble(parts[1].trim());
        if (parsedLat != null && parsedLng != null) {
          return LatLng(parsedLat, parsedLng);
        }
      }
    }

    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _openInGoogleMaps() async {
    if (_centerPosition == null) return;

    final lat = _centerPosition!.latitude;
    final lng = _centerPosition!.longitude;

    // 搜尋這個區域
    final Uri mapsUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${widget.regionName})');

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  // Dark mode map style
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
  {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#6b9a76"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca5b3"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2835"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f3d19c"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
  {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#515c6d"}]},
  {"featureType": "water", "elementType": "labels.text.stroke", "stylers": [{"color": "#17263c"}]}
]
''';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Rebuild markers with correct color for current theme
    if (_markers.isNotEmpty) {
      _buildMarkers(isDarkMode: isDarkMode);
    }

    if (_markers.isEmpty || _centerPosition == null) {
      return SizedBox(
        height: widget.height,
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('此區域無地圖資料', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _centerPosition!,
              zoom: 12,
            ),
            markers: _markers.toSet(),
            onMapCreated: (controller) {
              _mapController = controller;
              if (isDarkMode) {
                controller.setMapStyle(_darkMapStyle);
              }
              // 自動調整視角以顯示所有標記
              if (_markers.length > 1) {
                _fitAllMarkers();
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // 右上角：景點數量和開啟按鈕
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_markers.length} 個景點',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _openInGoogleMaps,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, size: 20, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '開啟地圖',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _fitAllMarkers() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (var marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}