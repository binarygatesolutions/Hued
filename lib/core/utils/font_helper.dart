import 'package:flutter/material.dart';

class FontHelper {
  static bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  static String getFontFamily(String text) {
    return isArabic(text) ? 'Almarai' : 'PlusJakartaSans';
  }

  static TextStyle getTextStyle(String text, {TextStyle? style}) {
    final bool arabic = isArabic(text);
    final String family = arabic ? 'Almarai' : 'PlusJakartaSans';

    if (style != null) {
      return style.copyWith(
        fontFamily: family,
        height: arabic ? 1.4 : style.height,
      );
    }

    return TextStyle(fontFamily: family);
  }
}
