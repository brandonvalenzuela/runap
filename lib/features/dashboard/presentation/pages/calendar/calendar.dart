import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:runap/features/dashboard/presentation/manager/training_view_model.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';
import 'package:runap/features/dashboard/domain/entities/dashboard_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';
import 'package:runap/common/widgets/training/training_card.dart';

// --- Helper isSameDay (local) ---
// Lo ponemos fuera de la clase para que sea accesible globalmente.
// (Originalmente de table_calendar, adaptado para null safety)
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// --- CalendarScreen: Punto de entrada StatefulWidget ---
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final TrainingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Get.find<TrainingViewModel>();
    // Cargar datos iniciales si es necesario
    _loadInitialData();
  }

  void _loadInitialData() {
     if (_viewModel.trainingData == null && _viewModel.status != LoadingStatus.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _viewModel.loadDashboardData();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<TrainingViewModel>(
        // Usar el viewModel ya obtenido en initState
        // init: _viewModel, // No es necesario si ya está inyectado y encontrado
        builder: (viewModel) {
          final bool isLoading = viewModel.status == LoadingStatus.loading && viewModel.trainingData == null;
          final bool hasError = viewModel.status == LoadingStatus.error;

          return Stack(
            children: [
              const _BackgroundGradient(), // Fondo
              // Contenido principal basado en el estado
              if (isLoading)
                _buildLoadingView()
              else if (hasError)
                 _buildErrorView(viewModel)
              else
                 // Pasar el viewModel con datos a la vista principal
                 _CalendarView(viewModel: viewModel),
            ],
          );
        },
      ),
    );
  }

  // --- Widgets de Estado (Loading/Error) --- //

  Widget _buildLoadingView() {
    // Simple vista de carga centrada por ahora
    return const Center(
      child: CircularProgressIndicator(color: TColors.primaryColor),
    );
    // Podríamos volver a la vista con Skeletons más adelante
  }

  Widget _buildErrorView(TrainingViewModel viewModel) {
    // Vista de error simple
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'Error al cargar datos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              viewModel.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () => viewModel.loadDashboardData(forceRefresh: true),
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: TColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

// --- _CalendarView: Vista principal con calendario y sesiones ---
class _CalendarView extends StatefulWidget {
  final TrainingViewModel viewModel; // Recibe el viewModel con datos
  const _CalendarView({required this.viewModel});

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<LinkedHashMap<DateTime, List<Session>>> _groupedEventsNotifier;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Inicializar con los datos ya cargados pasados por el widget
    _groupedEventsNotifier = ValueNotifier(_groupSessionsByDay(widget.viewModel.trainingData!.dashboard.nextWeekSessions));
    // Escuchar cambios futuros en el viewModel (si es necesario recargar)
    widget.viewModel.addListener(_updateEvents);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateEvents);
    _groupedEventsNotifier.dispose();
    super.dispose();
  }

  // Actualiza el notificador si los datos en el viewModel cambian
  void _updateEvents() {
    if (mounted && widget.viewModel.trainingData != null) {
       _groupedEventsNotifier.value = _groupSessionsByDay(widget.viewModel.trainingData!.dashboard.nextWeekSessions);
    } else if (mounted) {
       // Limpiar si los datos se vuelven nulos (ej: error después de carga exitosa)
       _groupedEventsNotifier.value = LinkedHashMap<DateTime, List<Session>>(equals: isSameDay, hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year);
    }
  }

  // Agrupa las sesiones (asume que sessions no es null aquí)
  LinkedHashMap<DateTime, List<Session>> _groupSessionsByDay(List<Session> sessions) {
    final map = LinkedHashMap<DateTime, List<Session>>(
      equals: isSameDay,
      hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
    );
    for (final session in sessions) {
      final date = DateTime.utc(session.sessionDate.year, session.sessionDate.month, session.sessionDate.day);
      map.putIfAbsent(date, () => []).add(session);
    }
    return map;
  }

  List<Session> _getEventsForDay(DateTime day) {
    final dateUtc = DateTime.utc(day.year, day.month, day.day);
    return _groupedEventsNotifier.value[dateUtc] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _onFormatChanged(CalendarFormat format) {
     if (_calendarFormat != format) {
        setState(() => _calendarFormat = format);
      }
  }

  @override
  Widget build(BuildContext context) {
    // Ahora _CalendarView asume que tiene datos válidos
    return Column(
      children: [
        // Encabezado (Fecha actual y botón de formato)
        _CalendarHeader(
          calendarFormat: _calendarFormat,
          onFormatChanged: _onFormatChanged,
        ),
        // Widget del Calendario
        ValueListenableBuilder<LinkedHashMap<DateTime, List<Session>>>(
          valueListenable: _groupedEventsNotifier,
          builder: (context, groupedEvents, _) {
            // Aquí sí necesitamos el widget TableCalendar
            return TableCalendar<Session>(
              locale: 'es_ES',
              firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
              lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                 // No necesitamos llamar a setState aquí si onFormatChanged ya lo hace
                 if (_calendarFormat != format) {
                   _onFormatChanged(format); // Llama al método que hace setState
                 }
              },
              onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
              calendarStyle: _buildCalendarStyle(),
              headerStyle: _buildHeaderStyle(),
              daysOfWeekStyle: _buildDaysOfWeekStyle(),
              calendarBuilders: _buildCalendarBuilders(),
            );
          },
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        // Lista de sesiones para el día seleccionado
        Expanded(
          child: _SelectedDaySessionsList(
            selectedDay: _selectedDay ?? _focusedDay,
            getEventsForDay: _getEventsForDay,
          ),
        ),
      ],
    );
  }

  // --- Métodos para construir estilos y builders del TableCalendar --- //

  CalendarStyle _buildCalendarStyle() {
     return CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: TColors.primaryColor.withAlpha(127),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: TColors.white.withAlpha(64),
          shape: BoxShape.circle,
        ),
        defaultTextStyle: TextStyle(color: TColors.white.withAlpha(230)),
        weekendTextStyle: TextStyle(color: TColors.white.withAlpha(179)),
        todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
  }

 HeaderStyle _buildHeaderStyle() {
   return const HeaderStyle(
        formatButtonVisible: false, // Controlado por _CalendarHeader
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        headerPadding: EdgeInsets.symmetric(vertical: 8.0),
      );
 }

 DaysOfWeekStyle _buildDaysOfWeekStyle() {
   return const DaysOfWeekStyle(
         weekdayStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
         weekendStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
      );
 }

 CalendarBuilders<Session> _buildCalendarBuilders() {
   return CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isNotEmpty) {
             final session = events.first;
             final isPast = day.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
             final isCompleted = session.completed;
             final isMissed = isPast && !isCompleted;
             IconData? iconData;
             Color iconColor = TColors.white;
             if (isCompleted) {
               iconData = Icons.check_circle;
               iconColor = TColors.success;
             } else if (isMissed) {
               iconData = Icons.cancel;
               iconColor = TColors.warning;
             }
             if (iconData != null) {
               return Positioned(
                 right: 3,
                 bottom: 3,
                 child: Icon(iconData, size: 14, color: iconColor),
               );
             }
          }
          return null;
        },
      );
 }

}


// --- Widgets Auxiliares (Stateless) --- //

// Fondo con gradiente
class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            TColors.primaryColor,
            TColors.gradientColor,
            Color(0xFFfdd884),
            Color(0xFFfff3e0),
          ],
          stops: [0.0, 0.4, 0.6, 1.0],
        ),
      ),
    );
  }
}

// Encabezado del Calendario (Fecha y botón de formato)
class _CalendarHeader extends StatelessWidget {
  final CalendarFormat calendarFormat;
  final ValueChanged<CalendarFormat> onFormatChanged;

  const _CalendarHeader({
    required this.calendarFormat,
    required this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TSizes.defaultSpace,
        vertical: TSizes.spaceBtwItems,
      ).copyWith(top: TSizes.appBarHeight), // Espacio para simular AppBar
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _CurrentDateHeader(),
          IconButton(
            icon: Icon(
              calendarFormat == CalendarFormat.week
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              color: TColors.white,
              size: TSizes.iconLg,
            ),
            tooltip: calendarFormat == CalendarFormat.week ? 'Mostrar mes' : 'Mostrar semana',
            onPressed: () {
              onFormatChanged(
                calendarFormat == CalendarFormat.week
                    ? CalendarFormat.month
                    : CalendarFormat.week,
              );
            },
          ),
        ],
      ),
    );
  }
}

// Encabezado con la fecha actual
class _CurrentDateHeader extends StatelessWidget {
  const _CurrentDateHeader();
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String formattedDate = DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(now);
    if (formattedDate.isNotEmpty) {
      formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoy',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: TColors.white,
            height: 1.1,
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

// Lista de sesiones para el día seleccionado
class _SelectedDaySessionsList extends StatelessWidget {
  final DateTime selectedDay;
  final List<Session> Function(DateTime) getEventsForDay;

  const _SelectedDaySessionsList({
    required this.selectedDay,
    required this.getEventsForDay,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDayEvents = getEventsForDay(selectedDay);
    if (selectedDayEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Text(
            'No hay entrenamientos programados para este día.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace)
               .copyWith(top: TSizes.sm, bottom: TSizes.defaultSpace),
      itemCount: selectedDayEvents.length,
      itemBuilder: (context, index) {
        final session = selectedDayEvents[index];
        final isPast = selectedDay.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
        return Padding(
          padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
          // Asumiendo que TrainingCard tiene constructor const si es posible
          child: TrainingCard(
            session: session,
            showBorder: false,
            isPast: isPast,
          ),
        );
      },
    );
  }
}
