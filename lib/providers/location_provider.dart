import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_trip/providers/all_vault_files_provider.dart';
import 'package:vault_trip/providers/settings_provider.dart';
import '../models/parsed_notes.dart';
import '../services/markdown_parser_service.dart';
import 'template_provider.dart';

// 狀態：載入中 + 筆記列表
class LocationState {
  final bool isLoading;
  final List<LocationNote> notes;
  const LocationState({this.isLoading = true, this.notes = const []});
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  Future<void> loadAll() async {
    state = const LocationState(isLoading: true, notes: []);
    
    final service = ref.read(markdownServiceProvider);
    final allBlueprints = await ref.read(templateProvider.future);
    final vaultFiles = await ref.read(allVaultFilesProvider.future);
    final settings = await ref.read(settingsProvider.future);
    final vaultPath = settings.vaultPath;

    if (vaultPath == null) {
      state = const LocationState(isLoading: false);
      return;
    }

    final templateRelativePaths = [
      settings.itineraryTemplatePath,
      settings.itineraryDayTemplatePath,
      settings.locationListTemplatePath,
      settings.locationItemTemplatePath,
    ].whereType<String>().toSet(); // 使用 Set 以提高查找效率

    final poiBlueprint = allBlueprints['景點清單模板'];
    if (poiBlueprint == null) {
      state = const LocationState(isLoading: false, notes: []);
      return;
    }

    final List<LocationNote> foundNotes = [];
    for (final entity in vaultFiles) {
      if (entity.path.endsWith('.md')) {
        final relativePath = entity.path.replaceFirst('$vaultPath/', '');
        if (templateRelativePaths.contains(relativePath)) {
          continue; // 跳過此模板檔案
        }
        final content = await entity.readAsString();
        final isPoi = poiBlueprint.rules.any((rule) => content.contains('## ${rule.key}'));
        
        if (isPoi) {
          final title = entity.path.split('/').last.replaceAll('.md', '');
          final data = service.parseNote(
            noteContent: content,
            blueprint: poiBlueprint,
            allBlueprints: allBlueprints,
          );
          foundNotes.add(LocationNote(filePath: entity.path, title: title, data: data));
        }
      }
    }
    state = LocationState(isLoading: false, notes: foundNotes);
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
