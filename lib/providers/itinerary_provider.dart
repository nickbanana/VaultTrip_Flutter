import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_trip/models/parsing_models.dart';
import 'package:vault_trip/providers/settings_provider.dart';
import '../models/parsed_notes.dart';
import '../services/markdown_parser_service.dart';
import 'template_provider.dart';
import 'all_vault_files_provider.dart';
import 'package:path/path.dart' as p;

// 狀態：載入中 + 筆記列表
class ItineraryState {
  final bool isLoading;
  final List<ItineraryNote> notes;
  const ItineraryState({this.isLoading = true, this.notes = const []});
}

Future<List<ItineraryNote>> _parseItinerariesInIsolate(Map<String, dynamic> args) async {
  // 在 Isolate 中，我們無法使用 ref，所以需要把所有依賴都作為參數傳進來
  final service = MarkdownParserService(); // 在 Isolate 中建立新的實例
  final allFiles = args['allFiles'] as List<File>;
  final allBlueprints = args['allBlueprints'] as Map<String, TemplateBlueprint>;
  final templateRelativePaths = args['templateRelativePaths'] as Set<String>;
  final itineraryBlueprint = allBlueprints['行程模板'];

  if (itineraryBlueprint == null) return [];

  final List<ItineraryNote> foundNotes = [];
  for (final file in allFiles.where((f) => f.path.endsWith('.md'))) {
    final relativePath = file.path.replaceFirst('${args['vaultPath']}/', '');
    if (templateRelativePaths.contains(relativePath)) {
      continue; // 跳過此模板檔案
    }
    final content = await file.readAsString();
    final isItinerary = itineraryBlueprint.rules.any((rule) => content.contains('## ${rule.key}')) && itineraryBlueprint.fingerprintRegex!.hasMatch(content);
    
    if (isItinerary) {
      final title = file.path.split('/').last.replaceAll('.md', '');
      final data = service.parseNote(
        noteContent: content,
        blueprint: itineraryBlueprint,
        allBlueprints: allBlueprints,
      );
      foundNotes.add(ItineraryNote(filePath: file.path, title: title, data: data));
    }
  }
  foundNotes.sort((a, b) => p.basename(a.filePath).compareTo(p.basename(b.filePath)));
  return foundNotes;
}

class ItineraryNotifier extends Notifier<ItineraryState> {
  @override
  ItineraryState build() => const ItineraryState();
  Future<void> loadAll() async {
    state = const ItineraryState(isLoading: true, notes: []);
    final allFiles = await ref.read(allVaultFilesProvider.future);
    final allBlueprints = await ref.read(templateProvider.future);
    final settings = await ref.read(settingsProvider.future);
    final vaultPath = settings.vaultPath;
    if (vaultPath == null) {
      state = const ItineraryState(isLoading: false);
      return;
    }
    final templateRelativePaths = [
      settings.itineraryTemplatePath,
      settings.itineraryDayTemplatePath,
      settings.locationListTemplatePath,
      settings.locationItemTemplatePath,
    ].whereType<String>().toSet(); // 使用 Set 以提高查找效率

    final foundNotes = await compute(_parseItinerariesInIsolate, {
      'allFiles': allFiles,
      'allBlueprints': allBlueprints,
      'templateRelativePaths': templateRelativePaths,
      'vaultPath': vaultPath,
    });
    state = ItineraryState(isLoading: false, notes: foundNotes);
  }
}
/// @deprecated
final itineraryProvider = NotifierProvider<ItineraryNotifier, ItineraryState>(
  ItineraryNotifier.new,
);
