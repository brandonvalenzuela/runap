import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';

class TrainingData {
  final Dashboard dashboard;

  TrainingData({required this.dashboard});

  factory TrainingData.fromJson(Map<String, dynamic> json) {
    return TrainingData(
      dashboard: Dashboard.fromJson(json['dashboard'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dashboard': dashboard.toJson(),
    };
  }
}
