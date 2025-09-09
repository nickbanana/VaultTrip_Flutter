import 'package:flutter/material.dart';

class PointOfInterestWidget extends StatelessWidget {
  const PointOfInterestWidget({super.key});

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