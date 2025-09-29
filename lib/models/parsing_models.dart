import 'package:flutter/foundation.dart';

/// 代表從模板檔案分析出來的單一解析規則
@immutable
class ParsingRule {
  /// 標題層級 (ex: #, ##, ### 對應到 1, 2, 3 等)
  final int level;
  /// 標題的靜態文字
  final String key;
  /// 如果是複合區塊(標題底下還有其他模板)，其子模板的名稱
  final String? subTemplateName;
  ParsingRule({required this.level, required this.key, this.subTemplateName});
}

/// 代表一個完整的，已分析的模板藍圖
@immutable
class TemplateBlueprint {
  final String name;
  /// 此模板包含的所有H2/H3 規則
  final List<ParsingRule> rules;
  /// 專門用於解析子項目的正規表達式
  final RegExp? itemHeaderRegex;
  /// 獨特用於識別筆記類型的正規表達式
  final RegExp? fingerprintRegex;
  final List<String>? itemHeaderPlaceholders;
  final Map<String, String>? itemBodyKeywords;
  TemplateBlueprint({
    required this.name,
    required this.rules,
    this.itemHeaderRegex,
    this.itemHeaderPlaceholders,
    this.fingerprintRegex,
    this.itemBodyKeywords,
  });
}