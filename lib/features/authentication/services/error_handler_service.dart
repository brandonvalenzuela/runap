import 'package:get/get.dart';
import 'package:runap/utils/popups/loaders.dart';

class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// Muestra un mensaje de error al usuario usando un snackbar personalizado
  void showError({required String title, required String message}) {
    TLoaders.errorSnackBar(title: title, message: message);
  }

  /// Muestra un mensaje de advertencia al usuario
  void showWarning({required String title, required String message}) {
    TLoaders.warningSnackBar(title: title, message: message);
  }

  /// Muestra un mensaje de éxito al usuario
  void showSuccess({required String title, required String message}) {
    TLoaders.successSnackBar(title: title, message: message);
  }

  /// Registra el error en consola (o en un sistema externo si se desea)
  void logError(dynamic error, [StackTrace? stackTrace]) {
    print("‼️----- ERROR CAUGHT -----‼️");
    print("Error Type: [31m${error.runtimeType}[0m");
    print("Error Message: $error");
    if (stackTrace != null) {
      print("Stack Trace:\n$stackTrace");
    }
    print("‼️------------------------‼️");
  }

  /// Traduce excepciones comunes a mensajes amigables
  String getFriendlyMessage(dynamic error) {
    // Aquí puedes personalizar según tus excepciones
    if (error is Exception) {
      return error.toString();
    }
    return "Ha ocurrido un error inesperado. Intenta nuevamente.";
  }
} 