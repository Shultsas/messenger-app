// lib/utils/avatar_color_generator.dart

import 'package:flutter/material.dart';

class AvatarColorGenerator {
  static final List<Color> _palette = [
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.deepPurpleAccent,
    Colors.indigoAccent,
    Colors.blueAccent,
    Colors.lightBlueAccent,
    Colors.cyanAccent,
    Colors.tealAccent,
    Colors.greenAccent,
    Colors.lightGreenAccent,
    Colors.limeAccent,
    Colors.yellowAccent,
    Colors.amberAccent,
    Colors.orangeAccent,
    Colors.deepOrangeAccent,
  ];

  static Color getColor(String name) {
    if (name.isEmpty) return Colors.grey;

    int sum = 0;
    for (int i = 0; i < name.length; i++) {
      sum += name.codeUnitAt(i);
    }

    return _palette[sum % _palette.length];
  }

  static LinearGradient getGradient(String name) {
    final color = getColor(name);
    return LinearGradient(
      colors: [
        color.withOpacity(0.8),
        color.withOpacity(0.4),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}