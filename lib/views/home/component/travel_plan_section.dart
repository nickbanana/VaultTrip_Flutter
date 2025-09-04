import 'package:flutter/material.dart';

class TravelPlanSectionWidget extends StatelessWidget {
  const TravelPlanSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('行程概覽'),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 300,
          ),
          child: ListView(
            children: [
              ListTile(
                title: Text('文件名稱'),
                subtitle: Text('文件內容'),
              ),
              ListTile(
                title: Text('文件名稱'),
                subtitle: Text('文件內容'),
              ),
              ListTile(
                title: Text('文件名稱'),
                subtitle: Text('文件內容'),
              ),
            ]
          )
        )
      ],
    );
  }
}