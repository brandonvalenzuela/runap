import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/features/authentication/screens/welcome/welcome_screen.dart';
import 'package:runap/utils/exceptions/exceptions.dart';
import 'package:runap/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:runap/utils/exceptions/firebase_exceptions.dart';
import 'package:runap/utils/exceptions/format_exceptions.dart';
import 'package:runap/features/dashboard/presentation/manager/binding/home_binding.dart';
import 'package:runap/features/survey/screens/survey_screen.dart';
import 'package:runap/features/survey/bindings/survey_binding.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  // Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  // Called from main.dart on app launch
  @override
  void onReady() {
    // Remove the native splash screen
    FlutterNativeSplash.remove();
    // Redirigir SIEMPRE a WelcomeScreen después del splash inicial.
    // La WelcomeScreen decidirá si ir a Login o a Onboarding.
    screenRedirect();
  }

  /// Function to Show Relevant Screen (AHORA SOLO VA A WELCOME)
  screenRedirect() async {
    // Ya no necesitamos verificar currentUser o flags aquí.
    // La lógica se traslada a los botones de WelcomeScreen y 
    // a la lógica de finalización de Survey/Login/Signup.
    Get.offAll(() => const WelcomeScreen());
  }

/* --------------------------------------- Email & Password sign-in ------------------------------------------ */

  /// [EmailAuthentication] - SignIn
  Future<UserCredential> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TExceptions(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
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
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TExceptions(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again'; //const TGenericException();
    }
  }

  /// [EmailVerification] - MAIL VERIFICATION
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TExceptions(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
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
      await FirebaseAuth.instance.signOut();
      
      // No eliminar credenciales guardadas al cerrar sesión
      // Si el usuario tiene rememberMe desactivado, ya se habrán eliminado en login_controller
      
      Get.offAll(() => const WelcomeScreen(), transition: Transition.upToDown);
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TExceptions(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// DELETE USER - Remove user Auth and Firestore Account.
}
