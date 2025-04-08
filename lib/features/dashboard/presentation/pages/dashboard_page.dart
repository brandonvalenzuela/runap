import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:runap/features/dashboard/presentation/manager/dashboard_manager.dart';
import 'package:runap/features/dashboard/presentation/widgets/session_card.dart';
import 'package:runap/features/dashboard/presentation/widgets/stats_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardManager _manager = Get.find<DashboardManager>();

  @override
  void initState() {
    super.initState();
    // Cargar los datos cuando se inicia la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manager.loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Entrenamiento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _manager.loadDashboardData(forceRefresh: true);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_manager.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_manager.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${_manager.error}'),
                ElevatedButton(
                  onPressed: () => _manager.loadDashboardData(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final trainingData = _manager.trainingData;
        if (trainingData == null) {
          return const Center(child: Text('No hay datos disponibles'));
        }

        return RefreshIndicator(
          onRefresh: () => _manager.loadDashboardData(forceRefresh: true),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              StatsCard(dashboard: trainingData.dashboard),
              const SizedBox(height: 16),
              const Text(
                'Sesiones de esta semana',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...trainingData.dashboard.nextWeekSessions.map((session) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SessionCard(
                    session: session,
                    onToggleCompletion: () {
                      _manager.toggleSessionCompletion(session);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
} 