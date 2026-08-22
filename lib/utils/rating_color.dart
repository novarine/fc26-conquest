import 'package:flutter/material.dart';

/// Shared FC-style OVR tiering used across player cards and chips:
/// 80+ green, 70-79 yellow, below 70 red.
Color ratingColor(int rating) {
  if (rating >= 80) {
    return const Color(0xFF22C55E);
  }
  if (rating >= 70) {
    return const Color(0xFFEAB308);
  }
  return const Color(0xFFEF4444);
}
