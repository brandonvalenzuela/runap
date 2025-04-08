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
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/common/widgets/loaders/skeleton_loader.dart';
import 'package:runap/common/widgets/training/skeleton_training_card.dart';
import 'package:runap/common/widgets/headers/user_profile_header.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:collection/collection.dart';
import 'package:runap/features/dashboard/widgets/date_header.dart';
import 'package:intl/intl.dart';

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

  // Constantes para las alturas estimadas
  static const double _estimatedHeaderHeight = 60.0;
  static const double _estimatedCardHeight = 118.0;
  static const double _dashboardHeaderHeight = 150.0;
  static const double _upcomingTitleHeight = 50.0;

  // Formateadores de fecha
  final _dayFormatter = DateFormat('d', 'es_ES');
  final _monthFormatter = DateFormat('MMM', 'es_ES');
  final _weekdayFormatter = DateFormat('EEEE', 'es_ES');

  // Constantes de animación
  static const Duration _appBarAnimationDuration = Duration(milliseconds: 2500);
  static const Duration _headerAnimationDuration = Duration(milliseconds: 900);
  static const Duration _progressAnimationDuration = Duration(milliseconds: 1800);
  static const Duration _listItemAnimationDuration = Duration(milliseconds: 400);
  static const Duration _cardAnimationDuration = Duration(milliseconds: 500);

  // Constantes de estilo
  static const double _cardBorderRadius = 16.0;
  static const double _cardShadowOpacity = 0.05;
  static const double _cardShadowBlur = 15.0;
  static const double _cardShadowSpread = 3.0;
  static const double _cardShadowOffset = 5.0;
  static const double _listItemShadowOpacity = 0.2;
  static const double _listItemShadowBlur = 15.0;
  static const double _listItemShadowSpread = 2.0;
  static const double _listItemShadowOffset = 5.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _appBarAnimationDuration,
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

    // Iniciar la animación
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Session> _getCurrentWeekSessions(List<Session> allSessions) {
    final now = DateTime.now();
    // Calcular inicio de semana (Lunes)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); 
    final startOfWeekDateOnly = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    // Calcular fin de semana (Domingo)
    final endOfWeek = now.add(Duration(days: DateTime.daysPerWeek - now.weekday));
    final endOfWeekDateOnly = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);

    return allSessions.where((session) {
      final sessionDateOnly = DateTime(session.sessionDate.year, session.sessionDate.month, session.sessionDate.day);
      return !sessionDateOnly.isBefore(startOfWeekDateOnly) && !sessionDateOnly.isAfter(endOfWeekDateOnly);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el controlador de usuario
    final userController = Get.find<UserController>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: FadeTransition(
          opacity: _fadeAppBarAnimation,
          child: AppBar(
            title: SlideTransition(
              position: _slideAvatarAnimation,
              child: FadeTransition(
                opacity: _fadeUserInfoAnimation,
                child: UserProfileHeader(
                  onAvatarTap: () => Get.to(() => const ProfileScreen(),
                      transition: Transition.upToDown),
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: GetBuilder<TrainingViewModel>(
        init: TrainingViewModel(),
        builder: (viewModel) {
          if (viewModel.status == LoadingStatus.loading &&
              viewModel.trainingData == null) {
            return _buildSkeletonList(context);
          } else if (viewModel.status == LoadingStatus.error) {
            return _buildErrorView(context, viewModel);
          } else if (viewModel.trainingData != null &&
              viewModel.trainingData!.dashboard.nextWeekSessions.isNotEmpty) {
            
            final currentWeekSessions = _getCurrentWeekSessions(
              viewModel.trainingData!.dashboard.nextWeekSessions
            );
            
            if (currentWeekSessions.isNotEmpty) {
              return _buildHomeContent(context, viewModel, currentWeekSessions);
            } else {
              return const Center(
                child: Text('No hay entrenamientos programados para esta semana.'),
              );
            }
          } else {
            return const Center(
              child: Text('No hay entrenamientos programados.'),
            );
          }
        },
      ),
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    // Estimación de la altura combinada de un header + una tarjeta (aproximado)
    final estimatedGroupHeight = _estimatedHeaderHeight + 
        TSizes.spaceBtwSections * 0.8 + 
        TSizes.spaceBtwItems + 
        _estimatedCardHeight;

    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight;
    final paddingTop = MediaQuery.of(context).padding.top;
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    
    final availableHeight = screenHeight - 
        appBarHeight - 
        paddingTop - 
        paddingBottom - 
        _dashboardHeaderHeight - 
        _upcomingTitleHeight;

    // Calcular cuántos grupos (header + card) caben
    final groupCount = max(1, (availableHeight / estimatedGroupHeight).ceil());
    // El itemCount será el doble porque cada grupo tiene un header y una card
    final itemCount = groupCount * 2; 

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.spaceBtwItems),
      itemCount: itemCount, 
      itemBuilder: (context, index) {
        // Alternar entre skeleton de header y skeleton de card
        if (index % 2 == 0) {
          // Es un índice par, mostrar skeleton de header
          return const SkeletonDashboardDateHeader();
        } else {
          // Es un índice impar, mostrar skeleton de card
          return const SkeletonTrainingCard();
        }
      },
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

  Widget _buildHomeContent(BuildContext context, TrainingViewModel viewModel, List<Session> sessions) {
    final dashboard = viewModel.trainingData!.dashboard;
    // No es necesario verificar si sessions está vacía aquí porque ya se hizo en el builder principal

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDashboardHeader(context, viewModel),
        _buildUpcomingSessionsTitle(context),
        _buildSessionsList(context, sessions),
      ],
    );
  }

  Widget _buildDashboardHeader(BuildContext context, TrainingViewModel viewModel) {
    final dashboard = viewModel.trainingData!.dashboard;
    
    return SlideTransition(
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
            duration: _headerAnimationDuration,
            curve: Curves.easeOutSine,
            builder: (context, value, child) {
              // Skeleton para el Header si viewModel está cargando
              if (viewModel.status == LoadingStatus.loading) {
                return _buildHeaderSkeleton(context);
              }
              // Contenido real del Header
              return Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: TColors.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(_cardBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_cardShadowOpacity * value),
                      blurRadius: _cardShadowBlur * value,
                      offset: Offset(0, _cardShadowOffset * value),
                      spreadRadius: _cardShadowSpread * value,
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
                        duration: _progressAnimationDuration,
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
    );
  }

  Widget _buildUpcomingSessionsTitle(BuildContext context) {
    return FadeTransition(
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
                "Entrenamientos de la semana",
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
    );
  }

  Widget _buildSessionsList(BuildContext context, List<Session> sessions) {
    // Ordenar sesiones por fecha (asegurarse de que estén ordenadas)
    sessions.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    // Agrupar sesiones por día (ignorando la hora)
    final groupedSessions = groupBy<Session, DateTime>(
      sessions,
      (session) => DateTime(session.sessionDate.year, session.sessionDate.month, session.sessionDate.day),
    );

    // Crear la lista de widgets (headers y cards)
    List<Widget> listItems = [];
    int animationIndex = 0; // Índice para la animación escalonada

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    groupedSessions.forEach((date, sessionsOnDate) {
      // Determinar etiqueta: "Hoy", "Mañana" o vacía
      String label = '';
      if (date == today) {
        label = 'Hoy';
      } else if (date == tomorrow) {
        label = 'Mañana';
      }

      // Añadir el Header para este día
      listItems.add(
        AnimationConfiguration.staggeredList(
          position: animationIndex++,
          duration: _listItemAnimationDuration,
          child: SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(
              child: DashboardDateHeader(
                day: _dayFormatter.format(date),
                month: _monthFormatter.format(date).replaceAll('.', ''),
                weekday: _weekdayFormatter.format(date).capitalizeFirst ?? _weekdayFormatter.format(date),
                label: label,
              ),
            ),
          ),
        )
      );

      // Añadir las TrainingCards para este día
      for (var session in sessionsOnDate) {
        final isPast = session.sessionDate.isBefore(DateTime.now()); // Considerar hora aquí
         final isTodaySession = isSameDay(session.sessionDate, DateTime.now()); // Ya teníamos esta función

        listItems.add(
          AnimationConfiguration.staggeredList(
            position: animationIndex++,
            duration: _cardAnimationDuration,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: TSizes.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_cardBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((_listItemShadowOpacity * 255).round()),
                        blurRadius: _listItemShadowBlur,
                        offset: Offset(0, _listItemShadowOffset),
                        spreadRadius: _listItemShadowSpread,
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
                ),
              ),
            ),
          )
        );
      }
    });

    return Expanded(
      child: AnimationLimiter(
        child: ListView.builder(
          padding: EdgeInsets.zero, // El padding ahora está en los headers/cards
          itemCount: listItems.length,
          itemBuilder: (context, index) {
            return Padding( // Añadir padding horizontal aquí
               padding: const EdgeInsets.symmetric(horizontal: TSizes.spaceBtwItems),
               child: listItems[index],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SkeletonCircle(radius: 12),
                    const SizedBox(width: TSizes.sm),
                    const SkeletonWidget(height: 16, width: 100),
                  ],
                ),
                const SkeletonWidget(height: 28, width: 80, borderRadius: 16),
              ],
            ),
            const SizedBox(height: TSizes.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonWidget(height: 14, width: 120),
                const SkeletonWidget(height: 14, width: 100),
              ],
            ),
            const SizedBox(height: TSizes.sm),
            const SkeletonWidget(height: 8, width: double.infinity),
            const SizedBox(height: TSizes.xs),
            const SkeletonWidget(height: 12, width: 250),
          ],
        ),
      ),
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
