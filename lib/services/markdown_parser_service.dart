import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_trip/models/parsed_notes.dart';
import '../models/parsing_models.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class MarkdownParserService {
  // TODO: 目前寫死，但未來可以在設定調整
  static const String itineraryDayTemplatePlaceholder = '行程單日模板';
  static const String locationItemTemplatePlaceholder = '景點項目模板';
  static const String singleEntityPrefixPlaceholder = '單筆';
  static const String multiEntityPrefixPlaceholder = '多筆';

  // =================================================================
  // == Phase 1: 分析模板檔案，生成藍圖 (Analyze Template Files) ==
  // =================================================================
  Map<String, TemplateBlueprint> analyzeTemplates({
    required String itineraryTplContent,
    required String itineraryDayTplContent,
    required String locationListTplContent,
    required String locationItemTplContent,
  }) {
    final Map<String, TemplateBlueprint> blueprints = {};
    // 1. 分析景點項目模板 (最底層)
    final locationItemRegex = _createRegexFromItemTemplate(
      locationItemTplContent,
    );
    blueprints['景點項目模板'] = TemplateBlueprint(
      name: '景點項目模板',
      rules: [], // 它本身沒有 H2/H3 規則
      itemRegex: locationItemRegex['regex'],
      itemPlaceholderNames: locationItemRegex['placeholders'],
    );

    // 2. 分析景點清單模板
    blueprints['景點清單模板'] = TemplateBlueprint(
      name: '景點清單模板',
      rules: _extractRulesFromCompositeTemplate(
        content: locationListTplContent,
        // 告訴分析器，遇到這個 placeholder 就代表底下是可重複的子項目
        subTemplatePlaceholder: '{{多筆景點項目模板}}',
        subTemplateName: '景點項目模板',
      ),
    );

    // 3. 分析行程單日模板 (類似景點項目)
    final dayItemRegex = _createRegexFromItemTemplate(itineraryDayTplContent);
    blueprints['行程單日模板'] = TemplateBlueprint(
      name: '行程單日模板',
      rules: [],
      itemRegex: dayItemRegex['regex'],
      itemPlaceholderNames: dayItemRegex['placeholders'],
    );

    // 4. 分析行程模板
    blueprints['行程模板'] = TemplateBlueprint(
      name: '行程模板',
      rules: _extractRulesFromCompositeTemplate(
        content: itineraryTplContent,
        subTemplatePlaceholder: '{{多筆行程單日模板}}',
        subTemplateName: '行程單日模板',
      ),
      fingerprintRegex: blueprints['行程單日模板']!.itemRegex,
    );

    return blueprints;
  }

  // ===================================================================
  // == Phase 2: 使用藍圖解析實際的筆記檔案 (Parse Note File) ==
  // ===================================================================
  Map<String, dynamic> parseNote({
    required String noteContent,
    required TemplateBlueprint blueprint,
    required Map<String, TemplateBlueprint> allBlueprints,
  }) {
    final Map<String, dynamic> result = {};
    final lines = noteContent.split('\n');

    // --- 狀態機的狀態變數 ---
    String? currentH2Key;
    ParsingRule? currentH2Rule;
    
    // 用於儲存單一區塊的內容
    List<String> currentBlockContent = []; 
    // 用於儲存複合區塊的子項目列表
    List<Map<String, dynamic>> currentItemsList = []; 
    // 用於儲存當前正在處理的子項目
    Map<String, dynamic>? currentItemData; 
    List<String> currentItemContentLines = [];

    // --- 狀態提交輔助函式 ---
    void commitCurrentItem() {
      if (currentItemData != null) {
        currentItemData!['內容'] = currentItemContentLines.join('\n').trim();
        currentItemsList.add(currentItemData!);
        currentItemData = null;
        currentItemContentLines = [];
      }
    }

    void commitCurrentH2Section() {
      commitCurrentItem(); // 先提交最後一個子項目
      if (currentH2Key != null) {
        if (currentH2Rule?.subTemplateName != null) {
          result[currentH2Key!] = List.from(currentItemsList);
        } else {
          result[currentH2Key!] = currentBlockContent.join('\n').trim();
        }
      }
      currentBlockContent = [];
      currentItemsList = [];
    }
    
    // --- 單遍掃描主迴圈 ---
    for (final line in lines) {
      final h2Match = RegExp(r'^##\s+(.*)').firstMatch(line);
      final h3Match = RegExp(r'^###\s+(.*)').firstMatch(line);

      if (h2Match != null) {
        // 遇到新的 H2，代表一個區塊的開始
        commitCurrentH2Section(); // 提交上一個 H2 區塊的全部內容
        
        currentH2Key = h2Match.group(1)!.trim();
        currentH2Rule = blueprint.rules.firstWhere(
          (r) => r.level == 2 && r.key == currentH2Key,
          orElse: () => ParsingRule(level: 2, key: currentH2Key!),
        );

      } else if (h3Match != null && currentH2Rule?.subTemplateName != null) {
        // 【核心修正】在主迴圈中直接處理 H3
        commitCurrentItem(); // 提交上一個子項目
        
        final subTemplate = allBlueprints[currentH2Rule!.subTemplateName!];
        if (subTemplate?.itemRegex != null) {
          final itemHeaderMatch = subTemplate!.itemRegex!.firstMatch(line);
          if (itemHeaderMatch != null) {
            currentItemData = {};
            for (int i = 0; i < subTemplate.itemPlaceholderNames!.length; i++) {
              final key = subTemplate.itemPlaceholderNames![i];
              final value = itemHeaderMatch.group(i + 1)?.trim() ?? '';
              currentItemData![key] = value;
            }
          }
        }
      } else if (currentH2Key != null) {
        // 既不是 H2 也不是 H3，是內容行
        if (currentItemData != null) {
          // 如果當前正在處理一個子項目，內容就屬於它
          currentItemContentLines.add(line);
        } else {
          // 否則，內容屬於當前的 H2 區塊
          currentBlockContent.add(line);
        }
      }
    }
    
    commitCurrentH2Section(); // 處理文件最後一個區塊

    return result;
  }

  // ===================================================================
  // == Phase 3: 將解析後的結果轉換成 ParsedNote 物件 (Parse Result to ParsedNote) ==
  // ===================================================================
  Future<ParsedNote> parseFile(String filePath, Map<String, TemplateBlueprint> allBlueprints) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at $filePath');
    }
    final content = await file.readAsString();
    final title = parseTitle(content, p.basenameWithoutExtension(filePath));

    // 依序嘗試匹配主模板
    final itineraryBlueprint = allBlueprints['行程模板'];
    if (itineraryBlueprint?.fingerprintRegex != null && itineraryBlueprint!.fingerprintRegex!.hasMatch(content)) {
      final data = parseNote(noteContent: content, blueprint: itineraryBlueprint, allBlueprints: allBlueprints);
      return ItineraryNote(filePath: filePath, title: title, data: data);
    }
    
    final locationBlueprint = allBlueprints['景點清單模板'];
    if (locationBlueprint?.fingerprintRegex != null && locationBlueprint!.fingerprintRegex!.hasMatch(content)) {
       final data = parseNote(noteContent: content, blueprint: locationBlueprint, allBlueprints: allBlueprints);
       return LocationNote(filePath: filePath, title: title, data: data);
    }

    return GenericNote(filePath: filePath, title: title, rawContent: content);
  }


  // --- Private Helper Functions ---
  List<ParsingRule> _extractRulesFromCompositeTemplate({
    required String content,
    required String subTemplatePlaceholder,
    required String subTemplateName,
  }) {
    final rules = <ParsingRule>[];
    final lines = content.split('\n');
    for (final line in lines) {
      final h2Match = RegExp(r'^##\s+(.*)').firstMatch(line);
      if (h2Match != null) {
        final key = h2Match.group(1)!.trim();
        rules.add(
          ParsingRule(
            level: 2,
            key: key,
            // 檢查下一行是否是 placeholder
            subTemplateName:
                lines.indexOf(line) + 1 < lines.length &&
                    lines[lines.indexOf(line) + 1].trim() ==
                        subTemplatePlaceholder
                ? subTemplateName
                : null,
          ),
        );
      }
    }
    return rules;
  }

  /// 將模板字串轉換成一個強大的正規表示式 (修正版)
  Map<String, dynamic> _createRegexFromItemTemplate(String templateContent) {
    // 1. 依序找出所有 placeholder 的名稱
    final placeholderRegex = RegExp(r'\{\{(.*?)\}\}');
    final placeholders = placeholderRegex
        .allMatches(templateContent)
        .map((m) => m.group(1)!)
        .toList();

    // 2. 使用 placeholder 作為分隔符，將模板切成靜態的文字片段
    final parts = templateContent.split(placeholderRegex);

    // 3. 對每一個靜態文字片段進行轉義，以防其中包含 RegExp 的特殊字元
    final escapedParts = parts.map((part) => RegExp.escape(part)).toList();

    // 4. 將轉義後的文字片段用擷取群組 '(.*?)' 重新組合起來
    var regexString = '';
    for (int i = 0; i < escapedParts.length; i++) {
      regexString += escapedParts[i];
      // 在除了最後一個片段以外的每個片段後面加上擷取群組
      if (i < placeholders.length) {
        regexString += '(.*?)';
      }
    }

    return {
      'regex': RegExp(regexString, multiLine: true),
      'placeholders': placeholders,
    };
  }

  String parseTitle(String content, String fallback) {
    final h1Match = RegExp(r'^#\s+(.*)').firstMatch(content.trim());
    return h1Match?.group(1)?.trim() ?? fallback;
  }
}

final markdownServiceProvider = Provider((ref) => MarkdownParserService());
