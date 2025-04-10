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
import 'package:runap/utils/helpers/helper_functions.dart';

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
  // Mantener formato semanal por defecto como antes, pero sin toggle visible
  final CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<LinkedHashMap<DateTime, List<Session>>> _groupedEventsNotifier;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _groupedEventsNotifier = ValueNotifier(_groupSessionsByDay(widget.viewModel.trainingData!.dashboard.nextWeekSessions));
    widget.viewModel.addListener(_updateEvents);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_updateEvents);
    _groupedEventsNotifier.dispose();
    super.dispose();
  }

  void _updateEvents() {
    if (mounted && widget.viewModel.trainingData != null) {
       _groupedEventsNotifier.value = _groupSessionsByDay(widget.viewModel.trainingData!.dashboard.nextWeekSessions);
    } else if (mounted) {
       _groupedEventsNotifier.value = LinkedHashMap<DateTime, List<Session>>(equals: isSameDay, hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year);
    }
  }

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
        _focusedDay = focusedDay; // Actualizar también focusedDay al seleccionar
      });
    }
  }

  // Cambiar página (mes/semana)
  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      // Opcional: deseleccionar día al cambiar de página si se prefiere
      // _selectedDay = null;
    });
  }

  // Navegar a la página anterior/siguiente
  void _navigateToPreviousPage() {
    // Calcula el día para retroceder (una semana en este caso)
    final newFocusedDay = _focusedDay.subtract(const Duration(days: 7));
    _onPageChanged(newFocusedDay);
  }

  void _navigateToNextPage() {
    // Calcula el día para avanzar (una semana en este caso)
    final newFocusedDay = _focusedDay.add(const Duration(days: 7));
    _onPageChanged(newFocusedDay);
  }

  // Mostrar selector de fecha (implementación básica)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime.utc(DateTime.now().year - 5, 1, 1), // Rango ajustable
      lastDate: DateTime.utc(DateTime.now().year + 5, 12, 31),
      locale: const Locale('es', 'ES'),
       // Puedes personalizar los colores del DatePicker si es necesario
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: TColors.primaryColor, // color del header
                onPrimary: Colors.white, // color del texto en el header
                onSurface: TColors.black, // color del texto de los días
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: TColors.primaryColor, // color de los botones
                ),
              ),
            ),
            child: child!,
          );
        },
    );
    if (picked != null && !isSameDay(picked, _focusedDay)) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked; // Seleccionar también el día elegido
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final primaryColor = TColors.primaryColor;
    final lightTextColor = TColors.darkGrey; // Para texto normal
    final darkerTextColor = TColors.black; // Para texto más prominente

    // Contenedor principal blanco con bordes redondeados
    return Padding(
       padding: const EdgeInsets.only(top: kToolbarHeight + 10, left: 10, right: 10, bottom: 10), // Ajustar padding
       child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg), // Bordes redondeados
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: ClipRRect( // Para que el contenido respete los bordes redondeados
             borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
             child: Column(
              children: [
                // Nuevo Encabezado del Calendario
                _CalendarHeader(
                  focusedDay: _focusedDay,
                  onLeftArrowTap: _navigateToPreviousPage,
                  onRightArrowTap: _navigateToNextPage,
                  onDateTap: () => _selectDate(context), // Pasar la función para abrir DatePicker
                ),
                // Widget del Calendario con estilos actualizados
                ValueListenableBuilder<LinkedHashMap<DateTime, List<Session>>>(
                  valueListenable: _groupedEventsNotifier,
                  builder: (context, groupedEvents, _) {
                    return TableCalendar<Session>(
                      locale: 'es_ES',
                      firstDay: DateTime.utc(DateTime.now().year - 5, 1, 1), // Ajustar rango si es necesario
                      lastDay: DateTime.utc(DateTime.now().year + 5, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat, // Formato fijo (semanal)
                      eventLoader: _getEventsForDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      // onFormatChanged: (format) {}, // Ya no es necesario cambiar formato desde aquí
                      onPageChanged: _onPageChanged, // Usar nuestro manejador
                      calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          todayDecoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.3), // Color primario suave para hoy
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: primaryColor, // Color primario sólido para seleccionado
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: TextStyle(color: lightTextColor),
                          weekendTextStyle: TextStyle(color: lightTextColor), // Mismo color para finde
                          todayTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          // Estilo para marcadores de evento
                          markerDecoration: const BoxDecoration(
                            color: TColors.secondaryColor, // Usar color secundario para el punto
                            shape: BoxShape.circle,
                           ),
                          markerSize: 5.0,
                          markersAlignment: Alignment.bottomCenter,
                          markersOffset: const PositionedOffset(bottom: 3), // Ajustar posición vertical del marcador
                          canMarkersOverflow: false, // Evitar que se salgan
                      ),
                      headerStyle: const HeaderStyle(
                          // Ocultar header por defecto de TableCalendar
                          formatButtonVisible: false,
                          titleCentered: true, // Aunque lo ocultaremos, mejor centrado
                          titleTextStyle: TextStyle(fontSize: 0), // Ocultar título
                          leftChevronVisible: false, // Ocultar flechas por defecto
                          rightChevronVisible: false, // Ocultar flechas por defecto
                          headerPadding: EdgeInsets.zero, // Sin padding
                          headerMargin: EdgeInsets.zero,
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                         // Estilo para los nombres de los días (L, M, X...)
                         weekdayStyle: TextStyle(color: darkerTextColor, fontWeight: FontWeight.bold, fontSize: 12),
                         weekendStyle: TextStyle(color: darkerTextColor, fontWeight: FontWeight.bold, fontSize: 12), // Mismo estilo finde
                      ),
                      calendarBuilders: CalendarBuilders(
                        // No usamos el markerBuilder anterior con iconos, solo el punto por defecto
                        // Si se quiere volver a los iconos, se puede reactivar aquí
                      ),
                    );
                  },
                ),
                const Divider(height: 1, thickness: 1, indent: TSizes.defaultSpace, endIndent: TSizes.defaultSpace,), // Divisor sutil
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                // Lista de sesiones para el día seleccionado
                Expanded(
                  child: _SelectedDaySessionsList(
                    selectedDay: _selectedDay ?? _focusedDay, // Usar focusedDay si no hay selección
                    getEventsForDay: _getEventsForDay,
                  ),
                ),
              ],
                     ),
          ),
       ),
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

// Encabezado del Calendario (rediseñado)
class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final VoidCallback onDateTap; // Callback para tocar la fecha

  const _CalendarHeader({
    required this.focusedDay,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    // Formatear el mes y año
    final headerText = DateFormat.yMMMM('es_ES').format(focusedDay);

    return Padding(
      // Padding ajustado para el nuevo diseño
      padding: const EdgeInsets.symmetric(vertical: TSizes.md, horizontal: TSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flecha Izquierda
          IconButton(
            icon: const Icon(Icons.chevron_left, color: TColors.darkGrey, size: 28),
            onPressed: onLeftArrowTap,
            tooltip: 'Semana anterior',
          ),
          // Botón central con Fecha (Mes y Año)
          TextButton.icon(
             icon: const Icon(Icons.calendar_today_outlined, size: 16, color: TColors.darkGrey),
             label: Text(
                headerText[0].toUpperCase() + headerText.substring(1), // Capitalizar
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: TColors.black),
             ),
             onPressed: onDateTap, // Llama al callback para abrir el selector
             style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
             ),
          ),
          // Flecha Derecha
          IconButton(
            icon: const Icon(Icons.chevron_right, color: TColors.darkGrey, size: 28),
            onPressed: onRightArrowTap,
            tooltip: 'Semana siguiente',
          ),
        ],
      ),
    );
  }
}

// Encabezado con la fecha actual (Ya no se usa directamente, eliminado)
// class _CurrentDateHeader extends StatelessWidget { ... }


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
    final today = DateTime.now();
    final isTodaySelected = isSameDay(selectedDay, today);
    final bool isPastDay = selectedDay.isBefore(DateTime(today.year, today.month, today.day));

    String titleText;
    if (isTodaySelected) {
      titleText = 'Entrenamientos de Hoy';
    } else {
      // Formatear la fecha seleccionada
      String formattedDate = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(selectedDay);
       if (formattedDate.isNotEmpty) {
           formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);
       }
       titleText = formattedDate; // Mostrar la fecha seleccionada
    }


    if (selectedDayEvents.isEmpty) {
      return Column( // Envolver en columna para añadir título aunque esté vacío
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: TSizes.defaultSpace, right: TSizes.defaultSpace, top: TSizes.md, bottom: TSizes.lg),
            child: Text(titleText, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded( // Para que el texto centrado ocupe el espacio restante
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: Text(
                  'Día de descanso. ¡No hay entrenamientos programados!', // Mensaje modificado
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TColors.darkGrey),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Si hay eventos, mostrar título y luego la lista
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Padding(
           padding: const EdgeInsets.only(left: TSizes.defaultSpace, right: TSizes.defaultSpace, top: TSizes.md, bottom: TSizes.md),
           child: Text(titleText, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
         ),
         Expanded(
           child: ListView.builder(
              // Quitar padding horizontal de la lista, añadirlo al título y a cada item
              padding: const EdgeInsets.only(bottom: TSizes.defaultSpace, top: 0),
              itemCount: selectedDayEvents.length,
              itemBuilder: (context, index) {
                final session = selectedDayEvents[index];
                // Asegurarse que `isPast` se calcula correctamente respecto al día seleccionado
                final isPastSessionDay = selectedDay.isBefore(DateTime(today.year, today.month, today.day));
                return Padding(
                  // Añadir padding horizontal a cada tarjeta
                  padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems, left: TSizes.defaultSpace, right: TSizes.defaultSpace),
                  child: TrainingCard(
                    session: session,
                    showBorder: true, // Mostrar un borde ligero en la tarjeta
                    isPast: isPastSessionDay, // Pasar si el día de la sesión es pasado
                  ),
                );
              },
            ),
         ),
       ],
    );
  }
}

// Eliminar el import no usado si existe
// import 'package:runap/utils/constants/image_strings.dart';
// import 'package:runap/utils/constants/texts.dart';
// import 'package:runap/utils/device/device_utility.dart';
// import 'package:runap/utils/http/http_client.dart';
// import 'package:runap/utils/local_storage/storage_utility.dart';
// import 'package:runap/utils/logging/logger.dart';
// import 'package:runap/utils/theme/theme.dart';
// import 'package:runap/utils/validators/validation.dart';

// Asegurarse de que el import de HelperFunctions está presente si se usa
// import 'package:runap/utils/helpers/helper_functions.dart';
