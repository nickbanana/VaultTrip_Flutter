import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parsing_models.dart';

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
    );

    return blueprints;
  }

  // ===================================================================
  // == Phase 2: 使用藍圖解析實際的筆記檔案 (Parse Note File) ==
  // ===================================================================
  Map<String, dynamic> parseNote({
    required String noteContent,
    required TemplateBlueprint blueprint, // 使用哪個藍圖來解析
    required Map<String, TemplateBlueprint> allBlueprints, // 需要所有藍圖來查找子模板
  }) {
    final Map<String, dynamic> result = {};
    final lines = noteContent.split('\n');

    String? currentKey;
    List<String> currentBlockContent = [];
    ParsingRule? currentRule;

    void processBlock() {
      if (currentKey == null) return;

      final blockText = currentBlockContent.join('\n').trim();

      if (currentRule?.subTemplateName != null) {
        // --- 處理複合區塊 (e.g., 景點列表) ---
        final subTemplate = allBlueprints[currentRule!.subTemplateName!];
        if (subTemplate?.itemRegex != null) {
          final matches = subTemplate!.itemRegex!.allMatches(blockText);
          final List<Map<String, String>> items = [];
          for (final match in matches) {
            final Map<String, String> itemData = {};
            for (int i = 0; i < subTemplate.itemPlaceholderNames!.length; i++) {
              final key = subTemplate.itemPlaceholderNames![i];
              final value = match.group(i + 1)?.trim() ?? '';
              itemData[key] = value;
            }
            items.add(itemData);
          }
          result[currentKey] = items;
        }
      } else {
        // --- 處理單一區塊 (e.g., 航班資訊) ---
        result[currentKey] = blockText;
      }

      currentBlockContent = [];
    }

    for (final line in lines) {
      final h2Match = RegExp(r'^##\s+(.*)').firstMatch(line);
      final h3Match = RegExp(r'^###\s+(.*)').firstMatch(line);

      ParsingRule? foundRule;
      String? foundKey;

      if (h2Match != null) {
        foundKey = h2Match.group(1)!.trim();
        foundRule = blueprint.rules.firstWhere(
          (r) => r.level == 2 && r.key == foundKey,
          orElse: () => ParsingRule(level: 2, key: foundKey!),
        );
      } else if (h3Match != null) {
        // 這裡可以擴充 H3 的邏輯，目前我們的模板 H3 只在子項目中
      }

      if (foundRule != null) {
        // 遇到一個新的標題，先處理上一個區塊的內容
        processBlock();
        // 開始一個新區塊
        currentKey = foundKey;
        currentRule = foundRule;
      } else if (currentKey != null) {
        // 如果還在當前區塊，就把內容加進去
        currentBlockContent.add(line);
      }
    }

    // 處理文件最後一個區塊的內容
    processBlock();

    return result;
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
}

final markdownServiceProvider = Provider((ref) => MarkdownParserService());
