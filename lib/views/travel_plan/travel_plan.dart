import 'package:flutter/material.dart';

class TravelPlanWidget extends StatelessWidget {
  const TravelPlanWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('行程導覽')),
      body: const Center(
        child: Text('行程導覽'),
      ),
    );
  }
}