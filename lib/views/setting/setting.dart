import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vault_trip/providers/vault_provider.dart';

class SettingWidget extends StatelessWidget {
  const SettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vaultProvider = context.watch<VaultProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Obsidian Vault 路徑',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vaultProvider.vaultPath ?? '未選擇',
                style: TextStyle(
                  fontSize: 16,
                  color: vaultProvider.vaultPath == null
                      ? Colors.grey[600] : Colors.black,
                ),
              )
            ),
            const SizedBox(height: 20),
            // 選擇路徑的按鈕
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('選擇 Vault 資料夾'),
              onPressed: () {
                // 按下按鈕時，呼叫 Provider 的方法來處理邏輯
                // 這裡使用 context.read 是因為我們在一個 callback 中，不需要監聽變化
                context.read<VaultProvider>().selectAndSaveVaultPath();
              },
            ),
            const SizedBox(height: 10),
            // 清除路徑的按鈕 (可選)
            TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('清除路徑設定', style: TextStyle(color: Colors.red)),
                onPressed: () {
                    context.read<VaultProvider>().clearVaultPath();
                },
            ),
            ElevatedButton(
              child: const Text('檢查並授予權限'),
              onPressed: () async {
                // 請求權限
                var storageStatus = await Permission.storage.status;
                if (!storageStatus.isGranted) {
                  await Permission.storage.request();
                }

                var manageStatus = await Permission.manageExternalStorage.status;
                if (!manageStatus.isGranted) {
                  // 這個權限比較特殊，通常需要引導使用者去設定頁開啟
                  await Permission.manageExternalStorage.request();
                }
                // 檢查最終狀態並提示使用者
                if (await Permission.manageExternalStorage.isGranted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已獲得所有檔案存取權限！'))
                    );
                } else {
                    if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('權限不足，無法讀取檔案。'))
                        );
                    }
                }
              },
            )
          ],
        ),
      )
    );
  }
}