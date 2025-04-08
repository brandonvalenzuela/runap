import 'package:get/get.dart';
import 'package:runap/features/dashboard/viewmodels/training_view_model.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Using lazyPut so the ViewModel is created only when it's first needed
    Get.lazyPut<TrainingViewModel>(() => TrainingViewModel());
  }
} 