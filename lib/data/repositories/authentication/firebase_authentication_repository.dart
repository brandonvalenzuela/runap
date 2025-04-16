import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/data/repositories/authentication/i_authentication_repository.dart';
import 'package:runap/features/authentication/screens/signup/verify_email.dart';
import 'package:runap/features/authentication/screens/welcome/welcome_screen.dart';
import 'package:runap/features/dashboard/presentation/manager/binding/home_binding.dart';
import 'package:runap/navigation_menu.dart';
import 'package:runap/utils/constants/text_strings.dart';
import 'package:runap/utils/popups/full_screen_loader.dart';

/// Implementación concreta del repositorio de autenticación usando Firebase
class FirebaseAuthenticationRepository extends GetxController implements IAuthenticationRepository {
  static FirebaseAuthenticationRepository get instance => Get.find();

  // Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  // Called from main.dart on app launch
  @override
  void onReady() {
    FlutterNativeSplash.remove();
    // Escuchar el estado de autenticación inicial
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // No user authenticated -> Welcome Screen
        print("🏁 [AUTH_INIT] No user found. Redirecting to WelcomeScreen...");
        screenRedirectToWelcome();
      } else {
        // User is authenticated, check verification and survey status
        print("🏁 [AUTH_INIT] User found (${user.uid}). Checking status...");
        // IMPORTANTE: Primero verificar si el email está verificado.
        if (user.emailVerified) {
           print("📧 [AUTH_INIT] User email IS verified. Checking survey status...");
           // Si el email está verificado, usar la lógica post-login 
           checkAuthStatusAndNavigate();
        } else {
           print("📧 [AUTH_INIT] User email NOT verified. Redirecting to VerifyEmailScreen...");
           // Si el email no está verificado, enviar a la pantalla de verificación.
           TFullScreenLoader.stopLoading(); 
           Get.offAll(() => VerifyEmailScreen(email: user.email), transition: Transition.upToDown);
        }
      }
    });
  }

  @override
  void screenRedirectToWelcome() {
    print("🏁 [AUTH_REDIRECT] Redirigiendo a WelcomeScreen...");
    Get.offAll(() => const WelcomeScreen());
  }

  @override
  void checkAuthStatusAndNavigate() async {
    print("🏁 [AUTH_CHECK] Verificando estado post-login/signup...");
    final user = _auth.currentUser;
    print("🕵️ [AUTH_CHECK] Usuario actual: ${user?.uid ?? 'null'}");

    if (user != null) {
      print("✅ [AUTH_CHECK] Usuario logueado.");
      await user.reload(); // Asegura datos frescos (especialmente emailVerified)
      final freshUser = _auth.currentUser;
      print("📧 [AUTH_CHECK] Email verificado (post-reload): ${freshUser?.emailVerified}");

      if (freshUser != null && freshUser.emailVerified) {
        print("👍 [AUTH_CHECK] Email verificado.");

        // 1. Chequeo en Local Storage (como caché)
        bool surveyCompletedLocally = deviceStorage.read('SurveyCompleted') ?? false;
        print("💾 [AUTH_CHECK] Encuesta completada (Local Storage): $surveyCompletedLocally");

        if (surveyCompletedLocally) {
          // Si el caché local dice que está completa, vamos directo al Home.
          print("➡️ [AUTH_CHECK] Redirigiendo a NavigationMenu (Home) - Vía Local Storage");
          TFullScreenLoader.stopLoading(); // Detener loader ANTES de navegar
          Get.offAll(() => const NavigationMenu(), binding: HomeBinding(), transition: Transition.upToDown);
        } else {
          // Si no hay caché local, asumimos que el usuario ya completó la encuesta para poder registrarse
          print("🔒 [AUTH_CHECK] Asumiendo encuesta completada (pre-registro). Actualizando caché.");
          deviceStorage.write('SurveyCompleted', true); // Actualiza/Crea el caché local
          print("💾 [AUTH_CHECK] Actualizando Local Storage: SurveyCompleted = true");
          print("➡️ [AUTH_CHECK] Redirigiendo a NavigationMenu (Home) - Vía Asunción Pre-Registro");
          TFullScreenLoader.stopLoading(); // Detener loader ANTES de navegar
          Get.offAll(() => const NavigationMenu(), binding: HomeBinding(), transition: Transition.upToDown);
        }
      } else {
        // Email no verificado
        print("➡️ [AUTH_CHECK] Redirigiendo a VerifyEmailScreen");
        TFullScreenLoader.stopLoading(); // Detener loader ANTES de navegar
        Get.offAll(() => VerifyEmailScreen(email: freshUser?.email), transition: Transition.upToDown);
      }
    } else {
      // Usuario null inesperado - También detener loader si estaba activo
      print("❌ [AUTH_CHECK] Usuario null inesperado. Redirigiendo a WelcomeScreen.");
      TFullScreenLoader.stopLoading(); // Detener loader ANTES de navegar
      screenRedirectToWelcome(); 
    }
    print("🏁 [AUTH_CHECK] Fin verificación post-login/signup.");
  }

  @override
  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e;
    } on FirebaseException catch (e) {
      throw e;
    } on FormatException catch (_) {
      rethrow;
    } on PlatformException catch (e) {
      throw e;
    } catch (e) {
      throw Exception(TTexts.error);
    }
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (userCredential.user == null) {
        throw TTexts.error;
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
      throw Exception(TTexts.error);
    }
  }

  @override
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
      throw Exception(TTexts.error);
    }
  }

  @override
  Future<void> logout() async {
    try {
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
      throw Exception(TTexts.error);
    }
  }
} 