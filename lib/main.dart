import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/Core/service_locator.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
import 'package:runap/firebase_options.dart';
import 'app.dart';

// Entry point of the application
Future<void> main() async {
  // Widgets Binding
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  // Getx Local Storage
  await GetStorage.init();

  // Await Splash until other items load
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase & Authentication Repository
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then(
    (FirebaseApp value) => Get.put(AuthenticationRepository()),
  );

  // Initialize Service Locator
  setupServiceLocator();

  // Run App
  runApp(const App());
}
