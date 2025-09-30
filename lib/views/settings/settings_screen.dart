import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vault_trip/providers/settings_provider.dart';
import 'package:vault_trip/views/vault_browser/vault_browser_screen.dart';
import 'package:vault_trip/widgets/settings/path_container.dart';
import 'package:vault_trip/widgets/settings/template_setting.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickTemplateFile(
    BuildContext context,
    WidgetRef ref,
    String prefKey,
  ) async {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final settingsAsync = ref.read(settingsProvider);

    // Handle the AsyncValue to get the actual settings
    final settings = settingsAsync.when(
      data: (settings) => settings,
      loading: () => null,
      error: (error, stack) => null,
    );
    final vaultPath = settings?.vaultPath;

    if (vaultPath == null || vaultPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先設定Vault路徑!')));
      return;
    }
    final selectedAbsolutePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => VaultBrowserScreen(isSelectMode: true)),
    );

    if (selectedAbsolutePath != null) {
      final selectedRelativePath = p.relative(
        selectedAbsolutePath,
        from: vaultPath,
      );
      await settingsNotifier.saveTemplatePath(prefKey, selectedRelativePath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已設定模板: ${p.basename(selectedRelativePath)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    return settingsState.when(
      data: (settingsState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('設定'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text(
                  'Obsidian Vault 路徑',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                PathContainer(
                  path: settingsState.vaultPath,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                // 選擇路徑的按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('選擇 Vault 資料夾'),
                      onPressed: () {
                        // 按下按鈕時，呼叫 Provider 的方法來處理邏輯
                        // 這裡使用 context.read 是因為我們在一個 callback 中，不需要監聽變化
                        settingsNotifier.selectAndSaveVaultPath();
                      },
                    ),
                    // 清除路徑的按鈕 (可選)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        '清除路徑設定',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        settingsNotifier.clearVaultPath();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('檢查並授予權限'),
                      onPressed: () async {
                        // 請求權限
                        var storageStatus = await Permission.storage.status;
                        if (!storageStatus.isGranted) {
                          await Permission.storage.request();
                        }

                        var manageStatus =
                            await Permission.manageExternalStorage.status;
                        if (!manageStatus.isGranted) {
                          // 這個權限比較特殊，通常需要引導使用者去設定頁開啟
                          await Permission.manageExternalStorage.request();
                        }
                        // 檢查最終狀態並提示使用者
                        if (await Permission.manageExternalStorage.isGranted &&
                            context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已獲得所有檔案存取權限！')),
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('權限不足，無法讀取檔案。')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 32),
                TemplateSettingWidget(
                  templateType: '行程模板',
                  templatePath: settingsState.itineraryTemplatePath,
                  buttonPressedEvent: () => _pickTemplateFile(
                    context,
                    ref,
                    SettingsNotifier.itineraryTemplatePathKey,
                  ),
                ),
                TemplateSettingWidget(
                  templateType: '行程單日模板',
                  templatePath: settingsState.itineraryDayTemplatePath,
                  buttonPressedEvent: () => _pickTemplateFile(
                    context,
                    ref,
                    SettingsNotifier.itineraryDayTemplatePathKey,
                  ),
                ),
                TemplateSettingWidget(
                  templateType: '景點清單模板',
                  templatePath: settingsState.locationListTemplatePath,
                  buttonPressedEvent: () => _pickTemplateFile(
                    context,
                    ref,
                    SettingsNotifier.locationListTemplatePathKey,
                  ),
                ),
                TemplateSettingWidget(
                  templateType: '景點項目模板',
                  templatePath: settingsState.locationItemTemplatePath,
                  buttonPressedEvent: () => _pickTemplateFile(
                    context,
                    ref,
                    SettingsNotifier.locationItemTemplatePathKey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
