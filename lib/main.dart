import 'dart:async'; // Para manejo de errores asíncronos si es necesario
import 'dart:developer'; // Para log (opcional, pero útil)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para SystemChrome (barra de estado)
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/data/repositories/authentication/authentication_repository.dart'; // Asegúrate que la ruta es correcta
import 'package:runap/firebase_options.dart'; // Asegúrate que la ruta es correcta
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app.dart'; // Asegúrate que la ruta es correcta
import 'package:runap/features/gamification/presentation/manager/binding/gamification_binding.dart'; // Importar el binding

// Punto de entrada de la aplicación
Future<void> main() async {
  // --- 1. Inicializar WidgetsBinding ---
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // --- 2. Mantener SplashScreen hasta que estemos listos ---
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // --- 3. Inicializar GetStorage (persistencia local) ---
  await GetStorage.init();
  log("GetStorage Initialized"); // Mensaje opcional

  // --- 4. Configurar orientación preferida (solo portrait) ---
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  log("Device Orientation Set"); // Mensaje opcional

  // --- 5. Setear color/estilo de barra de estado ---
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  log("System UI Style Set"); // Mensaje opcional

  // --- 6. Inicializar Firebase (con mejor manejo de errores) ---
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform)
        .then(
      (FirebaseApp value) {
        // Configurar la persistencia de Firestore ANTES de usar Firestore por primera vez
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings
              .CACHE_SIZE_UNLIMITED, // Maximizar caché para modo offline
        );
        log("Firestore Persistence Enabled");

        // Una vez Firebase está listo, inicializamos y registramos el repositorio
        // usando GetX. Esto asegura que el repo solo esté disponible si Firebase funciona.
        Get.put(AuthenticationRepository());
        log("Firebase Initialized Successfully"); // Mensaje de éxito
        firebaseInitialized = true;
      },
    );
  } catch (e, stackTrace) {
    // Captura cualquier error durante la inicialización de Firebase
    log("Firebase Initialization Failed", error: e, stackTrace: stackTrace);

    // Incluso con error, intentamos inicializar el AuthenticationRepository
    // para que maneje el estado offline/error por sí mismo
    if (!firebaseInitialized) {
      try {
        Get.put(AuthenticationRepository());
        log("AuthenticationRepository initialized despite Firebase error");
      } catch (authError) {
        log("Failed to initialize AuthenticationRepository", error: authError);
      }
    }
  }

  // --- Inicializar Bindings ---
  // Asegúrate de inicializar tus bindings aquí
  GamificationBinding().dependencies(); // Ejecutar las dependencias del binding
  log("Gamification Dependencies Initialized"); // Mensaje opcional

  // --- 7. Inicializar Service Locator (si usas uno adicional a GetX) ---
  // Aquí configuras otras dependencias (ej: con get_it).
  // Considera si puedes unificar tu estrategia de DI (solo GetX o solo get_it)
  // para simplificar la gestión de dependencias.
  // setupServiceLocator(); // Eliminado: Ya no se usa
  // log("Service Locator Setup Complete"); // Eliminado: Ya no se usa

  // --- 8. Ejecutar la Aplicación ---
  // ¡Importante! Recuerda llamar a FlutterNativeSplash.remove() dentro de tu app
  // (ej. en initState de tu primera pantalla después del login/loading)
  // para ocultar la pantalla de splash.

  runApp(const App());
}
