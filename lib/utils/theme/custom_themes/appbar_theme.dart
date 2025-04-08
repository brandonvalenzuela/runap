import 'package:flutter/material.dart';
import 'package:runap/utils/constants/colors.dart';

class TAppBarTheme {
  TAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0.0,
    centerTitle: false,
    scrolledUnderElevation: 0.0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TColors.colorBlack, size: 24.0),
    actionsIconTheme: IconThemeData(color: TColors.colorBlack, size: 24.0),
    titleTextStyle: TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.w600, color: TColors.colorBlack),
  );

  static const darkAppBarTheme = AppBarTheme(
    elevation: 0.0,
    centerTitle: false,
    scrolledUnderElevation: 0.0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: TColors.colorBlack, size: 24.0),
    actionsIconTheme: IconThemeData(color: Colors.white, size: 24.0),
    titleTextStyle: TextStyle(
        fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.white),
  );
}
