import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/features/dashboard/domain/entities/training_data.dart';

abstract class DashboardRepository {
  Future<TrainingData> getDashboardData({bool forceRefresh = false, int userId = 1});
  Future<void> updateSession(Session session);
  Future<void> saveLocalDashboardData(TrainingData data);
  Future<TrainingData?> getLocalDashboardData();
} 