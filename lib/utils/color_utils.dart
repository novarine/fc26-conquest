import 'package:flutter/material.dart';

Color parseHexColor(String value) {
  final normalized = value.replaceAll('#', '');
  final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.parse(hex, radix: 16));
}
