import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/bindings/general_bindings.dart';
import 'package:runap/utils/constants/colors.dart';
import 'utils/theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      initialBinding: GeneralBindings(),
      home: const Scaffold(
          backgroundColor: TColors.primaryColor,
          body: Center(
              child: CircularProgressIndicator(
                  color: Colors.white))), //const OnBoardingScreen(),
    );
  }
}
