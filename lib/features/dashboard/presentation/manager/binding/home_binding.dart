import 'package:get/get.dart';
import 'package:runap/features/dashboard/presentation/manager/training_view_model.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Cambiar a Get.put para asegurar que la instancia exista antes de que initState la busque.
    Get.put<TrainingViewModel>(TrainingViewModel());
  }
} 