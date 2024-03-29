import 'package:flutter/material.dart';

extension JonlineColors on Color {
  static final Map<Color, double> _luminanceCache = {};
  Color withAlpha(int alpha) => Color.fromARGB(alpha, red, green, blue);

  double get luminance =>
      JonlineColors._luminanceCache.putIfAbsent(this, () => computeLuminance());
  bool get bright => luminance > 0.5;

  /// With [this] as the background color, computes the appropriate text color.
  Color get textColor {
    if (bright) {
      return Colors.black;
    }
    return Colors.white;
  }
}
