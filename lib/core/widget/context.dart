import 'package:web_app_admin/core/widget/date_picker.dart';
import 'package:web_app_admin/core/widget/network_image_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Date: 13/1/2025
// By: Amr Mesbah
// Last update: 21/1/2025
// Objectives: This file is responsible for providing extensions to several classes in the project.

final inventoryNavKey = GlobalKey<NavigatorState>();

extension ContextExtension on BuildContext {
  // ScreenInfo
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;

  bool get isTabletRange500To600 =>
      MediaQuery.of(this).size.width >= 500 &&
          MediaQuery.of(this).size.width <= 600;
  bool get isTabletVer =>
      MediaQuery.of(this).size.width >= 600 &&
          MediaQuery.of(this).size.width < 800;

  bool get isTablett => MediaQuery.of(this).size.shortestSide >= 600;

  bool get isArabic => Get.locale.toString().toLowerCase().contains('ar');

  void navigateTo(String routeName, {Object? arguments}) {
    inventoryNavKey.currentState!.pushNamed(routeName, arguments: arguments);
  }

  void pop() {
    inventoryNavKey.currentState!.pop();
  }

  void popToFirst() {
    inventoryNavKey.currentState!.popUntil(
          (route) => route.isFirst,
    );
  }
}

/// Extension to add additional functionalities for string manipulation, specifically for number conversions.
extension NumberToArabic on String {
  /// Converts English digits in the string to equivalent Arabic digits.
  String toArabicNumbers() {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String result = this;
    for (int i = 0; i < englishDigits.length; i++) {
      result = result.replaceAll(englishDigits[i], arabicDigits[i]);
    }
    return result;
  }

  int toEnglishNumber() {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String result = this;
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return result.toInt();
  }

  double toEnglishNumberAsDouble() {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String result = this;
    for (int i = 0; i < arabicDigits.length; i++) {
      result = result.replaceAll(arabicDigits[i], englishDigits[i]);
    }
    return result.toDouble();
  }

  /// Returns the string padded with leading zeros to ensure it has at least two digits.
  String get doubleDigit {
    try {
      return padLeft(2, DateTimeHelper.formatInt(0));
    } catch (e) {
      return this;
    }
  }

  /// Converts the string to an integer, returning 0 if the conversion fails.
  int toInt() => int.tryParse(this) ?? 0;

  /// Converts the string to an integer, returning a default value if the conversion fails or the value is 0.
  int toIntDefualt(int number) =>
      int.tryParse(this) == 0 ? number : int.tryParse(this) ?? number;

  /// Converts the string to a double, returning 0 if the conversion fails.
  double toDouble() => double.tryParse(this) ?? 0;

  /// Converts all digits in the string to '0'.
  String replaceAllDigitsWithZero() {
    const digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = this;
    for (var digit in digits) {
      result = result.replaceAll(digit, DateTimeHelper.formatInt(0));
    }
    return result;
  }

  Color? toColor() {
    try {
      var hexColor = replaceAll("Color(", "").replaceAll(")", "");

      return Color(int.parse(hexColor));
    } catch (e) {
      return Colors.black; // Fallback color
    }
  }

  toImage() {
    if (this != null && isNotEmpty) {
      if (contains('http') || contains('https')) {
        return NetworkImageView(url: this);
      } else {
        return Image.asset(this);
      }
    }

    return null;
  }
}

extension IntToOrdinal on int {
  /// Converts integers up to 9 to their ordinal form, otherwise appends "th".
  String toOrdinal() {
    switch (this) {
      case 0:
        return '1st'.tr;
      case 1:
        return '2nd'.tr;
      case 2:
        return '3rd'.tr;

      default:
        return (Get.locale!.languageCode == 'en')
            ? (this + 1).toString() + 'th'.tr
            : (this + 1).toString().toArabicNumbers() +
            'th'.tr; // or '${this + 1}th'.tr if you want to maintain the +1 logic from original
    }
  }

  String formatNumber() {
    String formattedNumber;

    if (this >= 1000000) {
      formattedNumber = '${(this / 1000000).truncate()}M';
    } else if (this >= 1000) {
      formattedNumber = '${(this / 1000).truncate()}K';
    } else {
      formattedNumber = this.toString();
    }

    // التحقق من اللغة الحالية وإرجاع الرقم بالتنسيق المناسب
    if (Get.context!.isArabic) {
      return DateTimeHelper.formatInt(int.parse(
          formattedNumber.replaceAll('K', '000').replaceAll('M', '000000')));
    } else {
      return formattedNumber;
    }
  }
}

/// Extension to provide additional functionality to the bool type.
extension BoolExtension on bool {
  /// Toggles the boolean value and returns the opposite.
  bool toggle() {
    return !this;
  }
}
