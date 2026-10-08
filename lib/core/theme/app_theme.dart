// Date: 1/8/2024
// By: Amr Mesbah
// Last update: 29/9/2024
// Objectives: This file is responsible for providing the app themes that is used in the app.
// ADDED: applyFonts() — writes selected fonts to GetStorage then calls
//        Get.forceAppUpdate() so the entire widget tree rebuilds with the
//        new font family immediately, without needing a page reload ✅

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:web_app_admin/core/theme/text.dart';


import '../constant/color.dart';
import 'appcolors.dart';



abstract class AppTheme {
  static bool isDark = false;
  static final _storage = GetStorage(); // ✅ ADDED

  // ✅ ADDED: call this after saving branding fonts — writes to storage
  //          then forces the full widget tree to rebuild so AppTextStyles
  //          getters re-evaluate with the new font family
  static void applyFonts(String englishFont, String arabicFont) {
    final eng = englishFont.isEmpty ? 'Cairo' : englishFont;
    final ar  = arabicFont.isEmpty  ? 'Cairo' : arabicFont;
    _storage.write('font',        eng);
    _storage.write('font_arabic', ar);
    Get.forceAppUpdate(); // ✅ forces full widget tree rebuild
  }

  static final ThemeData lightTheme = ThemeData.light().copyWith(
    textTheme: TextTheme(
      headlineMedium: AppTextStyles.font20BlackCairoMedium,
      headlineSmall: AppTextStyles.font16BlackMediumCairo,
      titleLarge: AppTextStyles.font18BlackCairoMedium,
      titleMedium: AppTextStyles.font16BlackMediumCairo,
      titleSmall: AppTextStyles.font14BlackCairoMedium,
      bodyLarge: AppTextStyles.font14BlackCairoMedium,
      bodySmall: AppTextStyles.font12BlackMediumCairo,
      bodyMedium: AppTextStyles.font14BlackCairo,
      labelLarge: AppTextStyles.font14BlackCairoMedium,
      labelMedium: AppTextStyles.font12BlackMediumCairo,
      labelSmall: AppTextStyles.font10BlackCairoRegular,
      displayLarge: AppTextStyles.font23BlackRegularCairo,
      displayMedium: AppTextStyles.font20BlackCairoMedium,
      displaySmall: AppTextStyles.font16BlackMediumCairo,
    ),
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    // Cursor / text-selection (copy) highlight — app-wide rule:
    // always ColorPick.primary, never the theme yellow.
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: ColorPick.primary,
      selectionColor: ColorPick.primary.withOpacity(0.3),
      selectionHandleColor: ColorPick.primary,
    ),

    colorScheme: ColorScheme.light(
      primary: AppColors.secondaryPrimary,
      onPrimary: Colors.white,
      outlineVariant: AppColors.lightGrey,
      onSurface: AppColors.inverseBase,
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.r)),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      headerHeadlineStyle: AppTextStyles.font23BlackRegularCairo,
      weekdayStyle: AppTextStyles.font12DarkGrayCairo,
      headerBackgroundColor: AppColors.secondaryPrimary,
      headerForegroundColor: Colors.white,
      backgroundColor: AppColors.card,
      todayBackgroundColor: WidgetStatePropertyAll(AppColors.card),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.r)),
      ),
      dayStyle: AppTextStyles.font14BlackCairoMedium,
      dayBackgroundColor: WidgetStateProperty.resolveWith(
            (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimary;
          }
          return AppColors.card;
        },
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith(
            (states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          } else if (states.contains(WidgetState.disabled)) {
            return AppColors.lightGrey;
          }
          return AppColors.text;
        },
      ),
      yearBackgroundColor: WidgetStateProperty.resolveWith(
            (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimary;
          }
          return AppColors.card;
        },
      ),
      yearForegroundColor: WidgetStateProperty.resolveWith(
            (states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.text;
        },
      ),
      dividerColor: AppColors.secondaryPrimary,
      dayShape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      todayForegroundColor: WidgetStateProperty.all(
        AppColors.secondaryPrimary,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: AppColors.primary,
    // Cursor / text-selection (copy) highlight — app-wide rule:
    // always ColorPick.primary, never the theme yellow.
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: ColorPick.primary,
      selectionColor: ColorPick.primary.withOpacity(0.3),
      selectionHandleColor: ColorPick.primary,
    ),
    textTheme: TextTheme(
      headlineMedium: AppTextStyles.font20BlackCairoMedium,
      headlineSmall: AppTextStyles.font16BlackMediumCairo,
      titleLarge: AppTextStyles.font18BlackCairoMedium,
      titleMedium: AppTextStyles.font16BlackMediumCairo,
      titleSmall: AppTextStyles.font14BlackCairoMedium,
      bodyLarge: AppTextStyles.font14BlackCairoMedium,
      bodySmall: AppTextStyles.font12BlackMediumCairo,
      bodyMedium: AppTextStyles.font14BlackCairo,
      labelLarge: AppTextStyles.font14BlackCairoMedium,
      labelMedium: AppTextStyles.font12BlackMediumCairo,
      labelSmall: AppTextStyles.font10BlackCairoRegular,
      displayLarge: AppTextStyles.font23BlackRegularCairo,
      displayMedium: AppTextStyles.font20BlackCairoMedium,
      displaySmall: AppTextStyles.font16BlackMediumCairo,
    ),
    scaffoldBackgroundColor: AppColors.background,

    colorScheme: ColorScheme.dark(
      primary: AppColors.secondaryPrimary,
      onPrimary: Colors.white,
      outlineVariant: AppColors.lightGrey,
      onSurface: AppColors.inverseBase,
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.r)),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      headerHeadlineStyle: AppTextStyles.font23BlackRegularCairo,
      weekdayStyle: AppTextStyles.font12DarkGrayCairo,
      headerBackgroundColor: AppColors.secondaryPrimary,
      headerForegroundColor: Colors.white,
      backgroundColor: AppColors.card,
      todayBackgroundColor: WidgetStatePropertyAll(AppColors.card),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.r)),
      ),
      dayStyle: AppTextStyles.font14BlackCairoMedium,
      dayBackgroundColor: WidgetStateProperty.resolveWith(
            (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimary;
          }
          return AppColors.white;
        },
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith(
            (states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          } else if (states.contains(WidgetState.disabled)) {
            return AppColors.lightGrey;
          }
          return AppColors.black;
        },
      ),
      yearBackgroundColor: WidgetStateProperty.resolveWith(
            (states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondaryPrimary;
          }
          return AppColors.card;
        },
      ),
      yearForegroundColor: WidgetStateProperty.resolveWith(
            (states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.text;
        },
      ),
      dividerColor: AppColors.secondaryPrimary,
      dayShape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      todayForegroundColor: WidgetStateProperty.all(
        AppColors.secondaryPrimary,
      ),
    ),
  );

  // ****************** DEFINE COLOR PALETTE HERE ******************
  static Map<String, Color> lightThemeColors = {
    'pending': const Color(0xffFF814A),
    'switchOff': const Color(0xffe9e9eb),

    'evenRowColor': const Color(0xFFf1f1f1),
    'secondaryPrimary': const Color(0xffE5B800),
    'primary': const Color(0xffFFDE59),
    'inputColor': const Color(0xff8D8D8D),
    'grey': const Color(0xffD9D9D9),
    'lightGrey': const Color(0xffC3C3C3),
    'moreLightGrey': const Color(0xffEFEFEF),
    'mediumGrey': const Color(0xffA6A6A6),
    'darkGrey': const Color(0xff858585),
    'blackShadow': const Color.fromRGBO(0, 0, 0, 0.4),
    'green': const Color(0xff008000),
    'red': const Color(0xffDF1C1C),
    'header': const Color(0xff2D2D2D),
    'warming': const Color(0xffFF814A),
    'blue': const Color(0xff1F78D1),
    'card': Colors.white,
    'field': Colors.white,
    'text': const Color(0xff2D2D2D),
    'lightPrimary': const Color(0xFFffe993),

    'base': Colors.white,
    'inverseBase': const Color(0xff797979),
    'dropShadow': const Color(0xffC3C3C3).withValues(alpha: 0.5),
    'borderCard': const Color(0xffFFFFFF),
    'message': const Color(0xffEFEFEF),
    'messageText': const Color(0xff858585),
    'border': const Color(0xffD9D9D9),
    'background': const Color(0xFFF1F2ED),
    'appBar': const Color(0xffF5F5F5),
    'indicator': const Color(0xffE9E9E9),
    'starredCard': Colors.white,
    'black': const Color(0xff2D2D2D),
    'secondaryBlack': const Color(0xff797979),
    'whiteShadow': const Color(0xD9D9D9E0),
    'darkWhiteShadow': const Color(0x9E9E9E9E),
    'white': Colors.white,
    'darkWhite': const Color(0xffF2F2F2),
    'dialog': Colors.white,
    'button': const Color(0xffF2F2F2),
    'icon': const Color(0xff2D2D2D),
    'chatBackground': const Color(0xffF5F5F5),
    'chatField': Colors.white,
    'lightGreen': const Color(0xff4BB609),
    'orange': const Color(0xffFF814A),
    'darkRed': const Color(0xffDF1C1C),
    "lightRed": const Color(0xffFF0000),

    'yellow': const Color(0xffE5B800),
    'fieldBorder': const Color(0xffE5E5ED),
    'oddRowColor': Colors.white,
    'secondaryText': const Color(0xff797979),
    'spanText': const Color(0xff797979),
    'secondaryButton': const Color(0xCCCCCCCC),
    'fullBlack': const Color(0xff000000),
    'lighterGrey': const Color(0xff999999),
    'liteBlue': const Color(0xff1877F2),
    'borderGrey': const Color(0xffB5B4B4),
    'darkerGrey': const Color(0xffcccccc),
    'unBlock': const Color(0xFF4BB609),
    'navyBlue': const Color(0xFF768396),

    'greyBack': const Color(0xFFBCCCCC),
    'darkBackGround': const Color(0xFF545454),
    'block': const Color(0xFFDF0C0C),
    'warning': const Color(0xFFFF814A),
    'delete': const Color(0xFFDF1C1C),
    'differentGrey': const Color(0xFF9E9E9E),
    'barrierColor': const Color(0XFFD9D9D9).withValues(alpha: .9),
    'totalBlack': const Color(0xFF000000),
    'whiteDark': Color(0xFFF2F2F2),
    'crimson': const Color(0xFFDF0C0C),
    'whiteDashboardTable': const Color(0xFFF1F1F1),
    'darkDashboardTable': const Color(0xFF28282B),
    'greyIcon': const Color(0xffA6A6A6),
    'drawerColor': const Color(0xFF797979),
    'blackButton': Colors.black
  };

  // ****************** DEFINE DARK COLOR PALETTE HERE ******************
  static Map<String, Color> darkThemeColors = {
    "greyDark": const Color(0xff8D8D8D),
    'greyIcon': const Color(0xFF6F6F6F),
    'secondaryPrimary': const Color(0xffE5B800),
    'evenRowColor': const Color(0xFF545454),
    'oddRowColor': const Color(0xFF28282B),
    'primary': const Color(0xffFFDE59),
    'inputColor': const Color(0xff8D8D8D),
    'grey': const Color(0xffD9D9D9),
    'lightGrey': const Color(0xffC3C3C3),
    'moreLightGrey': const Color(0xffEFEFEF),
    'mediumGrey': const Color(0xffA6A6A6),
    'darkGrey': const Color(0xff858585),
    'blackShadow': const Color.fromRGBO(0, 0, 0, 0.4),
    'green': const Color(0xff008000),
    'red': const Color(0xffDF1C1C),
    'header': const Color(0xFF171717),
    'warming': const Color(0xffFF814A),
    'blue': const Color(0xff1F78D1),
    'card': const Color(0xff4B4B4B),
    'field': const Color(0xff4B4B4B),
    'text': Colors.white,
    'base': const Color(0xff797979),
    'inverseBase': Colors.white,
    'dropShadow': const Color(0xffC3C3C3).withValues(alpha: 0.5),
    'borderCard': const Color(0xffFFFFFF),
    'message': const Color(0xffEFEFEF),
    'messageText': const Color(0xff858585),
    'border': Colors.transparent,
    'navyBlue': const Color(0xFF768396),
    'switchOff': const Color(0xffe9e9eb),

    'background': const Color(0xff2D2D2D),
    'appBar': const Color(0xff2D2D2D),
    'indicator': const Color(0xffE9E9E9),
    'starredCard': Colors.white,
    'black': const Color(0xff2D2D2D),
    'secondaryBlack': Colors.white,
    'whiteShadow': const Color(0xD9D9D9E0),
    'lightPrimary': const Color(0xFFffe993),

    'darkWhiteShadow': const Color(0x9E9E9E9E),
    'white': Colors.white,
    'darkWhite': const Color(0xffF2F2F2),
    'dialog': const Color(0xff2D2D2D),
    'button': const Color(0xD9D9D9E0),
    'icon': const Color(0xD9D9D9E0),
    'chatBackground': const Color(0xff4B4B4B),
    'chatField': const Color(0xff2D2D2D),
    'lightGreen': const Color(0xff4BB609),
    'orange': const Color(0xffFF814A),
    'darkRed': const Color(0xffDF1C1C),
    'yellow': const Color(0xffE5B800),
    'fieldBorder': const Color(0xff797979),
    'secondaryText': const Color(0xffcccccc),
    'spanText': const Color(0xffd3d3d3),
    'secondaryButton': const Color(0xff858585),
    'fullBlack': const Color(0xffffffff),
    'lighterGrey': const Color(0xff999999),
    'liteBlue': const Color(0xff1877F2),
    'borderGrey': const Color(0xffB5B4B4),
    'darkerGrey': const Color(0xffcccccc),
    'crimson': const Color(0xFFDF0C0C),
    'whiteDashboardTable': const Color(0xFFF1F1F1),
    'darkDashboardTable': const Color(0xFF28282B),
    'drawerColor': const Color(0xFFCCCCCC),
    'blackButton': Colors.white,
  };

  static void setCurrentThemeColors() {
    AppColors.currentThemeColors =
    isDark ? darkThemeColors : lightThemeColors;
    Get.forceAppUpdate();
  }

  static void initTheme(
      Color primaryColor, Color secondaryColor, bool isDarkMode) async {
    isDark = isDarkMode;
    interfaceUpdateBrandingColors(primaryColor, secondaryColor);
    setCurrentThemeColors();
  }

  static void interfaceUpdateBrandingColors(
      Color primaryColor, Color secondaryColor) {
    lightThemeColors['secondaryPrimary'] = secondaryColor;
    lightThemeColors['primary'] = primaryColor;
    darkThemeColors['secondaryPrimary'] = secondaryColor;
    darkThemeColors['primary'] = primaryColor;

    setCurrentThemeColors();
  }

  static void toggleTheme() async {
    isDark = !isDark;
    setCurrentThemeColors();
  }

  static Color contrastColor() {
    final double primaryLuminance = AppColors.primary.computeLuminance();
    final double secondaryPrimaryLuminance = AppColors.secondaryPrimary.computeLuminance();

    if (primaryLuminance > 0.5 && secondaryPrimaryLuminance > 0.5) {
      return AppColors.black;
    } else if (primaryLuminance <= 0.5 && secondaryPrimaryLuminance <= 0.5) {
      return AppColors.white;
    } else {
      if (primaryLuminance > 0.5) return AppColors.black;
      return AppColors.white;
    }
  }

  static Color secondaryPrimaryText() {
    final double secondaryPrimaryLuminance =
    AppColors.secondaryPrimary.computeLuminance();

    if (secondaryPrimaryLuminance > 0.5) {
      return AppColors.black;
    } else if (secondaryPrimaryLuminance <= 0.5) {
      return AppColors.white;
    } else {
      if (secondaryPrimaryLuminance > 0.5) return AppColors.black;
      return AppColors.white;
    }
  }

  static Color contrastGreyColor() {
    final double primaryLuminance = AppColors.primary.computeLuminance();
    final double secondaryPrimaryLuminance =
    AppColors.secondaryPrimary.computeLuminance();

    if (primaryLuminance > 0.5 && secondaryPrimaryLuminance > 0.5) {
      return AppColors.secondaryBlack;
    } else if (primaryLuminance <= 0.5 && secondaryPrimaryLuminance <= 0.5) {
      return AppColors.white;
    } else {
      return AppColors.white;
    }
  }
}