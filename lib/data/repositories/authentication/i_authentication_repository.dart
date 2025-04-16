import 'package:firebase_auth/firebase_auth.dart';

/// Interfaz para el repositorio de autenticación
/// Define los métodos necesarios para todas las operaciones de autenticación,
/// independientemente de la implementación
abstract class IAuthenticationRepository {
  /// Obtener el ID del usuario actual
  String? get currentUserId;

  /// Método llamado al iniciar el repositorio
  void onReady();

  /// Verificar el estado actual de autenticación y navegar a la pantalla correspondiente
  void checkAuthStatusAndNavigate();

  /// Redirigir a la pantalla de bienvenida
  void screenRedirectToWelcome();

  /// Iniciar sesión con email y contraseña
  Future<UserCredential> loginWithEmailAndPassword(String email, String password);

  /// Registrar usuario con email y contraseña
  Future<UserCredential> registerWithEmailAndPassword(String email, String password);

  /// Enviar email de verificación
  Future<void> sendEmailVerification();

  /// Cerrar sesión
  Future<void> logout();
} 