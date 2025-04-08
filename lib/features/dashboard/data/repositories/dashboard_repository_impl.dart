import 'package:runap/features/dashboard/data/datasources/training_service.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/features/dashboard/domain/entities/training_data.dart';
import 'package:runap/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final TrainingService _trainingService;

  DashboardRepositoryImpl({TrainingService? trainingService})
      : _trainingService = trainingService ?? TrainingService();

  @override
  Future<TrainingData> getDashboardData({bool forceRefresh = false, int userId = 1}) {
    return _trainingService.getDashboardData(forceRefresh: forceRefresh, userId: userId);
  }

  @override
  Future<void> updateSession(Session session) {
    return _trainingService.updateSession(session);
  }

  @override
  Future<void> saveLocalDashboardData(TrainingData data) {
    return _trainingService.saveLocalDashboardData(data);
  }

  @override
  Future<TrainingData?> getLocalDashboardData() {
    return _trainingService.getLocalDashboardData();
  }
} 