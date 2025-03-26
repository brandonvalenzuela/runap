import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/features/dashboard/viewmodels/training_view_model.dart';
import 'package:runap/features/map/controller/map_controller.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/features/map/models/workout_data.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  final WorkoutGoal? initialWorkoutGoal;
  final Session? sessionToUpdate;

  const MapScreen({
    super.key,
    this.initialWorkoutGoal,
    this.sessionToUpdate,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapWorkoutController _controller;
  WorkoutData _workoutData = WorkoutData();
  bool _showGoalSelector = false;
  List<WorkoutGoal> _availableGoals = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Verificar si la sesión debería ser accesible (SOLO HOY)
    if (widget.sessionToUpdate != null) {
      final now = DateTime.now();
      final isToday = now.year == widget.sessionToUpdate!.sessionDate.year &&
          now.month == widget.sessionToUpdate!.sessionDate.month &&
          now.day == widget.sessionToUpdate!.sessionDate.day;

      final canAccess = isToday &&
          !widget.sessionToUpdate!.workoutName
              .toLowerCase()
              .contains('descanso');

      if (!canAccess) {
        // No debería acceder a este entrenamiento, regresar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Solo puedes iniciar entrenamientos programados para hoy'),
              backgroundColor: Colors.red,
            ),
          );
          Get.back(); // Regresar a la pantalla anterior
        });
        return;
      }
    }

    // Inicializar el controlador
    _controller = MapWorkoutController(
      onWorkoutDataChanged: (data) {
        setState(() {
          _workoutData = data;
        });
      },
    );

    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    await _controller.initialize();

    // Si recibimos un objetivo inicial (desde una sesión de entrenamiento)
    if (widget.initialWorkoutGoal != null) {
      _controller.setWorkoutGoal(widget.initialWorkoutGoal!);
    }

    // Cargar los objetivos disponibles
    _availableGoals = await _controller.getAvailableGoals();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStartStopPress() {
    if (_workoutData.isWorkoutActive) {
      _stopWorkout();
    } else {
      _startWorkout();
    }
  }

  void _startWorkout() {
    _controller.startWorkout();
  }

  Future<void> _stopWorkout() async {
    setState(() {
      _isSaving = true;
    });

    // Detener el entrenamiento y guardar los datos
    _controller.stopWorkout();

    // Si hay una sesión a actualizar (viniendo del dashboard)
    if (widget.sessionToUpdate != null) {
      try {
        // Actualizar la sesión como completada
        final viewModel =
            Provider.of<TrainingViewModel>(context, listen: false);
        await viewModel.toggleSessionCompletion(widget.sessionToUpdate!);

        // Mostrar un diálogo de éxito
        await _showCompletionDialog();

        // Volver al dashboard
        Get.back();
      } catch (e) {
        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el entrenamiento: $e')),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _showCompletionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¡Entrenamiento completado!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Has completado tu entrenamiento de hoy.'),
                SizedBox(height: 8),
                Text(
                  'Distancia: ${(_workoutData.distanceMeters / 1000).toStringAsFixed(2)} km',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tiempo: ${_controller.getFormattedElapsedTime()}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Volver al Dashboard'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleGoalSelector() {
    setState(() {
      _showGoalSelector = !_showGoalSelector;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sessionToUpdate != null
              ? widget.sessionToUpdate!.workoutName
              : 'Entrenamiento',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.flag),
            onPressed:
                _workoutData.isWorkoutActive ? null : _toggleGoalSelector,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          _buildMap(),

          // Panel de información inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInfoPanel(),
          ),

          // Selector de objetivos (condicional)
          if (_showGoalSelector) _buildGoalSelector(),

          // Indicador de carga
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Indicador de guardado
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Guardando entrenamiento...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _workoutData.currentPosition ?? LatLng(20.651464, -103.392958),
        zoom: 17.0,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      polylines: _workoutData.polylines,
      onMapCreated: (GoogleMapController controller) {
        _controller.setMapController(controller);
      },
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Información del objetivo (si hay uno establecido)
          if (_workoutData.goal != null) ...[
            Text(
              'Objetivo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricTile(
                  icon: Icons.straighten,
                  value: '${_workoutData.goal!.targetDistanceKm} km',
                  label: 'Distancia',
                ),
                _buildMetricTile(
                  icon: Icons.timer,
                  value: '${_workoutData.goal!.targetTimeMinutes} min',
                  label: 'Tiempo',
                ),
                if (_workoutData.goal!.startTime != null) _buildProgressTile(),
              ],
            ),
            SizedBox(height: 16),
          ],

          // Métricas actuales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricTile(
                icon: Icons.straighten,
                value:
                    '${(_workoutData.distanceMeters / 1000).toStringAsFixed(2)} km',
                label: 'Distancia',
              ),
              _buildMetricTile(
                icon: Icons.timer,
                value: _controller.getFormattedElapsedTime(),
                label: 'Tiempo',
              ),
              _buildMetricTile(
                icon: Icons.speed,
                value: _workoutData.isWorkoutActive
                    ? '${_workoutData.currentPace.toStringAsFixed(2)} km/h'
                    : '0.00 km/h',
                label: 'Ritmo',
              ),
            ],
          ),
          SizedBox(height: 16),

          // Botón de inicio/parada
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onStartStopPress,
              style: ElevatedButton.styleFrom(
                backgroundColor: _workoutData.isWorkoutActive
                    ? Colors.red
                    : TColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _workoutData.isWorkoutActive ? 'DETENER' : 'INICIAR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: TColors.primaryColor),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTile() {
    // Calcular el progreso
    final elapsedSeconds = _controller.getElapsedTimeSeconds();
    final targetSeconds = _workoutData.goal!.targetTimeMinutes * 60;
    final progress = targetSeconds > 0 ? elapsedSeconds / targetSeconds : 0.0;

    return Column(
      children: [
        Icon(Icons.check_circle, color: TColors.primaryColor),
        SizedBox(height: 4),
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 5,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(TColors.primaryColor),
          ),
        ),
        Text(
          'Progreso',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSelector() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.all(TSizes.defaultSpace),
          padding: EdgeInsets.all(TSizes.defaultSpace),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona un objetivo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ..._availableGoals.map((goal) => _buildGoalOption(goal)),
              SizedBox(height: 16),
              TextButton(
                onPressed: _toggleGoalSelector,
                child: Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption(WorkoutGoal goal) {
    final isSelected =
        _workoutData.goal?.targetDistanceKm == goal.targetDistanceKm &&
            _workoutData.goal?.targetTimeMinutes == goal.targetTimeMinutes;

    return GestureDetector(
      onTap: () {
        _controller.setWorkoutGoal(goal);
        _toggleGoalSelector();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? TColors.primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? TColors.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? TColors.primaryColor : Colors.grey,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${goal.targetDistanceKm} km en ${goal.targetTimeMinutes} min',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Ritmo: ${(goal.targetDistanceKm / (goal.targetTimeMinutes / 60)).toStringAsFixed(2)} km/h',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
