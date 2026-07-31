import 'package:flutter/material.dart';

AppBar buildBookAppBar(
  String title, {
  List<Widget>? actions,
  VoidCallback? onBack,
}) {
  return AppBar(
    elevation: 0,
    centerTitle: false,
    titleSpacing: 16,
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    leading: onBack == null
        ? null
        : IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
    actions: actions,
  );
}
