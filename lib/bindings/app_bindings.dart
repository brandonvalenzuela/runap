import 'package:get/get.dart';
import 'package:runap/features/authentication/controllers/signup/signup_controller.dart';
import 'package:runap/features/dashboard/presentation/manager/dashboard_manager.dart';
import 'package:runap/features/dashboard/presentation/manager/home_controller.dart';
import 'package:runap/features/dashboard/presentation/manager/training_view_model.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/utils/helpers/network_manager.dart';
import 'package:runap/features/map/controller/location_permission_controller.dart';
import 'package:runap/features/map/controller/workout_controller.dart';
import 'package:runap/features/map/controller/map_controller.dart';
import 'package:runap/features/map/controller/goal_controller.dart';
import 'package:runap/common/widgets/notification/connectivity_controller.dart';
import 'package:runap/common/widgets/notification/notification_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Utilities & Services
    Get.put(NetworkManager(), permanent: true);
    
    // Controladores de notificación
    Get.put(NotificationController(), permanent: true);
    Get.put(ConnectivityController(), permanent: true);

    // ViewModels & Controllers
    Get.put(LocationPermissionController(), permanent: true);
    Get.put(HomeController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.lazyPut<DashboardManager>(() => DashboardManager());
    Get.lazyPut<TrainingViewModel>(() => TrainingViewModel());
    Get.lazyPut<SignupController>(() => SignupController());
    Get.lazyPut<WorkoutController>(() => WorkoutController());
    Get.lazyPut<MapController>(() => MapController());
    Get.lazyPut<GoalController>(() => GoalController());
  }
}
