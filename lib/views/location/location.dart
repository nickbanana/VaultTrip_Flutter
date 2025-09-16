import 'package:flutter/material.dart';
/// 景點導覽頁面 顯示景點區域列表
class LocationWidget extends StatelessWidget {
  const LocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('景點導覽')),
      body: const Center(
        child: Text('景點導覽'),
      ),
    );
  }
}