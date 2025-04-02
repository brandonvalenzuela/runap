import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/theme/custom_themes/appbar_theme.dart';
import 'package:runap/utils/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:runap/utils/theme/custom_themes/checkbox_theme.dart';
import 'package:runap/utils/theme/custom_themes/chip_theme.dart';
import 'package:runap/utils/theme/custom_themes/elevated_buttom_theme.dart';
import 'package:runap/utils/theme/custom_themes/outlined_buttom_theme.dart';
import 'package:runap/utils/theme/custom_themes/text_field_theme.dart';
import 'package:runap/utils/theme/custom_themes/text_theme.dart';

class TAppTheme {
  TAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: Colors.orange,
    textTheme: TTextTheme.lightTextTheme,
    chipTheme: TChipTheme.lightChipTheme,
    scaffoldBackgroundColor: TColors.lightBackground,
    appBarTheme: TAppBarTheme.lightAppBarTheme.copyWith(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Or any color you prefer for light theme
        statusBarIconBrightness: Brightness.dark, // For dark icons on a light background
        statusBarBrightness: Brightness.light, // For iOS: light status bar
      ),
    ),
    checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
    bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtomTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.lightInputDecorationTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark, // Changed brightness to dark for dark theme
    primaryColor: Colors.orange,
    textTheme: TTextTheme.darkTextTheme,
    chipTheme: TChipTheme.darkChipTheme,
    scaffoldBackgroundColor: TColors.colorBlack,
    appBarTheme: TAppBarTheme.darkAppBarTheme.copyWith(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Or any color you prefer for dark theme
        statusBarIconBrightness: Brightness.light, // For light icons on a dark background
        statusBarBrightness: Brightness.dark, // For iOS: dark status bar
      ),
    ),
    checkboxTheme: TCheckboxTheme.darkCheckboxTheme,
    bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
    elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: TOutlinedButtomTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: TTextFormFieldTheme.darkInputDecorationTheme,
  );
}
