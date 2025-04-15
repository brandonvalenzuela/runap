import 'package:get/get.dart';
import 'package:runap/features/authentication/controllers/signup/signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    // Usar lazyPut para que el controlador se cree solo cuando se necesite por primera vez
    Get.lazyPut<SignupController>(() => SignupController());
  }
}
