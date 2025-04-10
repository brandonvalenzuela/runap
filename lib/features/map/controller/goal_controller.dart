import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/features/map/services/map_workout_data_provider.dart';
import 'workout_controller.dart'; // To set the goal on the workout

class GoalController extends GetxController {
  final Logger logger = Logger(printer: PrettyPrinter(methodCount: 0));

  // Dependencias
  final WorkoutDatabaseService _databaseService = WorkoutDatabaseService();
  final WorkoutController _workoutController = Get.find<WorkoutController>();

  // Estado Observable
  final RxList<WorkoutGoal> availableGoals = <WorkoutGoal>[].obs;
  final RxBool showGoalSelector = false.obs;
  final RxBool isLoadingGoals = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadGoals();
    logger.i("GoalController inicializado.");
  }

  Future<void> _loadGoals() async {
    try {
      isLoadingGoals.value = true;
      final goals = await _databaseService.getAvailableWorkoutGoals();
      availableGoals.assignAll(goals);
      logger.i("Objetivos cargados: ${goals.length}");
    } catch (e) {
      logger.e('Error al cargar objetivos: $e');
      // Consider showing a snackbar or error message
      Get.snackbar('Error', 'No se pudieron cargar los objetivos.');
    } finally {
      isLoadingGoals.value = false;
    }
  }

  void toggleGoalSelector() {
    showGoalSelector.value = !showGoalSelector.value;
    if (showGoalSelector.value) {
       logger.d("Mostrando selector de objetivos");
    } else {
       logger.d("Ocultando selector de objetivos");
    }
  }

  void selectGoal(WorkoutGoal goal) {
    logger.d("Objetivo seleccionado: ${goal.formattedTargetDistance} km en ${goal.targetTimeMinutes} min");
    // Delegar la asignación del objetivo al WorkoutController
    _workoutController.workoutData.update((val) {
      val?.setGoal(goal);
    });
    showGoalSelector.value = false; // Ocultar selector después de seleccionar
  }

  // Método para refrescar manualmente si es necesario
  Future<void> refreshGoals() async {
     await _loadGoals();
  }
} 