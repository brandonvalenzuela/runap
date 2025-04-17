import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:math';
import 'package:runap/common/widgets/training/training_card.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:runap/features/dashboard/presentation/manager/training_view_model.dart';
import 'package:runap/features/dashboard/widgets/date_header.dart';
import 'package:runap/features/map/screen/map.dart';
import 'package:runap/features/personalization/screens/profile/profile.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/common/widgets/training/skeleton_training_card.dart';
import 'package:runap/common/widgets/headers/user_profile_header.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:runap/utils/device/device_utility.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TrainingViewModel viewModel;
  late final AnimationController _controller;
  late final Animation<Offset> slideHeaderAnimation;
  late final Animation<double> fadeHeaderAnimation;
  late final Animation<double> fadeProgressAnimation;
  // Animaciones para el AppBar
  late Animation<double> _fadeAppBarAnimation;
  late Animation<Offset> _slideAvatarAnimation;
  late Animation<double> _fadeUserInfoAnimation;
  late Animation<double> _rotateMenuAnimation;
  // Animaciones para el contenido principal (pasadas a _HomeContentWidget)
  late Animation<double> _fadeTitleAnimation;

  // Formateadores de fecha (podrían moverse a utils si se usan en otro lugar)
  final _dayFormatter = DateFormat('d', 'es_ES');
  final _monthFormatter = DateFormat('MMM', 'es_ES');
  final _weekdayFormatter = DateFormat('EEEE', 'es_ES');

  // Constantes de animación (usadas por el state y widgets internos)
  static const Duration _appBarAnimationDuration = Duration(milliseconds: 2500);
  static const Duration _headerAnimationDuration = Duration(milliseconds: 900);
  static const Duration _progressAnimationDuration = Duration(milliseconds: 1800);
  static const Duration _listItemAnimationDuration = Duration(milliseconds: 400);
  static const Duration _cardAnimationDuration = Duration(milliseconds: 500);

  // Constantes de estilo y altura (usadas por el state y widgets internos)
  static const double _cardBorderRadius = TSizes.borderRadiusXl;
  static const double _cardShadowOpacity = 0.05;
  static const double _cardShadowBlur = 15.0;
  static const double _cardShadowSpread = 3.0;
  static const double _cardShadowOffset = 5.0;
  static const double _listItemShadowOpacity = 0.2;
  static const double _listItemShadowBlur = 15.0;
  static const double _listItemShadowSpread = 2.0;
  static const double _listItemShadowOffset = 5.0;
  static const double _estimatedHeaderHeight = 60.0;
  static const double _estimatedCardHeight = 118.0;
  static const double _dashboardHeaderHeight = 150.0;
  static const double _upcomingTitleHeight = 50.0;

  @override
  void initState() {
    super.initState();
    viewModel = Get.find<TrainingViewModel>();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    slideHeaderAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    fadeHeaderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    fadeProgressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
    ));

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

    // Animación para el título de sección
    _fadeTitleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.4, curve: Curves.easeOut),
      ),
    );

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
    // Obtener el controlador de usuario (solo para el AppBar)
    // final userController = Get.find<UserController>(); // No es necesario aquí si UserProfileHeader lo obtiene internamente

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
                child: UserProfileHeader( // Asumiendo que UserProfileHeader obtiene UserController internamente
                  onAvatarTap: () {
                    TDiviceUtility.vibrateLight();
                    Get.to(() => const ProfileScreen(),
                        transition: Transition.rightToLeft);
                  },
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: GetBuilder<TrainingViewModel>(
        builder: (viewModel) {
          // Añadir un log para depuración (opcional)
          // print('🔄 HomeScreen GetBuilder - Status: ${viewModel.status}, Data: ${viewModel.trainingData != null}');
          
          // Estado de carga
          if (viewModel.status == LoadingStatus.loading &&
              viewModel.trainingData == null) {
            return _SkeletonListWidget(
              estimatedHeaderHeight: _estimatedHeaderHeight,
              estimatedCardHeight: _estimatedCardHeight,
              dashboardHeaderHeight: _dashboardHeaderHeight,
              upcomingTitleHeight: _upcomingTitleHeight,
            );
          }
          // Estado de error
          else if (viewModel.status == LoadingStatus.error) {
            return _ErrorViewWidget(viewModel: viewModel);
          }
          // Estado con datos
          else if (viewModel.trainingData != null) {
             final allSessions = viewModel.trainingData!.dashboard.nextWeekSessions;
             if (allSessions.isNotEmpty) {
                final currentWeekSessions = _getCurrentWeekSessions(allSessions);

                if (currentWeekSessions.isNotEmpty) {
                  // Mostrar contenido
                  return _HomeContentWidget(
                    viewModel: viewModel,
                    sessions: currentWeekSessions,
                    slideHeaderAnimation: slideHeaderAnimation,
                    fadeHeaderAnimation: fadeHeaderAnimation,
                    fadeProgressAnimation: fadeProgressAnimation,
                    fadeTitleAnimation: _fadeTitleAnimation,
                    controller: _controller, // Pasar el controlador para animaciones internas
                    dayFormatter: _dayFormatter,
                    monthFormatter: _monthFormatter,
                    weekdayFormatter: _weekdayFormatter,
                    // Pasar constantes necesarias
                    cardBorderRadius: _cardBorderRadius,
                    cardShadowOpacity: _cardShadowOpacity,
                    cardShadowBlur: _cardShadowBlur,
                    cardShadowSpread: _cardShadowSpread,
                    cardShadowOffset: _cardShadowOffset,
                    listItemShadowOpacity: _listItemShadowOpacity,
                    listItemShadowBlur: _listItemShadowBlur,
                    listItemShadowSpread: _listItemShadowSpread,
                    listItemShadowOffset: _listItemShadowOffset,
                    listItemAnimationDuration: _listItemAnimationDuration,
                    cardAnimationDuration: _cardAnimationDuration,
                    headerAnimationDuration: _headerAnimationDuration,
                    progressAnimationDuration: _progressAnimationDuration,
                  );
                } else {
                   // Mensaje si hay datos pero no para esta semana
                  return const Center(
                    child: Text('No hay entrenamientos programados para esta semana.'),
                  );
                }
             } else {
               // Mensaje si no hay ninguna sesión programada
               return const Center(
                  child: Text('No hay entrenamientos programados.'),
               );
             }
          }
          // Estado por defecto (si no es loading, error o con datos válidos)
          else {
            return const Center(
              child: Text('No hay datos disponibles.'), // Mensaje genérico
            );
          }
        },
      ),
    );
  }

  // --- Widgets extraídos ---

  // Widget para mostrar la lista de esqueletos
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
        _dashboardHeaderHeight - // Asumiendo que el header del dashboard también tiene un skeleton
        _upcomingTitleHeight; // Asumiendo que el título también tiene un skeleton

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
          // Deberíamos tener un Skeleton específico para el DateHeader si existe
          return const SkeletonDashboardDateHeader(); // Usar Skeleton existente
        } else {
          // Es un índice impar, mostrar skeleton de card
          return const SkeletonTrainingCard(); // Usar Skeleton existente
        }
      },
    );
  }

  // Widget para mostrar la vista de error
  Widget _buildErrorView(BuildContext context, TrainingViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Error al cargar los datos de entrenamiento'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              TDiviceUtility.vibrateMedium();
              viewModel.loadDashboardData(forceRefresh: true);
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar el contenido principal de la home
  Widget _buildHomeContent(BuildContext context, TrainingViewModel viewModel, List<Session> sessions) {
    final dashboard = viewModel.trainingData!.dashboard;
    // No es necesario verificar si sessions está vacía aquí porque ya se hizo en el builder principal

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDashboardHeader(context),
        _buildUpcomingSessionsTitle(context),
        _buildSessionsList(context, sessions),
      ],
    );
  }

  // --- Métodos auxiliares movidos o mantenidos en _HomeScreenState ---
  // (buildSkeletonList, buildErrorView, buildHomeContent se reemplazan por los widgets)

  // Widget para el header del dashboard (usado dentro de _HomeContentWidget)
  Widget _buildDashboardHeader(BuildContext context) {
    final dashboard = viewModel.trainingData!.dashboard;

    return SlideTransition(
      position: slideHeaderAnimation,
      child: FadeTransition(
        opacity: fadeHeaderAnimation,
        child: Padding(
          padding: const EdgeInsets.only(
              top: TSizes.space,
              right: TSizes.defaultSpace,
              left: TSizes.defaultSpace),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: _headerAnimationDuration,
            curve: Curves.easeOutSine,
            builder: (context, value, child) {
              return Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  // Aplicar gradiente y sombra del archivo de prueba
                  gradient: const LinearGradient(
                    colors: [
                      TColors.primaryColor, // Naranjo oscuro (inicio)
                      TColors.gradientColor, // Naranjo claro (fin)
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusXl), // Ajustar radio
                  boxShadow: [
                    BoxShadow(
                      color: TColors.gradientColor.withAlpha(104), // Sombra del archivo de prueba
                      blurRadius: 20 * value, // Animar desenfoque
                      offset: Offset(0, 8 * value), // Animar desplazamiento
                      // spreadRadius no está en el archivo de prueba, lo eliminamos
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
                            Container(
                              padding: const EdgeInsets.all(TSizes.sm),
                              decoration: BoxDecoration(
                                // Usar blanco con transparencia para el fondo del icono
                                color: Colors.white.withAlpha(104),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.directions_run,
                                  color: Colors.white, // Icono blanco
                                  size: 20.0),
                            ),
                            const SizedBox(width: TSizes.sm),
                            Text(
                              dashboard.raceType,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // Texto blanco
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            // Mantener color primario o ajustar si es necesario
                            color: TColors.white, // Cambiar a blanco para contraste
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: TColors.darkGrey.withAlpha(51), // Sombra sutil
                                blurRadius: 5,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '${dashboard.weeksToRace} semanas',
                            style: const TextStyle(
                                color: TColors.primaryColor, // Texto primario
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.md),

                    // Ritmo objetivo y tiempo meta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          context,
                          'Ritmo objetivo:',
                          dashboard.targetPace,
                          Icons.speed,
                          textColor: Colors.white, // Texto blanco
                          iconBackgroundColor: Colors.white.withAlpha(104), // Fondo blanco transp.
                          iconColor: Colors.white, // Icono blanco
                        ),
                        _buildInfoItem(
                          context,
                          'Tiempo meta:',
                          dashboard.goalTime,
                          Icons.timer,
                          textColor: Colors.white, // Texto blanco
                          iconBackgroundColor: Colors.white.withAlpha(104), // Fondo blanco transp.
                          iconColor: Colors.white, // Icono blanco
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.md),

                    // Barra de progreso con animación propia
                    FadeTransition(
                      opacity: fadeProgressAnimation,
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
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  // Fondo de la barra de progreso más claro
                                  color: Colors.white.withAlpha(77),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.transparent,
                                    // Usar blanco para la barra de progreso
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: TSizes.xs),
                              Text(
                                '${dashboard.completedSessions} de ${dashboard.totalSessions} sesiones completadas',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      // Texto blanco con transparencia
                                      color: Colors.white.withAlpha(230),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              Text(
                                '${dashboard.completionRate.toStringAsFixed(0)}% completado',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      // Texto blanco
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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

  // Widget para el título "Entrenamientos de la semana" (usado dentro de _HomeContentWidget)
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
              const EdgeInsets.symmetric(horizontal: TSizes.spaceBtwItems, vertical: TSizes.sm),
          child: Row(
            children: [
              Text(
                "Entrenamientos de la semana",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Iconsax.map_1, size: 20),
                tooltip: 'Abrir Mapa',
                onPressed: () {
                  TDiviceUtility.vibrateLight();
                  Get.to(() => MapScreen(), transition: Transition.upToDown);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para la lista de sesiones (usado dentro de _HomeContentWidget)
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
        final isTodaySession = DateTime(
          session.sessionDate.year,
          session.sessionDate.month,
          session.sessionDate.day
        ) == DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day
        ); // Comparación directa de fechas

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
                        color: TColors.colorBlack.withAlpha((_listItemShadowOpacity * 255).round()),
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

  // Widget para mostrar elementos de información (usado dentro de _buildDashboardHeader -> ahora en _HomeContentWidget)
  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon, {Color textColor = TColors.dark, Color iconBackgroundColor = TColors.primaryColor, Color iconColor = TColors.primaryColor}) {
    // Ajustar colores por defecto si es necesario o quitar los parámetros opcionales si siempre serán blancos
    iconBackgroundColor = iconBackgroundColor == TColors.primaryColor ? TColors.primaryColor.withAlpha(30) : iconBackgroundColor; // Mantener lógica original si no se sobreescribe

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconBackgroundColor, // Usar color de fondo pasado
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: iconColor, // Usar color de icono pasado
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    // Usar color de texto pasado con opacidad
                    color: textColor.withAlpha(204),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor, // Usar color de texto pasado
                  ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Funciones auxiliares mantenidas en _HomeScreenState ---
  // (Pueden moverse a utils si son genéricas)

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


// --- Widgets Privados Extraídos ---

class _SkeletonListWidget extends StatelessWidget {
  final double estimatedHeaderHeight;
  final double estimatedCardHeight;
  final double dashboardHeaderHeight;
  final double upcomingTitleHeight;

  const _SkeletonListWidget({
    required this.estimatedHeaderHeight,
    required this.estimatedCardHeight,
    required this.dashboardHeaderHeight,
    required this.upcomingTitleHeight,
  });

  @override
  Widget build(BuildContext context) {
     // Estimación de la altura combinada de un header + una tarjeta (aproximado)
    final estimatedGroupHeight = estimatedHeaderHeight +
        TSizes.spaceBtwSections * 0.8 +
        TSizes.spaceBtwItems +
        estimatedCardHeight;

    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight;
    final paddingTop = MediaQuery.of(context).padding.top;
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    // Altura disponible estimada
    // TODO: Considerar si el header del dashboard y el título tienen esqueletos visibles
    final availableHeight = screenHeight -
        appBarHeight -
        paddingTop -
        paddingBottom -
        dashboardHeaderHeight - // Altura estimada del header del dashboard
        upcomingTitleHeight; // Altura estimada del título "próximas sesiones"

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
          // Asegúrate de tener este widget definido en common/widgets/training/
          return const SkeletonDashboardDateHeader();
        } else {
          // Es un índice impar, mostrar skeleton de card
          return const SkeletonTrainingCard();
        }
      },
    );
  }
}

class _ErrorViewWidget extends StatelessWidget {
  final TrainingViewModel viewModel;

  const _ErrorViewWidget({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Error al cargar los datos de entrenamiento'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              TDiviceUtility.vibrateMedium();
              viewModel.loadDashboardData(forceRefresh: true);
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _HomeContentWidget extends StatelessWidget {
  final TrainingViewModel viewModel;
  final List<Session> sessions;
  final Animation<Offset> slideHeaderAnimation;
  final Animation<double> fadeHeaderAnimation;
  final Animation<double> fadeProgressAnimation;
  final Animation<double> fadeTitleAnimation;
  final AnimationController controller;
  final DateFormat dayFormatter;
  final DateFormat monthFormatter;
  final DateFormat weekdayFormatter;
  final double cardBorderRadius;
  final double cardShadowOpacity;
  final double cardShadowBlur;
  final double cardShadowSpread;
  final double cardShadowOffset;
  final double listItemShadowOpacity;
  final double listItemShadowBlur;
  final double listItemShadowSpread;
  final double listItemShadowOffset;
  final Duration listItemAnimationDuration;
  final Duration cardAnimationDuration;
  final Duration headerAnimationDuration;
  final Duration progressAnimationDuration;

  const _HomeContentWidget({
    required this.viewModel,
    required this.sessions,
    required this.slideHeaderAnimation,
    required this.fadeHeaderAnimation,
    required this.fadeProgressAnimation,
    required this.fadeTitleAnimation,
    required this.controller,
    required this.dayFormatter,
    required this.monthFormatter,
    required this.weekdayFormatter,
    required this.cardBorderRadius,
    required this.cardShadowOpacity,
    required this.cardShadowBlur,
    required this.cardShadowSpread,
    required this.cardShadowOffset,
    required this.listItemShadowOpacity,
    required this.listItemShadowBlur,
    required this.listItemShadowSpread,
    required this.listItemShadowOffset,
    required this.listItemAnimationDuration,
    required this.cardAnimationDuration,
    required this.headerAnimationDuration,
    required this.progressAnimationDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardHeaderCard(
          dashboard: viewModel.trainingData!.dashboard,
          slideHeaderAnimation: slideHeaderAnimation,
          fadeHeaderAnimation: fadeHeaderAnimation,
          fadeProgressAnimation: fadeProgressAnimation,
          headerAnimationDuration: headerAnimationDuration,
          progressAnimationDuration: progressAnimationDuration,
          cardBorderRadius: cardBorderRadius,
        ),
        _buildUpcomingSessionsTitle(context),
        _SessionsListView(
          sessions: sessions,
          dayFormatter: dayFormatter,
          monthFormatter: monthFormatter,
          weekdayFormatter: weekdayFormatter,
          listItemAnimationDuration: listItemAnimationDuration,
          cardAnimationDuration: cardAnimationDuration,
          cardBorderRadius: cardBorderRadius,
          listItemShadowOpacity: listItemShadowOpacity,
          listItemShadowBlur: listItemShadowBlur,
          listItemShadowSpread: listItemShadowSpread,
          listItemShadowOffset: listItemShadowOffset,
        ),
      ],
    );
  }

  Widget _buildUpcomingSessionsTitle(BuildContext context) {
    return FadeTransition(
      opacity: fadeTitleAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.3, 0.4, curve: Curves.easeOut),
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: TSizes.spaceBtwItems, vertical: TSizes.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Asegura espacio entre texto y botón
            children: [
              Text(
                "Entrenamientos de la semana",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Iconsax.map_1, size: 20),
                tooltip: 'Abrir Mapa', // Añadir tooltip para accesibilidad
                onPressed: () {
                  TDiviceUtility.vibrateLight();
                  Get.to(() => MapScreen(), transition: Transition.upToDown);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- NUEVO WIDGET: Encabezado del Dashboard Expandible ---

class _DashboardHeaderCard extends StatefulWidget {
  final Dashboard dashboard;
  final Animation<Offset> slideHeaderAnimation;
  final Animation<double> fadeHeaderAnimation;
  final Animation<double> fadeProgressAnimation;
  final Duration headerAnimationDuration;
  final Duration progressAnimationDuration;
  final double cardBorderRadius;

  const _DashboardHeaderCard({
    required this.dashboard,
    required this.slideHeaderAnimation,
    required this.fadeHeaderAnimation,
    required this.fadeProgressAnimation,
    required this.headerAnimationDuration,
    required this.progressAnimationDuration,
    required this.cardBorderRadius,
  });

  @override
  State<_DashboardHeaderCard> createState() => _DashboardHeaderCardState();
}

class _DashboardHeaderCardState extends State<_DashboardHeaderCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    TDiviceUtility.vibrateLight();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usar las animaciones pasadas desde _HomeScreenState
    return SlideTransition(
      position: widget.slideHeaderAnimation,
      child: FadeTransition(
        opacity: widget.fadeHeaderAnimation,
        child: Padding(
          padding: const EdgeInsets.only(
              top: TSizes.defaultSpace,
              right: TSizes.spaceBtwItems,
              left: TSizes.spaceBtwItems),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: widget.headerAnimationDuration,
            curve: Curves.easeOutSine,
            builder: (context, value, child) {
              // Contenedor principal con gradiente y sombra
              return Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [TColors.primaryColor, TColors.gradientColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(widget.cardBorderRadius), // Usar valor pasado
                  boxShadow: [
                    BoxShadow(
                      color: TColors.gradientColor.withAlpha(50), // Opacidad aún más baja
                      blurRadius: 5 * value,  // Desenfoque mínimo
                      offset: Offset(0, 3 * value), // Desplazamiento vertical muy corto
                      spreadRadius: 0,        // Sin expansión
                    ),
                  ],
                ),
                child: Material( // Necesario para InkWell y ClipRRect
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.cardBorderRadius),
                  child: InkWell(
                    onTap: _toggleExpansion,
                    borderRadius: BorderRadius.circular(widget.cardBorderRadius),
                    child: Padding(
                      // Aumentar el padding vertical para más altura inicial
                      padding: const EdgeInsets.symmetric(vertical: TSizes.defaultSpace - 2, horizontal: TSizes.defaultSpace),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Sección Superior (Siempre visible) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Icono y Tipo de carrera
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(TSizes.sm),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(104),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.directions_run, color: Colors.white, size: TSizes.iconSm + 4),
                                  ),
                                  const SizedBox(width: TSizes.sm),
                                  Text(
                                    widget.dashboard.raceType,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold, color: Colors.white, fontSize: TSizes.fontSizeLg),
                                  ),
                                ],
                              ),
                              // Semanas restantes e Icono de expansión
                              Row(
                                children: [
                                  Container(
                                     padding: const EdgeInsets.symmetric(horizontal: TSizes.smallSpace, vertical: TSizes.xSmallSpace),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(color: TColors.darkGrey.withAlpha(51), blurRadius: 5, offset: const Offset(0, 1)),
                                        ],
                                      ),
                                      child: Text(
                                        '${widget.dashboard.weeksToRace} semanas',
                                        style: const TextStyle(color: TColors.primaryColor, fontSize: TSizes.fontSizeXs, fontWeight: FontWeight.w600),
                                      ),
                                  ),
                                  const SizedBox(width: TSizes.sm),
                                  RotationTransition(
                                    turns: _rotationAnimation,
                                    child: const Icon(Icons.expand_more, color: Colors.white, size: TSizes.iconMd),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // --- Sección Detallada (Expandible) ---
                          AnimatedCrossFade(
                            firstChild: Container(), // Vacío cuando está colapsado
                            secondChild: _buildDetailsSection(context), // Contenido detallado
                            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                            firstCurve: Curves.easeOut,
                            secondCurve: Curves.easeIn,
                            sizeCurve: Curves.easeInOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Widget para la sección de detalles
  Widget _buildDetailsSection(BuildContext context) {
    return Padding(
      // Añadir padding superior para separar de la sección siempre visible
      padding: const EdgeInsets.only(top: TSizes.spaceBtwItems),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ritmo objetivo y tiempo meta (Usando el helper _buildInfoItem)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                context,
                'Ritmo objetivo:',
                widget.dashboard.targetPace,
                Icons.speed,
                textColor: Colors.white,
                iconBackgroundColor: Colors.white.withAlpha(104),
                iconColor: Colors.white,
              ),
              _buildInfoItem(
                context,
                'Tiempo meta:',
                widget.dashboard.goalTime,
                Icons.timer,
                textColor: Colors.white,
                iconBackgroundColor: Colors.white.withAlpha(104),
                iconColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItemsSm),

          // Barra de progreso con animación propia
          FadeTransition(
            // Usar la animación de progreso pasada
            opacity: widget.fadeProgressAnimation,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                  begin: 0.0,
                  end: widget.dashboard.completionRate / 100),
              // Usar la duración de progreso pasada
              duration: widget.progressAnimationDuration,
              curve: Curves.easeOutQuad,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: TSizes.smx,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(77),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItemsSm),
                    Text(
                      '${widget.dashboard.completedSessions} de ${widget.dashboard.totalSessions} sesiones completadas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withAlpha(230),
                            fontWeight: FontWeight.w500,
                            fontSize: TSizes.fontSizeMd,
                            ),
                    ),
                    Text(
                      '${widget.dashboard.completionRate.toStringAsFixed(0)}% completado',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: TSizes.fontSizeMd,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper para mostrar elementos de información (movido aquí)
  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon, {required Color textColor, required Color iconBackgroundColor, required Color iconColor}) {
     return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(TSizes.xSmallSpace),
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          ),
          child: Icon(icon, size: TSizes.iconMx, color: iconColor),
        ),
        const SizedBox(width: TSizes.xSmallSpace),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor.withAlpha(204),
                    fontWeight: FontWeight.w500,
                    fontSize: TSizes.fontSizeMd),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: TSizes.fontSizeSm),
            ),
          ],
        ),
      ],
    );
  }

} // Fin de _DashboardHeaderCardState

// --- NUEVO WIDGET: Lista de Sesiones con Animaciones ---
class _SessionsListView extends StatelessWidget {
  final List<Session> sessions;
  final DateFormat dayFormatter;
  final DateFormat monthFormatter;
  final DateFormat weekdayFormatter;
  final Duration listItemAnimationDuration;
  final Duration cardAnimationDuration;
  final double cardBorderRadius;
  final double listItemShadowOpacity;
  final double listItemShadowBlur;
  final double listItemShadowSpread;
  final double listItemShadowOffset;

  const _SessionsListView({
    required this.sessions,
    required this.dayFormatter,
    required this.monthFormatter,
    required this.weekdayFormatter,
    required this.listItemAnimationDuration,
    required this.cardAnimationDuration,
    required this.cardBorderRadius,
    required this.listItemShadowOpacity,
    required this.listItemShadowBlur,
    required this.listItemShadowSpread,
    required this.listItemShadowOffset,
  });

  @override
  Widget build(BuildContext context) {
    // Ordenar sesiones por fecha (asegurarse de que estén ordenadas)
    final sortedSessions = List<Session>.from(sessions)..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    // Agrupar sesiones por día (ignorando la hora)
    final groupedSessions = groupBy<Session, DateTime>(
      sortedSessions,
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
        _buildAnimatedListItem(
          index: animationIndex++,
          duration: listItemAnimationDuration,
          verticalOffset: 30.0,
          child: DashboardDateHeader(
            day: dayFormatter.format(date),
            month: monthFormatter.format(date).replaceAll('.', '').capitalizeFirst ?? monthFormatter.format(date),
            weekday: weekdayFormatter.format(date).capitalizeFirst ?? weekdayFormatter.format(date),
            label: label,
          ),
        )
      );

      // Añadir las TrainingCards para este día
      for (var session in sessionsOnDate) {
        final isPast = session.sessionDate.isBefore(DateTime.now()); // Considerar hora aquí

        listItems.add(
          _buildAnimatedListItem(
            index: animationIndex++,
            duration: cardAnimationDuration,
            verticalOffset: 50.0,
            child: _buildTrainingCardItem(session, isPast),
          )
        );
      }
      // Añadir un SizedBox después de cada grupo de tarjetas del día para espaciado
      listItems.add(SizedBox(height: TSizes.spaceBtwSections * 0.8));
    });

    // Remover el último SizedBox si existe y si la lista no está vacía
    if (listItems.isNotEmpty && listItems.last is SizedBox) {
      listItems.removeLast();
    }

    // Devolver el ListView animado
    return Expanded(
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.spaceBtwItems)
                   .copyWith(bottom: TSizes.defaultSpace),
          itemCount: listItems.length,
          itemBuilder: (context, index) {
            return listItems[index];
          },
        ),
      ),
    );
  }

  // Helper para construir un item de lista animado
  Widget _buildAnimatedListItem({
    required int index,
    required Duration duration,
    required double verticalOffset,
    required Widget child,
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration,
      child: SlideAnimation(
        verticalOffset: verticalOffset,
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }

  // Helper para construir el contenedor y la TrainingCard
  Widget _buildTrainingCardItem(Session session, bool isPast) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: TColors.colorBlack.withAlpha((listItemShadowOpacity * 255).round()),
            blurRadius: listItemShadowBlur,
            offset: Offset(0, listItemShadowOffset),
            spreadRadius: listItemShadowSpread,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardBorderRadius),
        child: TrainingCard(
          session: session,
          showBorder: false,
          isPast: isPast,
        ),
      ),
    );
  }
}
