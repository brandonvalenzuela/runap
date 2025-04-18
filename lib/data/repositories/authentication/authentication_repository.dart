// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/features/authentication/screens/signup/verify_email.dart';
import 'package:runap/navigation_menu.dart';
import 'package:runap/features/authentication/screens/welcome/welcome_screen.dart';
import 'package:runap/features/dashboard/presentation/manager/binding/home_binding.dart';
import 'package:runap/utils/popups/full_screen_loader.dart';
// TODO: Importar UserRepository si se implementa la consulta al backend
// import 'package:runap/data/repositories/user/user_repository.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  // Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  // Getter para obtener el UID del usuario actual de forma segura
  String? get currentUserId => _auth.currentUser?.uid;

  // Called from main.dart on app launch
  @override
  void onReady() {
    // Asegurarse de que el splash se quite incluso si hay errores
    try {
      FlutterNativeSplash.remove();
    } catch (e) {
      print("Error al quitar splash: $e");
    }

    try {
      // Verificar si hay datos de sesión guardados localmente para iniciar sin internet
      final bool hasOfflineSession =
          deviceStorage.read('HasOfflineSession') ?? false;

      if (hasOfflineSession) {
        print(
            "📱 [AUTH_INIT] Se encontró sesión offline almacenada, iniciando app...");
        Get.offAll(() => const NavigationMenu(), binding: HomeBinding());
        return;
      }

      // Escuchar el estado de autenticación inicial
      _auth.authStateChanges().listen((User? user) {
        if (user == null) {
          // No user authenticated -> Welcome Screen
          print(
              "🏁 [AUTH_INIT] No user found. Redirecting to WelcomeScreen...");
          // No llamar a stopLoading aquí, no hay loader activo al inicio.
          screenRedirectToWelcome();
        } else {
          // User is authenticated, check verification and survey status
          print("🏁 [AUTH_INIT] User found (${user.uid}). Checking status...");
          // IMPORTANTE: Primero verificar si el email está verificado.
          try {
            if (user.emailVerified) {
              print(
                  "📧 [AUTH_INIT] User email IS verified. Checking survey status...");
              // Guardar información de sesión para uso offline
              deviceStorage.write('HasOfflineSession', true);
              // Si el email está verificado, usar la lógica post-login
              // (que ahora detiene el loader antes de navegar).
              checkAuthStatusAndNavigate();
            } else {
              print(
                  "📧 [AUTH_INIT] User email NOT verified. Redirecting to VerifyEmailScreen...");
              // Si el email no está verificado, enviar a la pantalla de verificación.
              // Detener loader aquí SÍ tiene sentido si venimos de un flujo donde pudo activarse.
              TFullScreenLoader.stopLoading();
              Get.offAll(() => VerifyEmailScreen(email: user.email),
                  transition: Transition.upToDown);
            }
          } catch (e) {
            // Error verificando email - podría ser sin conexión
            print(
                "⚠️ [AUTH_INIT] Error verificando email: $e. Intentando modo offline...");

            // Verificar si tenemos información guardada previamente
            if (deviceStorage.read('HasOfflineSession') == true) {
              print(
                  "📱 [AUTH_INIT] Usando información offline guardada previamente.");
              Get.offAll(() => const NavigationMenu(), binding: HomeBinding());
            } else {
              // No tenemos información guardada, ir a welcome
              print(
                  "⚠️ [AUTH_INIT] No hay información offline previa. Redirigiendo a Welcome.");
              screenRedirectToWelcome();
            }
          }
        }
      }, onError: (error) {
        // Manejar error en el listener de authStateChanges
        print("⚠️ [AUTH_INIT] Error en authStateChanges: $error");

        // Verificar si tenemos información guardada previamente para modo offline
        if (deviceStorage.read('HasOfflineSession') == true) {
          print(
              "📱 [AUTH_INIT] Usando información offline guardada previamente tras error.");
          Get.offAll(() => const NavigationMenu(), binding: HomeBinding());
        } else {
          // No tenemos información guardada, ir a welcome
          print(
              "⚠️ [AUTH_INIT] No hay información offline previa tras error. Redirigiendo a Welcome.");
          screenRedirectToWelcome();
        }
      });
    } catch (e) {
      // Capturar cualquier error no controlado en onReady
      print("❌ [AUTH_INIT] Error crítico en onReady: $e");

      // Intentar usar información offline como último recurso
      if (deviceStorage.read('HasOfflineSession') == true) {
        print("📱 [AUTH_INIT] Usando información offline tras error crítico.");
        Get.offAll(() => const NavigationMenu(), binding: HomeBinding());
      } else {
        // Si todo falla, ir a Welcome
        screenRedirectToWelcome();
      }
    }
  }

  /// Función para redirigir SIEMPRE a WelcomeScreen al inicio de la app si no hay sesión.
  void screenRedirectToWelcome() {
    print("🏁 [AUTH_REDIRECT] Redirigiendo a WelcomeScreen...");
    // Eliminar stopLoading de aquí también, principalmente se llama al inicio.
    Get.offAll(() => const WelcomeScreen());
  }

  /// Función para verificar estado DESPUÉS de Login/Signup y redirigir.
  void checkAuthStatusAndNavigate() async {
    print("🏁 [AUTH_CHECK] Verificando estado post-login/signup...");
    final user = _auth.currentUser;
    print("🕵️ [AUTH_CHECK] Usuario actual: ${user?.uid ?? 'null'}");

    if (user != null) {
      print("✅ [AUTH_CHECK] Usuario logueado.");
      try {
        await user
            .reload(); // Asegura datos frescos (especialmente emailVerified)
        final freshUser = _auth.currentUser;
        print(
            "📧 [AUTH_CHECK] Email verificado (post-reload): ${freshUser?.emailVerified}");

        if (freshUser != null && freshUser.emailVerified) {
          print("👍 [AUTH_CHECK] Email verificado.");

          // Guardar información para uso offline
          deviceStorage.write('HasOfflineSession', true);

          // 1. Chequeo en Local Storage (como caché)
          bool surveyCompletedLocally =
              deviceStorage.read('SurveyCompleted') ?? false;
          print(
              "💾 [AUTH_CHECK] Encuesta completada (Local Storage): $surveyCompletedLocally");

          if (surveyCompletedLocally) {
            // Si el caché local dice que está completa, vamos directo al Home.
            print(
                "➡️ [AUTH_CHECK] Redirigiendo a NavigationMenu (Home) - Vía Local Storage");
            TFullScreenLoader.stopLoading(); // Detener loader ANTES de navegar
            Get.offAll(() => const NavigationMenu(),
                binding: HomeBinding(), transition: Transition.upToDown);
          } else {
            // 2. Si el caché local NO dice que está completa:
            print(
                "🤔 [AUTH_CHECK] Caché local no confirma encuesta completada.");

            // --- Punto de Integración Backend (Futuro) ---
            // TODO: Implementar consulta al backend aquí para máxima robustez.
            //       Si el backend dice que SÍ está completa, actualizar caché local y ir a Home.
            //       Si el backend dice que NO (caso raro), ir a SurveyScreen.
            /* ... bloque comentado para backend ... */
            // --- Fin Punto de Integración Backend ---

            // --- Lógica Actual (Basada en Asunción Pre-Registro) ---
            // Si no hay caché local, PERO sabemos que la encuesta es PRE-REGISTRO,
            // entonces *asumimos* que el usuario ya la completó para poder registrarse.
            // Por lo tanto, actualizamos el caché local y lo enviamos al Home.
            print(
                "🔒 [AUTH_CHECK] Asumiendo encuesta completada (pre-registro). Actualizando caché.");
            deviceStorage.write(
                'SurveyCompleted', true); // Actualiza/Crea el caché local
            print(
                "💾 [AUTH_CHECK] Actualizando Local Storage: SurveyCompleted = true");
            print(
                "➡️ [AUTH_CHECK] Redirigiendo a NavigationMenu (Home) - Vía Asunción Pre-Registro");
            TFullScreenLoader.stopLoading(); // Detener loader ANTES de navegar
            Get.offAll(() => const NavigationMenu(),
                binding: HomeBinding(), transition: Transition.upToDown);
            // --- Fin Lógica Actual ---
          }
        } else {
          // Email no verificado
          print("➡️ [AUTH_CHECK] Redirigiendo a VerifyEmailScreen");
          TFullScreenLoader.stopLoading(); // Detener loader ANTES de navegar
          Get.offAll(() => VerifyEmailScreen(email: freshUser?.email),
              transition: Transition.upToDown);
        }
      } catch (e) {
        print("⚠️ [AUTH_CHECK] Error al recargar datos de usuario: $e");

        // En caso de error (sin internet), intentamos usar datos guardados
        if (deviceStorage.read('HasOfflineSession') == true) {
          print(
              "📱 [AUTH_CHECK] Usando información offline tras error de recarga.");
          TFullScreenLoader.stopLoading();
          Get.offAll(() => const NavigationMenu(), binding: HomeBinding());
        } else {
          // No hay datos guardados, intentamos usar los datos actuales de usuario
          if (user.emailVerified) {
            print(
                "📱 [AUTH_CHECK] Usando datos actuales sin recarga (offline).");
            deviceStorage.write('HasOfflineSession', true);
            deviceStorage.write('SurveyCompleted', true);
            TFullScreenLoader.stopLoading();
            Get.offAll(() => const NavigationMenu(), binding: HomeBinding());
          } else {
            // No podemos determinar si el email está verificado, ir a verificación
            print(
                "➡️ [AUTH_CHECK] No se pudo determinar verificación, ir a VerifyEmailScreen");
            TFullScreenLoader.stopLoading();
            Get.offAll(() => VerifyEmailScreen(email: user.email),
                transition: Transition.upToDown);
          }
        }
      }
    } else {
      // Usuario null inesperado - También detener loader si estaba activo
      print(
          "❌ [AUTH_CHECK] Usuario null inesperado. Redirigiendo a WelcomeScreen.");
      TFullScreenLoader.stopLoading(); // Detener loader ANTES de navegar
      screenRedirectToWelcome();
    }
    print("🏁 [AUTH_CHECK] Fin verificación post-login/signup.");
  }

/* --------------------------------------- Email & Password sign-in ------------------------------------------ */

  /// [EmailAuthentication] - SignIn
  Future<UserCredential> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Cuando el login es exitoso, actualizamos el estado offline
      deviceStorage.write('HasOfflineSession', true);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw e;
    } on FirebaseException catch (e) {
      throw e;
    } on FormatException catch (_) {
      rethrow;
    } on PlatformException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('An unexpected error occurred during login.');
    }
  }

  /// [EmailAuthentication] - REGISTER
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (userCredential.user == null) {
        throw 'Failed to create user account. Please try again.';
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    } on FirebaseException catch (e) {
      throw e;
    } on FormatException catch (_) {
      rethrow;
    } on PlatformException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('An unexpected error occurred during registration.');
    }
  }

  /// [EmailVerification] - MAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw e;
    } on FirebaseException catch (e) {
      throw e;
    } on FormatException catch (_) {
      rethrow;
    } on PlatformException catch (e) {
      throw e;
    } catch (e) {
      throw Exception(
          'An unexpected error occurred sending verification email.');
    }
  }

  /// [ReAuthentication] - ReAuthenticate User

  /// [EmailAuthentication] - FORGET PASSWORD

/* --------------------------------------- Federated identity & social sign-in ------------------------------------------ */

  /// [GoogleAuthentication] - GOOGLE

  /// [FacebookAuthentication] - FACEBOOK

/* --------------------------------------- ./end Federated identity & social sign-in ------------------------------------------ */

  /// [LogoutUser] - Valid for any authentication
  Future<void> logout() async {
    try {
      // Limpiar datos de sesión offline
      deviceStorage.remove('HasOfflineSession');

      await FirebaseAuth.instance.signOut();
      screenRedirectToWelcome();
    } on FirebaseAuthException catch (e) {
      throw e;
    } on FirebaseException catch (e) {
      throw e;
    } on FormatException catch (_) {
      rethrow;
    } on PlatformException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('An unexpected error occurred during logout.');
    }
  }

  /// DELETE USER - Remove user Auth and Firestore Account.
}
