import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_trip/models/parsed_notes.dart';
import 'package:vault_trip/models/parsing_models.dart';
import 'package:vault_trip/providers/all_vault_files_provider.dart';
import 'package:vault_trip/providers/settings_provider.dart';
import 'package:vault_trip/providers/template_provider.dart';
import 'package:vault_trip/services/markdown_parser_service.dart';

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
    return ParsedNotesState(isLoading: false, notes: parsedNotes);
  }

  Future<void> updateNotes() async {
    ref.invalidateSelf();
    await future;
  }
}

final parsedNotesProvider = AsyncNotifierProvider<ParsedNotesNotifier, ParsedNotesState>(ParsedNotesNotifier.new);