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

// Punto de entrada de la aplicación
Future<void> main() async {
  // --- 1. Asegurar Inicialización de Widgets ---
  // Es lo primero que se debe hacer si se necesita interactuar con el engine antes de runApp
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  // --- 2. Inicializar Almacenamiento Local ---
  // Util para guardar configuraciones, tokens, etc. de forma persistente
  await GetStorage.init();

  // --- 3. Preservar la Pantalla de Splash Nativa ---
  // Mantiene el splash visible mientras se cargan las configuraciones iniciales
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // --- 4. Configurar Estilo de la Barra de Estado por Defecto ---
  // Establece un estilo global inicial. Puede ser sobrescrito por pantallas individuales
  // usando AnnotatedRegion.
  // Ejemplo: Fondo transparente (para diseños edge-to-edge en Android) e iconos oscuros.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparente en Android
      statusBarIconBrightness:
          Brightness.dark, // Iconos oscuros (para fondos claros) - Android
      statusBarBrightness:
          Brightness.light, // Íconos oscuros (para fondos claros) - iOS
    ),
  );

  // --- 5. Configurar la Transición Personalizada ---
  // Ya no usamos este método, ahora utilizamos nuestro sistema de navegación personalizado
  // TNavigationHelper.setupCustomBackTransition();
  log("Custom Page Transitions Configured");

  // --- 6. Inicializar Firebase y Repositorio de Autenticación ---
  // Es crucial manejar posibles errores durante la inicialización de Firebase.
  try {
    await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform)
        .then(
      (FirebaseApp value) {
        // Configurar la persistencia de Firestore ANTES de usar Firestore por primera vez
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          // Opcional: Ajustar el tamaño de la caché si es necesario
          // cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // O un valor específico en bytes
        );
        log("Firestore Persistence Enabled");

        // Una vez Firebase está listo, inicializamos y registramos el repositorio
        // usando GetX. Esto asegura que el repo solo esté disponible si Firebase funciona.
        Get.put(AuthenticationRepository());
        log("Firebase Initialized Successfully"); // Mensaje de éxito (opcional)
      },
    );
  } catch (e, stackTrace) {
    // Captura cualquier error durante la inicialización de Firebase
    log("Firebase Initialization Failed", error: e, stackTrace: stackTrace);
    // Aquí podrías decidir qué hacer:
    // - Mostrar un mensaje de error específico antes de runApp (más complejo).
    // - Simplemente registrar el error y continuar (la app podría no funcionar correctamente).
    // - Lanzar una excepción para detener la ejecución si Firebase es absolutamente crítico.
    //   throw Exception("Firebase could not be initialized.");
  }

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
