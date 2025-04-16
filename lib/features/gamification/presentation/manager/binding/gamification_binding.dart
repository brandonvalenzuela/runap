import 'package:get/get.dart';
import 'package:runap/data/repositories/gamification/gamification_repository.dart';
import 'package:runap/features/gamification/presentation/manager/gamification_view_model.dart';

class GamificationBinding extends Bindings {
  @override
  void dependencies() {
    // Repositorio
    Get.lazyPut<GamificationRepository>(() => GamificationRepository());
    
    // ViewModel
    Get.lazyPut<GamificationViewModel>(() => GamificationViewModel());
  }
} 