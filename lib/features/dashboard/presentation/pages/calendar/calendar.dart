import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:runap/features/dashboard/presentation/manager/training_view_model.dart';
import 'package:runap/features/dashboard/presentation/pages/calendar/widgets/skeleton_calendar_widgets.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/image_strings.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'package:runap/common/widgets/training/training_card.dart';

// --- Helper isSameDay (usado por table_calendar) ---
// Lo ponemos fuera de la clase para que sea accesible globalmente si es necesario,
// o podría ser un método estático.
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Asegurarse de que el ViewModel esté disponible (puedes usar bindings en su lugar)
    // Get.put(TrainingViewModel()); // Descomentar si no usas bindings

    // Obtener la instancia del ViewModel
    final TrainingViewModel viewModel = Get.find<TrainingViewModel>();

    // Cargar datos si aún no se han cargado (o forzar actualización si es necesario)
    // Esto podría hacerse en un `initState` de un StatefulWidget contenedor o mediante bindings.
    // Por simplicidad, lo llamamos aquí si los datos son nulos.
    if (viewModel.trainingData == null && viewModel.status != LoadingStatus.loading) {
       Future.microtask(() => viewModel.loadDashboardData());
    }


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Estado para TableCalendar
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mapa para almacenar eventos (sesiones) por día
  late final ValueNotifier<LinkedHashMap<DateTime, List<Session>>> _events;


  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _events = ValueNotifier(_groupSessionsByDay(Get.find<TrainingViewModel>()));

     // Escuchar cambios en el ViewModel para actualizar los eventos
     Get.find<TrainingViewModel>().addListener(_updateEvents);
  }

   @override
  void dispose() {
    Get.find<TrainingViewModel>().removeListener(_updateEvents); // Dejar de escuchar
    _events.dispose();
    super.dispose();
  }

  // Función para actualizar los eventos cuando el ViewModel cambie
  void _updateEvents() {
    _events.value = _groupSessionsByDay(Get.find<TrainingViewModel>());
  }


  // Helper para agrupar sesiones por día
 LinkedHashMap<DateTime, List<Session>> _groupSessionsByDay(TrainingViewModel viewModel) {
  final sessions = viewModel.trainingData?.dashboard.nextWeekSessions ?? [];
  final map = LinkedHashMap<DateTime, List<Session>>(
    equals: isSameDay,
    hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
  );

  for (final session in sessions) {
    final date = DateTime.utc(session.sessionDate.year, session.sessionDate.month, session.sessionDate.day);
    final list = map.putIfAbsent(date, () => []);
    list.add(session);
  }
  return map;
}


  List<Session> _getEventsForDay(DateTime day) {
    // Implementation example
    final dateUtc = DateTime.utc(day.year, day.month, day.day);
    return _events.value[dateUtc] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // Actualizar focusedDay también
      });

      // Aquí podrías hacer algo al seleccionar un día, como mostrar las sesiones de ese día debajo del calendario
      final events = _getEventsForDay(selectedDay);
      print("Seleccionado: $selectedDay - Eventos: ${events.length}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroundGradient(),
          GetBuilder<TrainingViewModel>(
            builder: (viewModel) {
              final bool isLoading = viewModel.status == LoadingStatus.loading && viewModel.trainingData == null;
              final bool hasError = viewModel.status == LoadingStatus.error;

              // Actualizar el mapa de eventos si los datos del viewModel cambiaron
              // Esto es una alternativa si no usamos el listener
              // _events.value = _groupSessionsByDay(viewModel);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.defaultSpace,
                      vertical: TSizes.spaceBtwItems,
                    ).copyWith(top: TSizes.appBarHeight),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        isLoading ? const SkeletonDateHeader() : const DateHeader(),
                        if (!isLoading && !hasError)
                         IconButton(
                            icon: Icon(
                              _calendarFormat == CalendarFormat.week
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: TColors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _calendarFormat = _calendarFormat == CalendarFormat.week
                                    ? CalendarFormat.month
                                    : CalendarFormat.week;
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  // --- TableCalendar ---
                  if (isLoading)
                    const SkeletonCalendarView()
                  else if (!hasError)
                    ValueListenableBuilder<LinkedHashMap<DateTime, List<Session>>>(
                       valueListenable: _events,
                       builder: (context, value, _) {
                        return TableCalendar<Session>(
                          locale: 'es_ES',
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2025, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          eventLoader: _getEventsForDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: _onDaySelected,
                          onFormatChanged: (format) {
                            if (_calendarFormat != format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            todayDecoration: BoxDecoration(
                              color: TColors.primaryColor.withAlpha(100),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: TColors.white.withAlpha(64),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                               color: TColors.secondaryColor,
                               shape: BoxShape.circle,
                             ),
                            defaultTextStyle: TextStyle(color: TColors.white.withAlpha(230)),
                            weekendTextStyle: TextStyle(color: TColors.white.withAlpha(180)),
                            todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
                            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                             weekdayStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                             weekendStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          calendarBuilders: CalendarBuilders(
                             markerBuilder: (context, day, events) {
                              if (events.isNotEmpty) {
                                final session = events.first;
                                final isPast = day.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
                                final isCompleted = session.completed;
                                final isMissed = isPast && !isCompleted;

                                IconData iconData;
                                Color iconColor;
                                double iconSize = 16.0; // Tamaño similar al anterior

                                if (isCompleted) {
                                  iconData = Icons.check; // <-- Icono anterior
                                  iconColor = TColors.white; // <-- Color anterior
                                } else if (isMissed) {
                                  iconData = Icons.close; // <-- Icono anterior
                                  iconColor = Colors.white70; // <-- Color anterior
                                } else {
                                  // No mostrar marcador para días futuros o el día actual sin completar
                                  return null;
                                  /* Marcador simple anterior (eliminado)
                                  return Positioned(
                                     right: 1,
                                     bottom: 1,
                                     child: Container(
                                       width: 6, height: 6,
                                       decoration: const BoxDecoration(
                                         shape: BoxShape.circle,
                                         color: TColors.secondaryColor,
                                       ),
                                     ),
                                   );
                                   */
                                }

                                // Marcador con icono para completado/perdido (estilo antiguo)
                                return Positioned(
                                  right: 1,
                                  bottom: 1,
                                  child: Icon(iconData, size: iconSize, color: iconColor),
                                );
                              }
                              return null; // Sin marcador si no hay eventos
                            },
                          ),
                        );
                       },
                      )
                   else
                      Expanded(child: _buildErrorView(viewModel)),

                  if (!isLoading && !hasError)
                    Expanded(
                      child: _buildContentView(),
                    ),
                  if (isLoading)
                     Expanded(child: _buildCalendarSkeletonList()),

                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget para mostrar la lista de esqueletos
  Widget _buildCalendarSkeletonList() {
    return ListView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      children: const [
        SizedBox(height: TSizes.spaceBtwItems),
        SkeletonFavoritesCard(),
        SizedBox(height: TSizes.spaceBtwItems),
        SkeletonChallengeCard(),
        SizedBox(height: TSizes.spaceBtwItems),
        SkeletonQuoteCard(),
        SizedBox(height: TSizes.spaceBtwItems),
      ],
    );
  }

  // Widget para mostrar el contenido del día seleccionado
  Widget _buildContentView() {
    // Obtener eventos para el día seleccionado
    // Usamos _focusedDay como fallback si _selectedDay es null al inicio
    final selectedDayEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    if (selectedDayEvents.isEmpty) {
      // Mostrar mensaje si no hay eventos para el día seleccionado
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Text(
            'No hay entrenamientos programados para este día.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ),
      );
    }

    // Mostrar lista de TrainingCards si hay eventos
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace).copyWith(top: TSizes.spaceBtwItems), // Añadir padding
      itemCount: selectedDayEvents.length,
      itemBuilder: (context, index) {
        final session = selectedDayEvents[index];
        final isPast = (_selectedDay ?? _focusedDay).isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

        return Padding(
           padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems), // Espacio entre tarjetas
           child: TrainingCard(
              session: session,
              showBorder: false, // O true, según prefieras el estilo aquí
              isPast: isPast,
              // onTap: () { /* Podrías añadir navegación aquí si es necesario */ },
           ),
        );
      },
    );

     /* Contenido estático anterior (eliminado)
     return ListView(
      padding: const EdgeInsets.all(TSizes.defaultSpace).copyWith(top: 0),
      children: const [
        FavoritesCard(),
        SizedBox(height: TSizes.spaceBtwItems),
        ChallengeCard(),
        SizedBox(height: TSizes.spaceBtwItems),
        QuoteCard(),
        SizedBox(height: TSizes.spaceBtwItems),
      ],
    ); */
  }

  // NUEVO: Widget para mostrar la vista de error
  Widget _buildErrorView(TrainingViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'Error al cargar los datos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              viewModel.errorMessage ?? 'Ocurrió un error inesperado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            ElevatedButton(
              onPressed: () => viewModel.loadDashboardData(forceRefresh: true),
              child: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: TColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de fondo con gradiente
class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFf78314), // Naranja inicial
            Color(0xFFfbc05e), // Naranja ligeramente más claro
            Color(0xFFfdd884), // Naranja aún más claro
            Color(0xFFfff3e0), // Amarillo muy pálido (casi blanco)
          ],
          stops: [0.0, 0.4, 0.6, 1.0],
        ),
      ),
    );
  }
}

// Widget de encabezado de fecha
class DateHeader extends StatelessWidget {
  const DateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(now).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoy',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: TColors.white,
          ),
        ),
         Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// Widget de la tarjeta de Favoritos
class FavoritesCard extends StatelessWidget {
  const FavoritesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          decoration: BoxDecoration(
            color: TColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: TColors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TColors.darkerGrey,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Every Friday, share your favorite things',
                style: TextStyle(
                  fontSize: 14,
                  color: TColors.darkGrey,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                    color: TColors.secondaryColor
                      .withAlpha(204),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Have more to share?',
                      style: TextStyle(
                        fontSize: 16,
                        color: TColors.darkGrey,
                      ),
                    ),
                    Icon(
                      Icons.add,
                      color: TColors.primaryColor,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Positioned(
          top: -30,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: TColors.primaryColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: TColors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: TColors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget de la tarjeta de Desafío Diario
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: TColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.flag,
                    color: TColors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ENDS IN 09:58:49',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: TColors.white,
                    ),
                  ),
                ],
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: TColors.white.withAlpha(77),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flag,
                  color: TColors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Daily',
            style: TextStyle(
              fontSize: 18,
              color: TColors.white,
            ),
          ),
          const Text(
            'Challenge',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: TColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: TColors.white.withAlpha(55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.landscape,
                  color: TColors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de la tarjeta con cita e imagen
class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage(TImages.fitnessIllustration),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withAlpha(55),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: TColors.black.withAlpha(77),
            ),
          ),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: TColors.black.withAlpha(104),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Everything you can imagine is real.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TColors.white,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TColors.black.withAlpha(104),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fullscreen,
                color: TColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Skeleton para la vista del calendario (NUEVO)
class SkeletonCalendarView extends StatelessWidget {
  const SkeletonCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
      child: Column(
        children: [
          Container(
             margin: const EdgeInsets.symmetric(vertical: TSizes.sm, horizontal: TSizes.lg),
             height: 20, width: 150,
             decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
           ),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             children: List.generate(7, (_) => Container(
                margin: const EdgeInsets.only(bottom: TSizes.sm),
                height: 15, width: 25,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
              )),
           ),
           ...List.generate(5, (_) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (_) => Container(
                 margin: const EdgeInsets.all(2.0),
                 height: 35, width: 35,
                 decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
               )),
            )),
        ],
      ),
    );
  }
}
