import 'package:flutter/material.dart';
import 'package:runap/utils/constants/colors.dart';

class TOutlinedButtomTheme {
  TOutlinedButtomTheme._();

  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
    elevation: 0.0,
    foregroundColor: TColors.colorBlack,
    side: const BorderSide(color: TColors.primaryColor),
    textStyle: const TextStyle(
        fontSize: 16.0, color: TColors.colorBlack, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
  ));

  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
    elevation: 0.0,
    foregroundColor: Colors.white,
    side: const BorderSide(color: TColors.primaryColor),
    textStyle: const TextStyle(
        fontSize: 16.0, color: Colors.white, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
  ));
}
