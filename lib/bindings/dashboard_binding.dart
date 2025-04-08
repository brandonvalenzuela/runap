import 'package:get/get.dart';
import 'package:runap/features/dashboard/presentation/manager/dashboard_manager.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardManager>(() => DashboardManager());
  }
} 