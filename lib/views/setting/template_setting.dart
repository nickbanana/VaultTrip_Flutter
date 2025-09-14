import 'package:flutter/material.dart';
import 'package:vault_trip/views/setting/path_container.dart';

class TemplateSettingWidget extends StatelessWidget {
  final String templateType;
  final String? templatePath;
  final void Function()? buttonPressedEvent;
  const TemplateSettingWidget({
    super.key,
    required this.templateType,
    required this.templatePath,
    this.buttonPressedEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$templateType路徑',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        PathContainer(
          path: templatePath,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.file_open),
              label: Text('選擇$templateType檔案路徑'),
              onPressed: buttonPressedEvent,
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
