import 'package:get/get.dart';
import 'package:runap/features/authentication/controllers/signup/signup_controller.dart';
import 'package:runap/features/dashboard/presentation/manager/dashboard_manager.dart';
import 'package:runap/features/dashboard/presentation/manager/home_controller.dart';
import 'package:runap/features/dashboard/presentation/manager/training_view_model.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/utils/helpers/network_manager.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkManager());

    // Utilities & Services
    Get.put(NetworkManager(), permanent: true);

    // ViewModels & Controllers
    Get.put(HomeController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(DashboardManager(), permanent: true);
    Get.lazyPut<TrainingViewModel>(() => TrainingViewModel());
    Get.lazyPut<SignupController>(() => SignupController());
  }
}
