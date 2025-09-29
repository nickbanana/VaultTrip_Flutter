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
    final locationItemRegex = analyzeItemTemplate(locationItemTplContent);
    blueprints['景點項目模板'] = TemplateBlueprint(
      name: '景點項目模板',
      rules: [], // 它本身沒有 H2/H3 規則
      itemHeaderTemplate: locationItemRegex['itemHeaderTemplate'],
      itemBodyTemplates: locationItemRegex['itemBodyTemplates'],
      // itemBodyKeywords: locationItemRegex['itemBodyKeywords'],
    );

    // 2. 分析景點清單模板
    blueprints['景點清單模板'] = TemplateBlueprint(
      name: '景點清單模板',
      rules: _extractRulesFromCompositeTemplate(
        content: locationListTplContent,
        // 告訴分析器，遇到這個 placeholder 就代表底下是可重複的子項目
        subTemplatePlaceholder:
            '{{$multiEntityPrefixPlaceholder$locationItemTemplatePlaceholder}}',
        subTemplateName: locationItemTemplatePlaceholder,
      ),
      fingerprintRegex: createFingerprintRegexFromHeadings(
        locationListTplContent,
      ),
    );

    // 3. 分析行程單日模板 (類似景點項目)
    final dayItemRegex = analyzeItemTemplate(itineraryDayTplContent);
    blueprints['行程單日模板'] = TemplateBlueprint(
      name: '行程單日模板',
      rules: [],
      itemHeaderTemplate: dayItemRegex['itemHeaderTemplate'],
      itemBodyTemplates: dayItemRegex['itemBodyTemplates'],
      // itemBodyKeywords: dayItemRegex['itemBodyKeywords'],
    );

    // 4. 分析行程模板
    blueprints['行程模板'] = TemplateBlueprint(
      name: '行程模板',
      rules: _extractRulesFromCompositeTemplate(
        content: itineraryTplContent,
        subTemplatePlaceholder:
            '{{$multiEntityPrefixPlaceholder$itineraryDayTemplatePlaceholder}}',
        subTemplateName: itineraryDayTemplatePlaceholder,
      ),
      fingerprintRegex: blueprints[itineraryDayTemplatePlaceholder]!
          .itemHeaderTemplate!
          .regex,
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
        if (currentItemContentLines.isNotEmpty) {
          currentItemData!['內容'] = currentItemContentLines.join('\n').trim();
        }
        currentItemsList.add(currentItemData!);
        currentItemData = null;
        currentItemContentLines = [];
      }
    }

    void commitCurrentH2Section() {
      commitCurrentItem(); // 先提交最後一個子項目
      if (currentH2Key != null) {
        if (currentH2Rule?.subTemplateName != null) {
          result[currentH2Key] = List.from(currentItemsList);
        } else {
          result[currentH2Key] = currentBlockContent.join('\n').trim();
        }
      }
      currentBlockContent = [];
      currentItemsList = [];
    }

    // --- 單遍掃描主迴圈 ---
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        if (currentItemData != null) {
          // 如果當前正在處理一個子項目，內容就屬於它
          currentItemContentLines.add(line);
        }
        continue;
      }
      final h2Match = RegExp(r'^##\s+(.*)').firstMatch(trimmedLine);
      final subTemplate = (currentH2Rule?.subTemplateName != null)
          ? allBlueprints[currentH2Rule!.subTemplateName!]
          : null;
      final h3HeaderTemplate = subTemplate?.itemHeaderTemplate;
      final h3Match = (h3HeaderTemplate != null)
          ? h3HeaderTemplate.regex.firstMatch(trimmedLine)
          : null;

      if (h2Match != null) {
        // 遇到新的 H2，代表一個區塊的開始
        commitCurrentH2Section(); // 提交上一個 H2 區塊的全部內容

        currentH2Key = h2Match.group(1)!.trim();
        currentH2Rule = blueprint.rules.firstWhere(
          (r) => r.level == 2 && r.key == currentH2Key,
          orElse: () => ParsingRule(level: 2, key: currentH2Key!),
        );
      } else if (h3Match != null) {
        // 【核心修正】在主迴圈中直接處理 H3
        commitCurrentItem(); // 提交上一個子項目
        currentItemData = {};
        for (int i = 0; i < h3HeaderTemplate!.placeholders.length; i++) {
          final key = h3HeaderTemplate.placeholders[i];
          final value = h3Match.group(i + 1)?.trim() ?? '';
          currentItemData![key] = value;
        }
      } else if (currentItemData != null && subTemplate != null) {
        // --- 【你選中程式碼的最終修正版】 ---
        bool lineMatched = false;
        // 檢查子模板是否有「結構化」的內容行規則
        if (subTemplate.itemBodyTemplates.isNotEmpty) {
            for (final lineTemplate in subTemplate.itemBodyTemplates) {
                final contentMatch = lineTemplate.regex.firstMatch(trimmedLine);
                if (contentMatch != null) {
                    // 匹配成功，按規則提取資料
                    for (int i = 0; i < lineTemplate.placeholders.length; i++) {
                        final key = lineTemplate.placeholders[i];
                        final value = contentMatch.group(i + 1)?.trim() ?? '';
                        currentItemData![key] = value;
                    }
                    lineMatched = true;
                    break;
                }
            }
        }

        // 如果子模板沒有內容行規則 (像行程單日)，
        // 或者當前行不符合任何一條內容行規則，
        // 就將其視為「非結構化」的普通內容行並收集起來。
        if (!lineMatched) {
            currentItemContentLines.add(line);
        }
      } else if (currentH2Key != null) {
        // 既不是 H2 也不是 H3，是內容行
        // if (currentItemData != null) {
          // 如果當前正在處理一個子項目，內容就屬於它
          // currentItemContentLines.add(line);
        // }
        // 否則，內容屬於當前的 H2 區塊
        currentBlockContent.add(line);
      }
    }

    commitCurrentH2Section(); // 處理文件最後一個區塊

    return result;
  }

  // ===================================================================
  // == Phase 3: 將解析後的結果轉換成 ParsedNote 物件 (Parse Result to ParsedNote) ==
  // ===================================================================
  Future<ParsedNote> parseFile(
    String filePath,
    Map<String, TemplateBlueprint> allBlueprints,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found at $filePath');
    }
    final content = await file.readAsString();
    final title = parseTitle(content, p.basenameWithoutExtension(filePath));

    // 依序嘗試匹配主模板
    final itineraryBlueprint = allBlueprints['行程模板'];
    if (itineraryBlueprint?.fingerprintRegex != null &&
        itineraryBlueprint!.fingerprintRegex!.hasMatch(content)) {
      final data = parseNote(
        noteContent: content,
        blueprint: itineraryBlueprint,
        allBlueprints: allBlueprints,
      );
      return ItineraryNote(filePath: filePath, title: title, data: data);
    }

    final locationBlueprint = allBlueprints['景點清單模板'];
    if (locationBlueprint?.fingerprintRegex != null &&
        locationBlueprint!.fingerprintRegex!.hasMatch(content)) {
      final data = parseNote(
        noteContent: content,
        blueprint: locationBlueprint,
        allBlueprints: allBlueprints,
      );
      return LocationNote(filePath: filePath, title: title, data: data);
    }

    return GenericNote(filePath: filePath, title: title, rawContent: content);
  }

  RegExp? createFingerprintRegexFromHeadings(String? templateContent) {
    if (templateContent == null || templateContent.isEmpty) {
      return null;
    }
    // 尋找所有h2標題
    final h2Regex = RegExp(r'^##\s+(.*)', multiLine: true);
    final matches = h2Regex.allMatches(templateContent);

    if (matches.isEmpty) {
      return null;
    }

    // 提取每個標題的第一個字元，並用 Set 去除重複項
    final fingerprints = matches
        .map((match) {
          final headingText = match.group(1)?.trim();
          if (headingText != null && headingText.isNotEmpty) {
            // 使用 runes 來安全地獲取第一個字元，這對複雜 Emoji 很重要
            return String.fromCharCode(headingText.runes.first);
          }
          return null;
        })
        .whereType<String>()
        .toSet();

    if (fingerprints.isEmpty) {
      return null;
    }

    // 將所有 Emoji 用 '|' (OR) 連接起來，例如 "🏨|🗺️|🛍️"
    final joinedFingerprints = fingerprints.map(RegExp.escape).join('|');

    // 組成最終的正規表示式，例如 "^##\\s*(🏨|🗺️|🛍️)"
    final regexString = '^##\\s*($joinedFingerprints)';

    return RegExp(regexString, multiLine: true);
  }

  // --- Private Helper Functions ---
  List<ParsingRule> _extractRulesFromCompositeTemplate({
    required String content,
    required String subTemplatePlaceholder,
    required String subTemplateName,
  }) {
    final rules = <ParsingRule>[];
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final h2Match = RegExp(r'^##\s+(.*)').firstMatch(line);
      if (h2Match != null) {
        final key = h2Match.group(1)!.trim();
        String? detectedSubTemplateName;

        // --- 【核心修正】 ---
        // 找到 H2 標題後，開始向前掃描尋找 placeholder
        for (int j = i + 1; j < lines.length; j++) {
          final nextLine = lines[j].trim();

          if (nextLine.isEmpty) {
            // 如果是空行，就繼續往下找
            continue;
          }

          if (nextLine == subTemplatePlaceholder) {
            // 找到了！標記這是一個複合區塊
            detectedSubTemplateName = subTemplateName;
          }

          // 無論找到與否，只要遇到第一個非空行就停止對當前 H2 的掃描
          // 因為 placeholder 必須是 H2 後的第一個有意義的內容
          break;
        }
        // --- 【修正結束】 ---

        rules.add(
          ParsingRule(
            level: 2,
            key: key,
            subTemplateName: detectedSubTemplateName,
          ),
        );
      }
    }
    return rules;
  }

  Map<String, dynamic> analyzeItemTemplate(String templateContent) {
    final lines = templateContent
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return {};

    // 1. 分析標頭 (第一行)
    final header = lines.first;
    final headerTemplate = createLineTemplate(header);

    // 2. 分析內容 (剩餘行)
    // final Map<String, String> bodyKeywords = {};
    final List<LineTemplate> bodyTemplates = [];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      final currentLineTemplate = createLineTemplate(line);
      bodyTemplates.add(currentLineTemplate);
    }

    return {
      'itemHeaderTemplate': headerTemplate,
      // 'itemBodyKeywords': bodyKeywords,
      'itemBodyTemplates': bodyTemplates,
    };
  }

  /// 將模板字串轉換成一個強大的正規表示式 (修正版)
  LineTemplate createLineTemplate(String lineContent) {
    // 1. 依序找出所有 placeholder 的名稱
    final placeholderRegex = RegExp(r'\{\{(.*?)\}\}');
    final placeholders = placeholderRegex
        .allMatches(lineContent)
        .map((m) => m.group(1)!)
        .toList();

    // 2. 使用 placeholder 作為分隔符，將模板切成靜態的文字片段
    final parts = lineContent.split(placeholderRegex);

    // 3. 對每一個靜態文字片段進行轉義，以防其中包含 RegExp 的特殊字元
    final escapedParts = parts.map((part) => RegExp.escape(part)).toList();

    // 4. 【核心修正】重新組合
    var regexString = '^';
    for (int i = 0; i < escapedParts.length; i++) {
      regexString += escapedParts[i];
      if (i < placeholders.length) {
        regexString += r'(.*)';
      }
    }

    return LineTemplate(
      regex: RegExp(regexString, multiLine: true),
      placeholders: placeholders,
    );
  }

  String parseTitle(String content, String fallback) {
    final h1Match = RegExp(r'^#\s+(.*)').firstMatch(content.trim());
    return h1Match?.group(1)?.trim() ?? fallback;
  }
}

final markdownServiceProvider = Provider((ref) => MarkdownParserService());
