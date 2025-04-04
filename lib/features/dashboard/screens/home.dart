import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:math';
import 'package:runap/common/widgets/training/training_card.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/features/dashboard/viewmodels/training_view_model.dart';
import 'package:runap/features/map/screen/map.dart';
import 'package:runap/features/personalization/controllers/user_controller.dart';
import 'package:runap/features/personalization/screens/profile/profile.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Animaciones para el AppBar
  late Animation<double> _fadeAppBarAnimation;
  late Animation<Offset> _slideAvatarAnimation;
  late Animation<double> _fadeUserInfoAnimation;
  late Animation<double> _rotateMenuAnimation;
  // Animaciones para el contenido principal
  late Animation<double> _fadeHeaderAnimation;
  late Animation<Offset> _slideHeaderAnimation;
  late Animation<double> _fadeProgressAnimation;
  late Animation<double> _fadeTitleAnimation;
  late List<Animation<double>> _animations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Animaciones para el AppBar
    _fadeAppBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _slideAvatarAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutQuint),
      ),
    );

    _fadeUserInfoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.3, curve: Curves.easeOut),
      ),
    );

    _rotateMenuAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.35, curve: Curves.elasticOut),
      ),
    );

    // Animación para el encabezado
    _fadeHeaderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.4, curve: Curves.easeOut),
      ),
    );

    _slideHeaderAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.4, curve: Curves.easeOutQuint),
      ),
    );

    // Animación para la barra de progreso
    _fadeProgressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.35, curve: Curves.easeOut),
      ),
    );

    // Animación para el título de sección
    _fadeTitleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.4, curve: Curves.easeOut),
      ),
    );

    // Crear animaciones para cada tarjeta con efecto de desvanecimiento más suave
    _animations = List.generate(10, (index) {
      final double startValue = 0.4 + (index * 0.05);
      final double endValue = min(startValue + 0.2, 1.0);

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            startValue,
            endValue,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _slideAnimations = List.generate(10, (index) {
      final double startValue = 0.4 + (index * 0.05);
      final double endValue = min(startValue + 0.2, 1.0);

      return Tween<Offset>(
        begin: const Offset(0.3, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            startValue,
            endValue,
            curve: Curves.easeOutQuad,
          ),
        ),
      );
    });

    // Iniciar la animación
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TrainingViewModel>()) {
      Get.put(TrainingViewModel(), permanent: true);
    }
    
    // Obtener el controlador de usuario
    final userController = Get.find<UserController>();

    final today = DateTime.now();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: FadeTransition(
          opacity: _fadeAppBarAnimation,
          child: AppBar(
            title: Row(
              children: <Widget>[
                // Avatar con animación
                SlideTransition(
                  position: _slideAvatarAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(right: TSizes.spaceBtwItems),
                    child: Hero(
                      tag: 'profile-avatar',
                      child: Obx(() => CircleAvatar(
                        backgroundImage: userController.isLoading.value || userController.profilePicture.isEmpty
                            ? AssetImage(TImages.userIcon) as ImageProvider
                            : NetworkImage(userController.profilePicture),
                        radius: 25,
                      )),
                    ),
                  ),
                ),
                // Información de usuario con animación - usando datos reales
                FadeTransition(
                  opacity: _fadeUserInfoAnimation,
                  child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        userController.isLoading.value 
                            ? 'Cargando...' 
                            : userController.fullName,
                        style: TextStyle(color: Colors.black),
                      ),
                      Text(
                        userController.isLoading.value 
                            ? 'Cargando email...' 
                            : userController.email,
                        style: TextStyle(color: TColors.darkGrey, fontSize: 12),
                      ),
                    ],
                  )),
                ),
              ],
            ),
            actions: <Widget>[
              // Botón de menú con animación
              RotationTransition(
                turns: _rotateMenuAnimation,
                child: IconButton(
                  icon: Icon(Icons.menu, color: Colors.black),
                  onPressed: () => Get.to(() => const ProfileScreen(), transition: Transition.upToDown),
                ),
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: GetBuilder<TrainingViewModel>(
        builder: (viewModel) {
          final todaySessions = viewModel
                  .trainingData?.dashboard.nextWeekSessions
                  .where((session) => isSameDay(session.sessionDate, today))
                  .toList() ??
              [];

          if (viewModel.status == LoadingStatus.loading &&
              viewModel.trainingData == null) {
            return const Center(child: CircularProgressIndicator());
          } else if (viewModel.status == LoadingStatus.error) {
            return _buildErrorView(context, viewModel);
          } else if (viewModel.trainingData != null) {
            return _buildHomeContent(context, viewModel);
          } else {
            return const Center(
                child: Text('No hay datos de entrenamiento disponibles'));
          }
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, TrainingViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error al cargar los datos de entrenamiento'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.loadDashboardData(forceRefresh: true),
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, TrainingViewModel viewModel) {
    final dashboard = viewModel.trainingData!.dashboard;
    List<Session> sessions = List.from(dashboard.nextWeekSessions);
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No hay sesiones programadas para esta semana'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.loadDashboardData(forceRefresh: true),
              child: Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con información de entrenamiento - con animación
        SlideTransition(
          position: _slideHeaderAnimation,
          child: FadeTransition(
            opacity: _fadeHeaderAnimation,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: TSizes.defaultSpace,
                  right: TSizes.spaceBtwItems,
                  left: TSizes.spaceBtwItems),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutSine,
                builder: (context, value, child) {
                  return Container(
                    padding: const EdgeInsets.all(TSizes.md),
                    decoration: BoxDecoration(
                      color: TColors.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05 * value),
                          blurRadius: 15 * value,
                          offset: Offset(0, 5 * value),
                          spreadRadius: 3 * value,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tipo de carrera y semanas restantes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.directions_run,
                                    color: TColors.primaryColor),
                                const SizedBox(width: TSizes.sm),
                                Text(
                                  dashboard.raceType,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: TColors.primaryColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${dashboard.weeksToRace} semanas',
                                style: TextStyle(
                                    color: TColors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TSizes.sm),

                        // Ritmo objetivo y tiempo meta
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoItem(context, 'Ritmo objetivo:',
                                dashboard.targetPace),
                            _buildInfoItem(
                                context, 'Tiempo meta:', dashboard.goalTime),
                          ],
                        ),
                        const SizedBox(height: TSizes.sm),

                        // Barra de progreso con animación propia
                        FadeTransition(
                          opacity: _fadeProgressAnimation,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                                begin: 0.0,
                                end: dashboard.completionRate / 100),
                            duration: const Duration(milliseconds: 1800),
                            curve: Curves.easeOutQuad,
                            builder: (context, value, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: value,
                                    minHeight: 8,
                                    backgroundColor: TColors.grey,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        TColors.primaryColor),
                                  ),
                                  const SizedBox(height: TSizes.xs),
                                  Text(
                                    '${dashboard.completedSessions} de ${dashboard.totalSessions} sesiones completadas (${dashboard.completionRate}%)',
                                    style: TextStyle(
                                        fontSize: 12, color: TColors.darkGrey),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Título de sección con animación
        FadeTransition(
          opacity: _fadeTitleAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.3, 0.4, curve: Curves.easeOut),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: TSizes.spaceBtwItems),
              child: Row(
                children: [
                  Text(
                    "Próximos entrenamientos",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Iconsax.map_1, size: 20),
                    onPressed: () => Get.to(() => MapScreen(), transition: Transition.upToDown),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lista de sesiones con animaciones
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: TSizes.spaceBtwItems),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isPast = session.sessionDate.isBefore(DateTime.now());
              final isToday = isSameDay(session.sessionDate, DateTime.now());

              return SlideTransition(
                position: index < _slideAnimations.length
                    ? _slideAnimations[index]
                    : _slideAnimations.last,
                child: FadeTransition(
                  opacity: index < _animations.length
                      ? _animations[index]
                      : _animations.last,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutSine,
                    builder: (context, value, child) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: TSizes.sm),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08 * value),
                              blurRadius: 15 * value,
                              offset: Offset(0, 5 * value),
                              spreadRadius: 2 * value,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: TSizes.sm,
                          ),
                          child: TrainingCard(
                            session: session,
                            showBorder: true,
                            isPast: isPast,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Función auxiliar para formatear fechas
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Widget para mostrar elementos de información
  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: TColors.darkGrey,
          ),
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Añadir estos métodos a la clase HomeScreen
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool isBeforeToday(DateTime date) {
    final now = DateTime.now();
    // Solo comparar la fecha, ignorando la hora
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nowOnly = DateTime(now.year, now.month, now.day);
    return dateOnly.isBefore(nowOnly);
  }
}
