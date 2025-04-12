import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:runap/utils/constants/colors.dart'; // Assuming TColors is here

// --- Data Models (Placeholders) ---
// TODO: Replace with your actual data models
class WeightEntry {
  final DateTime date;
  final double weight;
  WeightEntry({required this.date, required this.weight});
}

class CalorieDataPoint {
  final DateTime date;
  final double calories;
  CalorieDataPoint({required this.date, required this.calories});
}

class MacroData {
  final double fatPercent;
  final double proteinPercent;
  final double carbsPercent;
  final double fiberPercent; // Optional
  final double fatGrams;
  final double proteinGrams;
  final double carbsGrams;
  final double fiberGrams; // Optional

  MacroData({
    this.fatPercent = 0,
    this.proteinPercent = 0,
    this.carbsPercent = 0,
    this.fiberPercent = 0,
    this.fatGrams = 0,
    this.proteinGrams = 0,
    this.carbsGrams = 0,
    this.fiberGrams = 0,
  });
}


class ProgressController extends GetxController {
  static ProgressController get instance => Get.find();

  // --- State Variables ---
  final RxInt selectedWeightTimePeriod = 1.obs; // 0: 7d, 1: 30d, 2: 90d
  final RxInt selectedCaloriePeriod = 1.obs;
  final RxInt selectedMacroBreakdownPeriod = 1.obs;
  final RxInt selectedMacroAveragePeriod = 1.obs;
  // Loading states remain for future async implementation
  final RxBool isLoadingWeight = false.obs; // Start as false for default data
  final RxBool isLoadingCalories = false.obs;
  final RxBool isLoadingMacroBreakdown = false.obs;
  final RxBool isLoadingMacroAverage = false.obs;
  final RxString weightError = ''.obs;
  final RxString nutritionError = ''.obs;

  // --- Data Variables (Maps for different time periods) ---
  final RxMap<int, List<WeightEntry>> weightHistoryData = {
    0: <WeightEntry>[ // 7 days
      WeightEntry(date: DateTime.now().subtract(const Duration(days: 6)), weight: 84.8),
      WeightEntry(date: DateTime.now().subtract(const Duration(days: 4)), weight: 84.5),
      WeightEntry(date: DateTime.now().subtract(const Duration(days: 2)), weight: 84.2),
      WeightEntry(date: DateTime.now().subtract(const Duration(days: 0)), weight: 84.0),
    ].obs,
    1: <WeightEntry>[ // 30 days (Original default)
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 29)), weight: 85.0),
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 21)), weight: 84.5),
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 15)), weight: 84.0),
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 7)), weight: 83.0),
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 0)), weight: 84.0),
    ].obs,
    2: <WeightEntry>[ // 90 days
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 88)), weight: 88.0),
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 60)), weight: 86.5),
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 35)), weight: 85.0),
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 10)), weight: 83.5),
       WeightEntry(date: DateTime.now().subtract(const Duration(days: 0)), weight: 84.0),
    ].obs
  }.obs;

  final RxMap<int, List<CalorieDataPoint>> calorieHistoryData = {
    0: <CalorieDataPoint>[ // 7 days
      CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 6)), calories: 1950),
      CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 4)), calories: 2050),
      CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 2)), calories: 2000),
      CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 0)), calories: 2100),
    ].obs,
    1: <CalorieDataPoint>[ // 30 days (Original default)
      CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 29)), calories: 1800),
      CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 21)), calories: 2100),
      CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 15)), calories: 1950),
      CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 7)), calories: 2055),
      CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 0)), calories: 2000),
    ].obs,
    2: <CalorieDataPoint>[ // 90 days
       CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 88)), calories: 2200),
       CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 60)), calories: 2000),
       CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 35)), calories: 1900),
       CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 10)), calories: 2150),
       CalorieDataPoint(date: DateTime.now().subtract(const Duration(days: 0)), calories: 2000),
    ].obs
  }.obs;

  final RxMap<int, MacroData> macroPeriodData = {
    0: MacroData( // 7 days
      fatPercent: 22, proteinPercent: 55, carbsPercent: 23, fiberPercent: 0,
      fatGrams: 25, proteinGrams: 110, carbsGrams: 130, fiberGrams: 18,
    ),
    1: MacroData( // 30 days (Original default)
      fatPercent: 19, proteinPercent: 63, carbsPercent: 18, fiberPercent: 0,
      fatGrams: 20, proteinGrams: 128, carbsGrams: 143, fiberGrams: 20,
    ),
    2: MacroData( // 90 days
      fatPercent: 25, proteinPercent: 50, carbsPercent: 25, fiberPercent: 0,
      fatGrams: 30, proteinGrams: 100, carbsGrams: 150, fiberGrams: 25,
    ),
  }.obs;

  // --- Static Goal & Start Data (Could also be fetched) ---
  final RxDouble startWeight = 85.0.obs;
  final RxDouble currentWeight = 84.0.obs; // Initialize based on last 7d default
  final RxDouble goalWeight = 75.0.obs;
  final RxDouble goalCalories = 2055.0.obs;
  final Rx<MacroData> goalMacroData = MacroData( // Example goals
      fatPercent: 27, proteinPercent: 25, carbsPercent: 45, fiberPercent: 3,
      fatGrams: 57, proteinGrams: 128, carbsGrams: 231, fiberGrams: 31,
  ).obs;

  // --- Colors (Could be moved to constants or theme) ---
  final Color fatColor = Colors.yellow.shade700;
  final Color proteinColor = Colors.pink.shade300;
  final Color carbsColor = Colors.blue.shade300;
  final Color fiberColor = Colors.brown.shade300;


  @override
  void onInit() {
    super.onInit();
    // Initial data is already loaded into the maps
    // Update currentWeight based on the initially selected period's data
     _updateCurrentWeight();
  }

  // --- Data Fetching Methods (Now just update state, no real fetching yet) ---
  // TODO: Replace these with actual async fetching logic later.

  Future<void> fetchWeightData(int periodIndex) async {
    // isLoadingWeight.value = true; // Uncomment when async
    weightError.value = '';
    print("Selecting weight data for period: $periodIndex");
    // await Future.delayed(const Duration(seconds: 1)); // Simulate delay if needed
    // In a real scenario, fetch data for periodIndex and update weightHistoryData[periodIndex]
    // For now, data is already loaded, just ensure UI reacts to period change
    selectedWeightTimePeriod.value = periodIndex;
    _updateCurrentWeight();
    // isLoadingWeight.value = false; // Uncomment when async
  }

  Future<void> fetchCalorieData(int periodIndex) async {
    // isLoadingCalories.value = true; // Uncomment when async
    nutritionError.value = '';
    print("Selecting CALORIE data for period: $periodIndex");
    // await Future.delayed(const Duration(seconds: 1));
    // In a real scenario, fetch data for periodIndex and update calorieHistoryData[periodIndex]
    selectedCaloriePeriod.value = periodIndex;
    // isLoadingCalories.value = false; // Uncomment when async
  }

  Future<void> fetchMacroBreakdownData(int periodIndex) async {
    // isLoadingMacroBreakdown.value = true; // Uncomment when async
    nutritionError.value = '';
    print("Selecting MACRO BREAKDOWN data for period: $periodIndex");
    // await Future.delayed(const Duration(seconds: 1));
    // In a real scenario, fetch data for periodIndex and update macroPeriodData[periodIndex]
    selectedMacroBreakdownPeriod.value = periodIndex;
    // isLoadingMacroBreakdown.value = false; // Uncomment when async
  }

  Future<void> fetchMacroAverageData(int periodIndex) async {
    // isLoadingMacroAverage.value = true; // Uncomment when async
    nutritionError.value = '';
    print("Selecting MACRO AVERAGE data for period: $periodIndex");
    // await Future.delayed(const Duration(seconds: 1));
    // In a real scenario, fetch data for periodIndex and update macroPeriodData[periodIndex]
    selectedMacroAveragePeriod.value = periodIndex;
    // isLoadingMacroAverage.value = false; // Uncomment when async
  }

  // --- Helper to update current weight based on selected period ---
  void _updateCurrentWeight() {
     final currentHistory = weightHistoryData[selectedWeightTimePeriod.value] ?? [];
     if (currentHistory.isNotEmpty) {
       currentWeight.value = currentHistory.last.weight;
     }
     // Handle case where history for period is empty if necessary
  }

  // --- UI Interaction Methods --- // (Change methods now just update selected index)
  void changeWeightPeriod(int index) {
    if (selectedWeightTimePeriod.value != index) {
      // selectedWeightTimePeriod.value = index; // Set inside fetchWeightData
      fetchWeightData(index); // Fetch handles setting the index now
    }
  }
  void changeCaloriePeriod(int index) {
    if (selectedCaloriePeriod.value != index) {
      // selectedCaloriePeriod.value = index; // Set inside fetchCalorieData
      fetchCalorieData(index);
    }
  }
  void changeMacroBreakdownPeriod(int index) {
    if (selectedMacroBreakdownPeriod.value != index) {
      // selectedMacroBreakdownPeriod.value = index; // Set inside fetchMacroBreakdownData
      fetchMacroBreakdownData(index);
    }
  }
  void changeMacroAveragePeriod(int index) {
    if (selectedMacroAveragePeriod.value != index) {
      // selectedMacroAveragePeriod.value = index; // Set inside fetchMacroAverageData
      fetchMacroAverageData(index);
    }
  }

  // --- Add/Update Weight Entry Methods (Adjust to modify the map) ---
  Future<void> addWeightEntry(double newWeight) async {
    // TODO: Implement logic to save the new weight entry to your backend/database
    print("Adding weight: $newWeight");
    final newEntry = WeightEntry(date: DateTime.now(), weight: newWeight);
    
    // Add to the list for the currently selected period
    final currentList = weightHistoryData[selectedWeightTimePeriod.value];
    if (currentList != null) {
        currentList.add(newEntry);
        currentList.sort((a, b) => a.date.compareTo(b.date));
        _updateCurrentWeight();
        print("Weight added locally to period ${selectedWeightTimePeriod.value}.");
    } else {
        print("Error: No weight list found for period ${selectedWeightTimePeriod.value}");
    }
  }

  Future<void> updateWeightEntry(DateTime entryDate, double newWeight) async {
    // TODO: Implement logic to update the weight entry in your backend/database
    print("Updating weight for $entryDate to $newWeight in period ${selectedWeightTimePeriod.value}");
    final currentList = weightHistoryData[selectedWeightTimePeriod.value];
    if (currentList != null) {
        final index = currentList.indexWhere((entry) => entry.date.year == entryDate.year && entry.date.month == entryDate.month && entry.date.day == entryDate.day);
        if (index != -1) {
          currentList[index] = WeightEntry(date: entryDate, weight: newWeight);
          currentList.sort((a, b) => a.date.compareTo(b.date));
          _updateCurrentWeight();
          print("Weight updated locally.");
          // weightHistoryData.refresh(); // Forzar refresco del mapa si la UI no actualiza
        } else {
          print("Error: Could not find weight entry for $entryDate to update.");
          Get.snackbar('Error', 'Could not find the entry to update.', snackPosition: SnackPosition.BOTTOM);
        }
    } else {
       print("Error: No weight list found for period ${selectedWeightTimePeriod.value}");
    }
  }

  // --- Chart Data Preparation (Getters now select data based on state) ---
  List<WeightEntry> get currentWeightHistory => weightHistoryData[selectedWeightTimePeriod.value] ?? [];
  List<CalorieDataPoint> get currentCalorieHistory => calorieHistoryData[selectedCaloriePeriod.value] ?? [];
  MacroData get currentMacroBreakdownData => macroPeriodData[selectedMacroBreakdownPeriod.value] ?? MacroData();
  MacroData get currentMacroAverageData => macroPeriodData[selectedMacroAveragePeriod.value] ?? MacroData();

  List<FlSpot> getWeightChartSpots() {
    final history = currentWeightHistory;
    if (history.isEmpty) return [];
    return history.asMap().entries.map((entry) {
       // Use days ago for X-axis relative to the latest entry
       final daysAgo = history.last.date.difference(entry.value.date).inDays;
       return FlSpot(daysAgo.toDouble(), entry.value.weight);
    }).toList().reversed.toList(); // Reverse to have oldest date at X=0 (left)
  }

  List<FlSpot> getCalorieChartSpots() {
     final history = currentCalorieHistory;
     if (history.isEmpty) return [];
      return history.asMap().entries.map((entry) {
       final daysAgo = history.last.date.difference(entry.value.date).inDays;
       return FlSpot(daysAgo.toDouble(), entry.value.calories);
    }).toList().reversed.toList(); // Reverse
  }

  // --- Helper to get color based on macro type ---
  Color getMacroColor(String macro) {
     switch (macro.toLowerCase()) {
        case 'fat': return fatColor;
        case 'protein': return proteinColor;
        case 'carbs': return carbsColor;
        case 'fiber': return fiberColor;
        default: return Colors.grey;
      }
  }
} 