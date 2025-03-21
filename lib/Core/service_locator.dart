import 'package:get_it/get_it.dart';
import 'package:runap/features/dashboard/controllers/training_service.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator() {
  // Registramos el servicio como un singleton
  serviceLocator
      .registerLazySingleton<TrainingService>(() => TrainingService());
}
