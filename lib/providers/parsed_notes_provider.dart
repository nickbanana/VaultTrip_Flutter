import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_trip/models/parsed_notes.dart';
import 'package:vault_trip/models/parsing_models.dart';
import 'package:vault_trip/providers/all_vault_files_provider.dart';
import 'package:vault_trip/providers/settings_provider.dart';
import 'package:vault_trip/providers/template_provider.dart';
import 'package:vault_trip/services/markdown_parser_service.dart';
import 'package:vault_trip/providers/places_service_provider.dart';
import 'package:vault_trip/providers/places_cache_provider.dart';

class ParsedNotesState {
  final bool isLoading;
  final List<ParsedNote> notes;
  const ParsedNotesState({this.isLoading = true, this.notes = const []});

  ParsedNotesState copyWith({
    bool? isLoading,
    List<ParsedNote>? notes,
  }) {
    return ParsedNotesState(
      isLoading: isLoading ?? this.isLoading,
      notes: notes ?? this.notes,
    );
  }
}

Future<List<ParsedNote>> parseAllNotesInIsolate(
  Map<String, dynamic> args,
) async {
  final service = MarkdownParserService(); // 在 Isolate 中建立新的實例
  final allFiles = args['allFiles'] as List<File>;
  final allBlueprints = args['allBlueprints'] as Map<String, TemplateBlueprint>;
  final templateRelativePaths = args['templateRelativePaths'] as Set<String>;
  final vaultPath = args['vaultPath'] as String;
  final List<ParsedNote> parsedNotes = [];
  for (final file in allFiles.where((f) => f.path.endsWith('.md'))) {
    final relativePath = file.path.replaceFirst('$vaultPath/', '');
    if (templateRelativePaths.contains(relativePath)) {
      continue; // 跳過此模板檔案
    }
    final note = await service.parseFile(file.path, allBlueprints);
    parsedNotes.add(note);
  }
  return parsedNotes;
}

class ParsedNotesNotifier extends AsyncNotifier<ParsedNotesState> {
  @override
  Future<ParsedNotesState> build() async {
    final allFiles = await ref.read(allVaultFilesProvider.future);
    final allBlueprints = await ref.read(templateProvider.future);
    final settings = await ref.read(settingsProvider.future);
    final vaultPath = settings.vaultPath;
    if (vaultPath == null) {
      return ParsedNotesState(isLoading: false, notes: []);
    }
    final templateRelativePaths = [
      settings.itineraryTemplatePath,
      settings.itineraryDayTemplatePath,
      settings.locationListTemplatePath,
      settings.locationItemTemplatePath,
    ].whereType<String>().toSet(); // 使用 Set 以提高查找效率
    final parsedNotes = await compute(parseAllNotesInIsolate, {
      'allFiles': allFiles,
      'allBlueprints': allBlueprints,
      'templateRelativePaths': templateRelativePaths,
      'vaultPath': vaultPath,
    });

    // 解析完成後，搜尋並快取所有景點的 Place ID
    await _fetchAndCachePlaceIds(parsedNotes);

    return ParsedNotesState(isLoading: false, notes: parsedNotes);
  }

  Future<void> updateNotes() async {
    ref.invalidateSelf();
    await future;
  }

  /// 從所有 LocationNote 中提取景點資料，並呼叫 Places API 快取 Place ID
  Future<void> _fetchAndCachePlaceIds(List<ParsedNote> parsedNotes) async {
    final placesService = ref.read(placesServiceProvider);
    if (placesService == null) {
      debugPrint('PlacesService not available, skipping Place ID caching');
      return;
    }

    final cacheNotifier = ref.read(placesCacheProvider.notifier);

    // 收集所有景點資料
    final List<Map<String, dynamic>> locations = [];
    for (final note in parsedNotes) {
      if (note is LocationNote) {
        // 從 LocationNote 的 data 中提取景點列表
        for (final entry in note.data.entries) {
          final value = entry.value;
          if (value is List) {
            // 這是一個景點列表
            for (final item in value) {
              if (item is Map<String, dynamic>) {
                // 檢查是否包含必要的欄位
                if (item.containsKey('景點名稱') &&
                    item.containsKey('緯度') &&
                    item.containsKey('經度')) {
                  locations.add(item);
                }
              }
            }
          }
        }
      }
    }

    if (locations.isEmpty) {
      debugPrint('No locations found for Place ID caching');
      return;
    }

    debugPrint('Found ${locations.length} locations, fetching Place IDs...');

    // 批次搜尋 Place ID
    final placeIds = await placesService.batchSearchPlaceIds(locations);

    // 儲存到快取
    if (placeIds.isNotEmpty) {
      cacheNotifier.addMultiplePlaceIds(placeIds);
      debugPrint('Successfully cached ${placeIds.length} Place IDs');
    }
  }
}

final parsedNotesProvider = AsyncNotifierProvider<ParsedNotesNotifier, ParsedNotesState>(ParsedNotesNotifier.new);