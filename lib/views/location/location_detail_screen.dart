import 'package:flutter/material.dart';
import 'package:vault_trip/models/parsed_notes.dart';

class LocationDetailScreen extends StatelessWidget {
  final LocationNote note;
  const LocationDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(note.title)),
      body: const Center(
        child: Text('景點詳細'),
      ),
    );
  }
}