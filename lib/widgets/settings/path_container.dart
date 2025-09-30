import 'package:flutter/material.dart';

class PathContainer extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;
  final String? path;

  const PathContainer({
    super.key,
    required this.path,
    this.decoration,
    this.padding = const EdgeInsets.all(12.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: decoration,
      child: Text(
        path ?? '未選擇',
        style: TextStyle(
          fontSize: 16,
          color: path == null ? Colors.grey : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
