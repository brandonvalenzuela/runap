import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/bindings/app_bindings.dart';
import 'package:runap/features/authentication/screens/login/login.dart';
import 'utils/theme/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RunAP',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      initialBinding: AppBindings(),
      home: const LoginScreen(),
      defaultTransition: Transition.fade,
      smartManagement: SmartManagement.keepFactory,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', ''),
      ],
      locale: const Locale('es', 'ES'),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
