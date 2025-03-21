import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/Core/service_locator.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart';
import 'package:runap/firebase_options.dart';

import 'app.dart';

//------Entry point of the application------//
Future<void> main() async {
  // Todo: Add Widgets Binding
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  // Todo: Init Local Storage
  await GetStorage.init();

  // Todo: Init Payment Methods
  // Todo: Await Native Splash
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Todo: Inizialize Firebase & Authentication Repository
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then(
    (FirebaseApp value) => Get.put(AuthenticationRepository()),
  );

  // Todo: Inizialize Authentication

  // Todo: Inizialize Service Locator
  setupServiceLocator();

  // Load all the Material Design / Theme / Localizations / Bindings
  runApp(const App());
}
