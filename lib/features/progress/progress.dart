import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:runap/common/screens/placeholder/placeholder_screen.dart';
import 'package:runap/common/widgets/icons/t_circular_image.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/features/personalization/screens/settings/settings.dart'; // Para navegar a Settings
import 'package:runap/features/personalization/screens/profile/profile.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:runap/features/progress/controllers/progress_controller.dart';
import 'package:runap/utils/device/device_utility.dart'; 
import 'package:shimmer/shimmer.dart'; // Importar el paquete shimmer

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final progressController = Get.put(ProgressController());

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerBgColor = isDarkMode ? TColors.darkerGrey : TColors.secondaryColor;
    final defaultBgColor = isDarkMode ? TColors.colorBlack : Colors.white;
    final chartGridColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final chartLineColor = isDarkMode ? TColors.primaryColor : TColors.primaryColor;
    final chartBackgroundColor = isDarkMode ? TColors.darkerGrey : TColors.lightGrey.withAlpha(128);
    final sectionBgColor = isDarkMode ? TColors.darkerGrey : TColors.lightGrey.withAlpha(100);
    final textColor = isDarkMode ? TColors.light : TColors.colorBlack;

    const userGoalText = 'Lose weight';
    const dailyCalories = '2055 Cal / d';
    const startWeight = '85.0 kg';
    const currentWeight = '85.0 kg';
    const goalWeight = '75.0 kg';

    final List<Map<String, dynamic>> savedWeights = [
      {'weight': '85.0 kg', 'date': DateTime(2025, 4, 9)},
    ];

    final List<FlSpot> chartSpots = [
       FlSpot(0, 85),   // Day 0 (Apr 9)
       FlSpot(1, 84.5), // Day 1 (Apr 10 - example)
       FlSpot(3, 84),   // Day 3 (Apr 12 - example)
       FlSpot(5, 83),   // Day 5 (Apr 14 - example)
       FlSpot(7, 83.5), // Day 7 (Apr 16 - example)
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: defaultBgColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                expandedHeight: 140,
                backgroundColor: headerBgColor,
                actions: [
                  IconButton(
                    icon: const Icon(Iconsax.setting_2, color: TColors.colorBlack),
                    onPressed: () {
                      TDiviceUtility.vibrateMedium();// Vibración ligera
                      Get.to(() => const SettingsScreen(), transition: Transition.rightToLeft);
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    color: headerBgColor,
                    padding: const EdgeInsets.only(
                      right: TSizes.defaultSpace,
                      left: TSizes.defaultSpace,
                      bottom: TSizes.defaultSpace
      ),
      child: Obx(() => Row(
        children: [
          GestureDetector(
            onTap: () {
              TDiviceUtility.vibrateMedium();
              Get.to(() => const ProfileScreen(), transition: Transition.rightToLeft);
            },
            child: TCircularImage(
              image: userController.profilePicture.isNotEmpty
                ? userController.profilePicture
                : TImages.userIcon, 
              width: 80,
              height: 80,
              isNetworkImage: userController.profilePicture.isNotEmpty,
              backgroundColor: TColors.lightContainer,
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: GestureDetector(
              onTap: () {
                TDiviceUtility.vibrateMedium();
                Get.to(() => const ProfileScreen(), transition: Transition.rightToLeft);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userController.fullName, 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                                  userGoalText, 
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: TSizes.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs / 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(TSizes.borderRadiusXl),
                    ),
                    child: Text(
                                    dailyCalories,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
                      ],
                    )),
                  ),
                ),
                bottom: TabBar(
                  indicatorColor: TColors.colorBlack,
                  labelColor: TColors.colorBlack,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 5.0,
                  indicator: _StadiumIndicator(
                    indicatorWeight: 5.0,
                    color: TColors.colorBlack,
                  ),
                  tabs: const [
                    Tab(text: 'Weight'),
                    Tab(text: 'Nutrition'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildWeightTabContent(context, progressController, chartGridColor, chartLineColor, chartBackgroundColor, textColor),
              _buildNutritionTabContent(context, progressController, sectionBgColor, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightTabContent(BuildContext context, ProgressController controller, Color gridColor, Color lineColor, Color bgColor, Color textColor) {
     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
     final buttonColor = isDarkMode ? TColors.light : TColors.colorBlack;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Obx(() {
        final history = controller.currentWeightHistory;
        final spots = controller.getWeightChartSpots();

        return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                _buildWeightMetric(context, '${controller.startWeight.value.toStringAsFixed(1)} kg', 'Start weight'),
                _buildWeightMetric(context, '${controller.currentWeight.value.toStringAsFixed(1)} kg', 'Current weight'),
                _buildWeightMetric(context, '${controller.goalWeight.value.toStringAsFixed(1)} kg', 'Goal weight'),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  TDiviceUtility.vibrateMedium();
                  _showAddWeightDialog(context, controller, null);
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                  foregroundColor: isDarkMode ? TColors.colorBlack : TColors.light,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusXl)),
                  padding: const EdgeInsets.symmetric(vertical: TSizes.smx),
                  side: BorderSide.none,
              ),
              child: Text('Add a weight entry', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDarkMode ? TColors.colorBlack : TColors.light, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections * 1.5),

          Text('Weight', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: TSizes.spaceBtwItems),
            SizedBox(
            height: 200,
              child: controller.isLoadingWeight.value
                 ? _buildChartShimmerPlaceholder(context, 200)
                 : controller.weightError.value.isNotEmpty 
                    ? Center(child: Text('Error loading chart', style: TextStyle(color: Colors.red.shade300))) 
                    : Container(
            padding: const EdgeInsets.only(right: TSizes.md, top: TSizes.md, bottom: TSizes.xs),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
                        child: _buildWeightLineChartWidget(context, spots, history, controller, gridColor, lineColor, textColor, bgColor)
                      ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections * 1.5),

            Text('Weights saved', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: TSizes.spaceBtwItems),
            Column(
               children: history.map((entry) => _buildWeightHistoryItem(context, entry)).toList(),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        );
      }),
    );
  }

  Widget _buildWeightMetric(BuildContext context, String value, String label) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? TColors.light : TColors.colorBlack;
    final labelColor = Colors.grey;
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: TSizes.xs / 2),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: labelColor)),
      ],
    );
  }

  Widget _buildWeightHistoryItem(BuildContext context, WeightEntry entry) {
    final formattedDate = '${entry.date.month}/${entry.date.day}/${entry.date.year}';
    final textColor = Theme.of(context).brightness == Brightness.dark ? TColors.light : TColors.colorBlack;
    final dateColor = Colors.grey;

    return InkWell(
      onTap: () {
        TDiviceUtility.vibrateMedium();
        _showAddWeightDialog(context, Get.find<ProgressController>(), entry);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${entry.weight.toStringAsFixed(1)} kg', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500, color: textColor)),
            Row(
              children: [
                Text(formattedDate, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: dateColor)),
                const SizedBox(width: TSizes.xs),
                Icon(Iconsax.arrow_right_3, size: TSizes.iconSm, color: dateColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTabContent(BuildContext context, ProgressController controller, Color sectionBgColor, Color textColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonTextColor = isDarkMode ? TColors.colorBlack : TColors.light;
    final buttonBgColor = isDarkMode ? TColors.light : TColors.colorBlack;

    final Color fatColor = controller.fatColor;
    final Color proteinColor = controller.proteinColor;
    final Color carbsColor = controller.carbsColor;
    final Color fiberColor = controller.fiberColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Obx(() {
        final calorieSpots = controller.getCalorieChartSpots();
        final currentBreakdownMacros = controller.currentMacroBreakdownData;
        final currentAverageMacros = controller.currentMacroAverageData;
        final goalMacros = controller.goalMacroData.value;
        final goalCalories = controller.goalCalories.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: sectionBgColor,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reach your goals faster with Premium',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems / 2),
                  ElevatedButton(
                    onPressed: () {
                      TDiviceUtility.vibrateMedium();
                      Get.to(() => const PlaceholderScreen(title: 'Get More Info'));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: buttonBgColor,
                      foregroundColor: buttonTextColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusXl)),
                      padding: const EdgeInsets.symmetric(vertical: TSizes.smx),
                      side: BorderSide.none,
                    ),
                    child: const Text('Get more info', style: TextStyle(fontWeight: FontWeight.bold)),
                    
                  ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            Text('Goal (Cal)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor)),
            const SizedBox(height: TSizes.spaceBtwItems),
            Center(child: _buildTimeToggleButtons(context, controller.selectedCaloriePeriod, controller.changeCaloriePeriod)),
            const SizedBox(height: TSizes.spaceBtwItems),
            SizedBox(
              height: 200,
              child: controller.isLoadingCalories.value
                ? _buildChartShimmerPlaceholder(context, 200)
                : controller.nutritionError.value.isNotEmpty
                  ? Center(child: Text('Error loading chart', style: TextStyle(color: Colors.red.shade300)))
                  : _buildCalorieLineChart(context, calorieSpots, sectionBgColor, textColor, goalCalories),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            Text('Macronutrient breakdown (%)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor)),
            const SizedBox(height: TSizes.spaceBtwItems),
            Center(child: _buildTimeToggleButtons(context, controller.selectedMacroBreakdownPeriod, controller.changeMacroBreakdownPeriod)),
            const SizedBox(height: TSizes.spaceBtwItems),
            SizedBox(
              height: 250,
              child: controller.isLoadingMacroBreakdown.value
                ? _buildChartShimmerPlaceholder(context, 250)
                : controller.nutritionError.value.isNotEmpty
                  ? Center(child: Text('Error loading chart', style: TextStyle(color: Colors.red.shade300)))
                  : _buildMacroPieChart(context, currentBreakdownMacros, goalMacros, controller),
            ),
            const SizedBox(height: TSizes.sm),
            _buildMacroLegend(context, controller),
            const SizedBox(height: TSizes.spaceBtwSections),

            Text('Macronutrient average (g)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor)),
            const SizedBox(height: TSizes.spaceBtwItems),
            Center(child: _buildTimeToggleButtons(context, controller.selectedMacroAveragePeriod, controller.changeMacroAveragePeriod)),
            const SizedBox(height: TSizes.spaceBtwItems),
            SizedBox(
              height: 200,
              child: controller.isLoadingMacroAverage.value
                ? _buildChartShimmerPlaceholder(context, 200)
                : controller.nutritionError.value.isNotEmpty
                  ? Center(child: Text('Error loading chart', style: TextStyle(color: Colors.red.shade300)))
                  : _buildMacroBarChart(context, currentAverageMacros, goalMacros, controller, textColor),
            ),
            const SizedBox(height: TSizes.sm),
            _buildMacroLegend(context, controller),
            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        );
      }),
    );
  }

  Widget _buildCalorieLineChart(BuildContext context, List<FlSpot> spots, Color bgColor, Color textColor, double goalCalories) {
    final chartGridColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300;
    final chartLineColor = TColors.primaryColor;

    // Calculate axis limits directly
    final double minX = 0;
    final double maxX = spots.isNotEmpty ? spots.map((s) => s.x).reduce(math.max) : 10;
    final double minY = spots.isEmpty
        ? goalCalories * 0.8
        : () {
            final dataMin = spots.map((s) => s.y).reduce(math.min);
            final range = spots.map((s) => s.y).reduce(math.max) - dataMin;
            final padding = (range * 0.1).clamp(50.0, 300.0);
            return math.min(dataMin, goalCalories) - padding;
          }();
    final double maxY = spots.isEmpty
        ? goalCalories * 1.2
        : () {
            final dataMax = spots.map((s) => s.y).reduce(math.max);
            final range = dataMax - spots.map((s) => s.y).reduce(math.min);
            final padding = (range * 0.1).clamp(50.0, 300.0);
            return math.max(dataMax, goalCalories) + padding;
          }();

    return LineChart(
              LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
          horizontalInterval: ((maxY - minY) / 5).clamp(50.0, 1000.0),
          verticalInterval: (maxX / 5).clamp(1.0, 100.0),
          getDrawingHorizontalLine: (value) => FlLine(color: chartGridColor, strokeWidth: 0.5),
          getDrawingVerticalLine: (value) => FlLine(color: chartGridColor, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
              interval: (maxX / 5).clamp(1.0, 100.0),
                      getTitlesWidget: (double value, TitleMeta meta) {
                return Text('D${value.toInt()}', style: TextStyle(color: textColor, fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
              interval: ((maxY - minY) / 5).clamp(50.0, 1000.0),
                      getTitlesWidget: (double value, TitleMeta meta) {
                return Text('${value.toInt()}', style: TextStyle(color: textColor, fontSize: 10));
                      },
                      reservedSize: 35,
                    ),
                  ),
                ),
        borderData: FlBorderData(show: true, border: Border.all(color: chartGridColor)),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
            color: chartLineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goalCalories,
              color: textColor.withAlpha(204),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 2),
                style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                labelResolver: (line) => '${line.y.toInt()} kcal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroPieChart(BuildContext context, MacroData current, MacroData goal, ProgressController controller) {
    final List<PieChartSectionData> consumptionSections = [
        if (current.fatPercent > 0) PieChartSectionData(
            color: controller.fatColor,
            value: current.fatPercent,
            title: '${current.fatPercent.toInt()}%',
            radius: 100.0,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TColors.colorBlack),
            titlePositionPercentageOffset: 0.85,
        ),
        if (current.proteinPercent > 0) PieChartSectionData(
            color: controller.proteinColor,
            value: current.proteinPercent,
            title: '${current.proteinPercent.toInt()}%',
            radius: 100.0,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TColors.white),
            titlePositionPercentageOffset: 0.85,
        ),
       if (current.carbsPercent > 0) PieChartSectionData(
            color: controller.carbsColor,
            value: current.carbsPercent,
            title: '${current.carbsPercent.toInt()}%',
            radius: 100.0,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TColors.white),
            titlePositionPercentageOffset: 0.85,
        ),
        if (current.fiberPercent > 0) PieChartSectionData(
            color: controller.fiberColor,
            value: current.fiberPercent,
            title: '${current.fiberPercent.toInt()}%',
            radius: 100.0,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TColors.white),
            titlePositionPercentageOffset: 0.85,
        ),
    ];
    final double goalRingOuterRadius = 60.0 - 5; 
    final double goalRingInnerRadius = goalRingOuterRadius - 15.0;
    final List<PieChartSectionData> goalSections = [
         if(goal.fatPercent > 0) PieChartSectionData(
            color: controller.fatColor.withAlpha(128),
            value: goal.fatPercent,
            title: '', radius: goalRingOuterRadius,
            badgePositionPercentageOffset: -1.5,
        ),
         if(goal.proteinPercent > 0) PieChartSectionData(
            color: controller.proteinColor.withAlpha(128),
            value: goal.proteinPercent,
            title: '', radius: goalRingOuterRadius,
            badgePositionPercentageOffset: -1.5,
        ),
         if(goal.carbsPercent > 0) PieChartSectionData(
            color: controller.carbsColor.withAlpha(128),
            value: goal.carbsPercent,
            title: '', radius: goalRingOuterRadius,
            badgePositionPercentageOffset: -1.5,
        ),
         if(goal.fiberPercent > 0) PieChartSectionData(
            color: controller.fiberColor.withAlpha(128),
            value: goal.fiberPercent,
            title: '', radius: goalRingOuterRadius,
            badgePositionPercentageOffset: -1.5,
        ),
    ];

    final PieChartData pieChartData = PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) { /* TODO */ },
      ),
      borderData: FlBorderData(show: false),
      sectionsSpace: 2,
      centerSpaceRadius: goalRingInnerRadius - 10,
      sections: [...consumptionSections, ...goalSections],
      centerSpaceColor: Colors.transparent,
    );

    final PieChart pieChart = PieChart(pieChartData);
    return Stack(
      alignment: Alignment.center,
      children: [
        pieChart,
        Text(
          "My goal",
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMacroBarChart(BuildContext context, MacroData current, MacroData goal, ProgressController controller, Color axisTextColor) {
    final chartGridColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300;
    const double barWidth = 22;

    final Map<String, double> macroAverages = {
      'fat': current.fatGrams,
      'protein': current.proteinGrams,
      'carbs': current.carbsGrams,
      'fiber': current.fiberGrams,
    };
    final Map<String, double> macroGoals = {
      'fat': goal.fatGrams,
      'protein': goal.proteinGrams,
      'carbs': goal.carbsGrams,
      'fiber': goal.fiberGrams,
    };

    final double maxY = [ ...macroAverages.values, ...macroGoals.values, 150.0 ].reduce(math.max) * 1.1;

    final List<BarChartGroupData> barGroups = [];
    int x = 0;
    macroAverages.forEach((key, avgValue) {
      if (avgValue <= 0 && (macroGoals[key] ?? 0) <= 0) return;
      final goalValue = macroGoals[key] ?? 0;
      final color = controller.getMacroColor(key);

      barGroups.add(
        BarChartGroupData(
          x: x,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: avgValue,
              color: color,
              width: barWidth,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          ],
        ),
      );
      x++;
    });

    final Map<double, String> goalValueMap = {};
    macroGoals.forEach((key, value) {
      if (value > 0) goalValueMap[value] = '${value.toInt()}g';
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 5).clamp(10, 500),
          getDrawingHorizontalLine: (value) {
            if (goalValueMap.containsKey(value.roundToDouble())) {
                return FlLine(color: axisTextColor.withAlpha(128), strokeWidth: 1, dashArray: [4, 4]);
            }
            return FlLine(color: chartGridColor, strokeWidth: 0.5, dashArray: [5, 5]);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY / 5).clamp(10, 500),
              getTitlesWidget: (double value, TitleMeta meta) {
                 String label = goalValueMap[value.roundToDouble()] ?? '';
                 if (label.isNotEmpty) {
                    return Text(label, style: TextStyle(color: axisTextColor, fontSize: 10));
                 }
                 return const Text('');
              },
              reservedSize: 35,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
             tooltipPadding: const EdgeInsets.all(8),
             tooltipMargin: 8,
             getTooltipColor: (group) => TColors.secondaryColor,
             getTooltipItem: (group, groupIndex, rod, rodIndex) {
               String macroName = macroAverages.keys.elementAt(group.x);
               return BarTooltipItem(
                 '$macroName\n${rod.toY.round()} g',
                 const TextStyle(color: TColors.white, fontWeight: FontWeight.bold),
               );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) { /* TODO */ },
        ),
      ),
    );
  }

  Widget _buildTimeToggleButtons(BuildContext context, RxInt selectedPeriodObs, Function(int) onChanged) {
    final selectedIndex = selectedPeriodObs.value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors based on theme and selection state
    final Color selectedFillColor = isDarkMode ? TColors.light.withAlpha(230) : TColors.colorBlack;
    final Color selectedTextColor = isDarkMode ? TColors.colorBlack : TColors.light;
    final Color unselectedTextColor = isDarkMode ? TColors.light.withAlpha(179) : TColors.darkGrey;
    final Color borderColor = isDarkMode ? TColors.darkGrey : Colors.grey.shade300;

    // Create the list of boolean selection states
    final List<bool> isSelected = List.generate(3, (index) => index == selectedIndex);

    return ToggleButtons(
      isSelected: isSelected,
      onPressed: (int index) {
        TDiviceUtility.vibrateMedium();// Vibración al cambiar
        onChanged(index);
      },
      borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      borderWidth: 1.5,
      borderColor: borderColor,
      selectedBorderColor: selectedFillColor,
      fillColor: selectedFillColor,
      color: unselectedTextColor,
      selectedColor: selectedTextColor,
      constraints: const BoxConstraints(minHeight: 40.0, minWidth: 80.0),
      children: const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: TSizes.sm),
          child: Text('7 days', style: TextStyle(fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: TSizes.sm),
          child: Text('30 days', style: TextStyle(fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: TSizes.sm),
          child: Text('90 days', style: TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildMacroLegend(BuildContext context, ProgressController controller) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? TColors.light : TColors.colorBlack;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(context, controller.fatColor, 'fat', textColor),
        _buildLegendItem(context, controller.proteinColor, 'protein', textColor),
        _buildLegendItem(context, controller.carbsColor, 'carbs', textColor),
        _buildLegendItem(context, controller.fiberColor, 'fiber', textColor),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
          children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: TSizes.xs / 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: textColor)),
      ],
    );
  }

  void _showAddWeightDialog(BuildContext context, ProgressController controller, WeightEntry? entry) {
    final TextEditingController weightController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final bool isEditing = entry != null;

    // Pre-fill if editing
    if (isEditing) {
      weightController.text = entry.weight.toStringAsFixed(1);
    }

    Get.dialog(
      AlertDialog(
        title: Text(isEditing ? 'Edit Weight Entry' : 'Add Weight Entry'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Weight (kg)', hintText: 'e.g., 84.5'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight <= 0) {
                return 'Please enter a valid positive weight';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              TDiviceUtility.vibrateMedium();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                TDiviceUtility.vibrateMedium();
                final newWeight = double.parse(weightController.text);
                if (isEditing) {
                  // Call controller method to UPDATE the entry
                  controller.updateWeightEntry(entry.date, newWeight);
                } else {
                  controller.addWeightEntry(newWeight); // Call controller method to ADD
                }
                Get.back(); // Close dialog
              }
            },
            
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  // --- WIDGET PARA EL SHIMMER PLACEHOLDER DE LAS GRÁFICAS ---
  Widget _buildChartShimmerPlaceholder(BuildContext context, double height) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: baseColor, // Es necesario un color de fondo para que el shimmer funcione
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
      ),
    );
  }

  // --- Extracted Weight Line Chart Builder ---
  Widget _buildWeightLineChartWidget(BuildContext context, List<FlSpot> spots, List<WeightEntry> history, ProgressController controller, Color gridColor, Color lineColor, Color textColor, Color bgColor) {
    // Calculate axis limits directly
    final double minX = 0;
    final double maxX = spots.isNotEmpty ? spots.map((s) => s.x).reduce(math.max) : 10;
    final double minY = spots.isEmpty 
        ? controller.goalWeight.value - 5 
        : () {
            final dataMin = spots.map((s) => s.y).reduce(math.min);
            final range = spots.map((s) => s.y).reduce(math.max) - dataMin;
            final padding = (range * 0.1).clamp(2.0, 10.0);
            return math.min(dataMin, controller.goalWeight.value) - padding;
          }();
    final double maxY = spots.isEmpty
        ? controller.goalWeight.value + 5
        : () {
            final dataMax = spots.map((s) => s.y).reduce(math.max);
            final range = dataMax - spots.map((s) => s.y).reduce(math.min);
            final padding = (range * 0.1).clamp(2.0, 10.0);
            return math.max(dataMax, controller.goalWeight.value) + padding;
          }();

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: ((maxY - minY) / 5).clamp(1.0, 100.0),
          verticalInterval: (maxX / 5).clamp(1.0, 100.0),
          getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 0.5),
          getDrawingVerticalLine: (value) => FlLine(color: gridColor, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (maxX / 5).clamp(1.0, 100.0),
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < history.length && (index % ((maxX / 5).clamp(1.0, 100.0)).round() == 0)) {
                  final date = history[index].date;
                  return Text('${date.day}/${date.month}', style: TextStyle(color: textColor, fontSize: 10));
                } 
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: ((controller.goalWeight.value * 1.2 - controller.goalWeight.value * 0.8) / 5).clamp(1, 100),
              getTitlesWidget: (double value, TitleMeta meta) {
                  return Text('${value.toInt()}kg', style: TextStyle(color: textColor, fontSize: 10));
              },
              reservedSize: 35,
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: gridColor)),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(colors: [lineColor, lineColor.withAlpha(228)]),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [lineColor.withAlpha(77), lineColor])),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: controller.goalWeight.value,
              color: textColor.withAlpha(204),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 2),
                style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                labelResolver: (line) => 'Goal ${line.y.toStringAsFixed(1)} kg',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StadiumIndicator extends Decoration {
  final double indicatorWeight;
  final Color color;

  const _StadiumIndicator({
    required this.indicatorWeight,
    required this.color,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _StadiumPainter(this, onChanged);
  }
}

class _StadiumPainter extends BoxPainter {
  final _StadiumIndicator decoration;

  _StadiumPainter(this.decoration, VoidCallback? onChanged) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration.size != null);
    final Rect rect = offset & Size(configuration.size!.width, decoration.indicatorWeight);
    final double dy = configuration.size!.height - decoration.indicatorWeight;
    final Rect bottomAlignedRect = rect.shift(Offset(0, dy));

    final Paint paint = Paint();
    paint.color = decoration.color;
    paint.style = PaintingStyle.fill;

    final RRect rrect = RRect.fromRectAndRadius(
      bottomAlignedRect,
      Radius.circular(decoration.indicatorWeight / 2),
    );
    canvas.drawRRect(rrect, paint);
  }
}


