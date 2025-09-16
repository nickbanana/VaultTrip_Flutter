import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/parsing_models.dart';
import '../services/markdown_parser_service.dart';
import 'settings_provider.dart';

final templateProvider = FutureProvider<Map<String, TemplateBlueprint>>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final vaultPath = settings.vaultPath;
  final service = ref.read(markdownServiceProvider);

  // 如果 Vault 或任何模板路徑未設定，則無法繼續
  if (vaultPath == null ||
      settings.itineraryTemplatePath == null ||
      settings.itineraryDayTemplatePath == null ||
      settings.locationListTemplatePath == null ||
      settings.locationItemTemplatePath == null) {
    // 回傳空的藍圖，讓其他 provider 知道模板尚未就緒
    return {};
  }

  // 非同步地讀取所有模板檔案的內容
  Future<String> readFileContent(String relativePath) async {
    final fullPath = p.join(vaultPath, relativePath);
    return await File(fullPath).readAsString();
  }

  final contents = await Future.wait([
    readFileContent(settings.itineraryTemplatePath!),
    readFileContent(settings.itineraryDayTemplatePath!),
    readFileContent(settings.locationListTemplatePath!),
    readFileContent(settings.locationItemTemplatePath!),
  ]);

  // 呼叫 service 來分析內容並生成藍圖
  return service.analyzeTemplates(
    itineraryTplContent: contents[0],
    itineraryDayTplContent: contents[1],
    locationListTplContent: contents[2],
    locationItemTplContent: contents[3],
  );
});