import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_to_obsidian/core/theme/global_theme.dart';

void main() {
  test('getThemeDefault returns a valid ThemeData', () {
    final theme = getThemeDefault();
    expect(theme, isA<ThemeData>());
    expect(theme.brightness, Brightness.dark);
  });
}
