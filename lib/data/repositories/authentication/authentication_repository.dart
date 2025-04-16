import 'package:get/get.dart';
import 'package:runap/data/repositories/authentication/firebase_authentication_repository.dart';
import 'package:runap/data/repositories/authentication/i_authentication_repository.dart';

/// Clase principal para gestionar la autenticación de usuarios
/// Utiliza el patrón Repository para desacoplar la implementación concreta
class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();
  
  // Repositorio concreto utilizado (inyectado)
  final IAuthenticationRepository _authRepo = Get.find<FirebaseAuthenticationRepository>();
  
  /// Getter para obtener el UID del usuario actual de forma segura
  String? get currentUserId => _authRepo.currentUserId;
  
  @override
  void onReady() {
    // Delega la inicialización al repositorio concreto
    _authRepo.onReady();
  }
  
  /// Función para redirigir SIEMPRE a WelcomeScreen al inicio de la app si no hay sesión.
  void screenRedirectToWelcome() {
    _authRepo.screenRedirectToWelcome();
  }
  
  /// Función para verificar estado DESPUÉS de Login/Signup y redirigir.
  void checkAuthStatusAndNavigate() {
    _authRepo.checkAuthStatusAndNavigate();
  }
  
  /// Login con email y contraseña
  Future<dynamic> loginWithEmailAndPassword(String email, String password) async {
    return await _authRepo.loginWithEmailAndPassword(email, password);
  }
  
  /// Registro con email y contraseña
  Future<dynamic> registerWithEmailAndPassword(String email, String password) async {
    return await _authRepo.registerWithEmailAndPassword(email, password);
  }
  
  /// Envío de email de verificación
  Future<void> sendEmailVerification() async {
    await _authRepo.sendEmailVerification();
  }
  
  /// Cierre de sesión
  Future<void> logout() async {
    await _authRepo.logout();
  }
  
  // Otros métodos que podrían añadirse en el futuro:
  // - ReAuthentication
  // - Forget Password
  // - Google Authentication
  // - Facebook Authentication
  // - Delete User Account
}
