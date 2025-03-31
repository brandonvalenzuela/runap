import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:runap/features/dashboard/models/dashboard_model.dart';
import 'package:runap/features/map/controller/map_controller.dart';
import 'package:runap/features/map/models/workout_goal.dart';
import 'package:runap/utils/constants/colors.dart';
import 'package:runap/utils/constants/sizes.dart';

class MapScreen extends StatelessWidget {
  final WorkoutGoal? initialWorkoutGoal;
  final Session? sessionToUpdate;
  
  // Añadir GlobalKey para medir el panel de información
  final GlobalKey infoPanelKey = GlobalKey();

  MapScreen({
    super.key,
    this.initialWorkoutGoal,
    this.sessionToUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Asegurarse de imprimir información de depuración
    print(
        "🗺️ MapScreen - Construyendo con sessionToUpdate: ${sessionToUpdate?.workoutName}");
    print(
        "🗺️ MapScreen - initialWorkoutGoal: ${initialWorkoutGoal?.targetDistanceKm}km");
    // Inyectar el controlador
    final controller = Get.put(MapController(
      initialSession: sessionToUpdate,
      initialWorkoutGoal: initialWorkoutGoal,
    ));

    // Añadir depuración adicional
    print("🗺️ MapScreen - Posición actual: ${controller.workoutData.value.currentPosition}");
    print("🗺️ MapScreen - Polilíneas: ${controller.workoutData.value.polylines.length}");

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          if (controller.sessionToUpdate.value != null) {
            return Text(controller.sessionToUpdate.value!.workoutName);
          }
          return Text('Entrenamiento');
        }),
        actions: [
          Obx(() {
            return IconButton(
              icon: Icon(Icons.flag),
              onPressed: controller.workoutData.value.isWorkoutActive
                  ? null
                  : controller.toggleGoalSelector,
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          Obx(() => _buildMap(controller)),

          // Panel de información inferior
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() => _buildInfoPanel(controller)),
          ),

          // Selector de objetivos (condicional)
          Obx(() {
            if (controller.showGoalSelector.value) {
              return _buildGoalSelector(controller);
            }
            return SizedBox.shrink();
          }),

          // Indicador de carga
          Obx(() {
            if (controller.isLoading.value) {
              return Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return SizedBox.shrink();
          }),

          // Indicador de guardado
          Obx(() {
            if (controller.isSaving.value) {
              return Container(
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
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildMap(MapController controller) {
    // Obtener dimensiones de la pantalla
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    
    // Estimar altura del panel de información
    final infoPanelHeight = screenHeight * 0.33;
    
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: controller.workoutData.value.currentPosition ??
                LatLng(20.651464, -103.392958),
            zoom: 17.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          polylines: controller.workoutData.value.polylines,
          onMapCreated: (GoogleMapController mapController) {
            controller.setMapControllerInstance(mapController);
            
            // Aplicar estilo personalizado para running
            mapController.setMapStyle('''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "administrative.neighborhood",
    "stylers": [
      {
        "visibility": "simplified"
      }
    ]
  },
  {
    "featureType": "poi",
    "stylers": [
      {
        "visibility": "simplified"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.attraction",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.business",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.government",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.medical",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c1e7c1"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "simplified"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "poi.place_of_worship",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.school",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.sports_complex",
    "stylers": [
      {
        "visibility": "simplified"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]
            ''');
            
            // Forzar actualización del mapa
            controller.forceMapUpdate();
          },
          padding: EdgeInsets.only(
            top: appBarHeight,
            bottom: infoPanelHeight,
          ),
          // Reducir el uso de memoria para carga más rápida
          liteModeEnabled: false, // Cambiar a true en dispositivos de gama baja
          // Optimizar para rendimiento
          tiltGesturesEnabled: false,
          compassEnabled: false,
          indoorViewEnabled: false,
          trafficEnabled: false,
          buildingsEnabled: false,
        ),
        // Botón de centrado
        Positioned(
          right: 16,
          bottom: infoPanelHeight + 20, // Posicionarlo justo encima del panel
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            child: Icon(Icons.my_location, color: TColors.primaryColor),
            onPressed: controller.resetMapView,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(MapController controller) {
    return Container(
      key: infoPanelKey,
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
      child: ListView(
        shrinkWrap: true,
        cacheExtent: 200,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Añadir indicador de calidad GPS
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Obx(() => Text(
                "GPS: ${controller.getGpsQualityIndicator()}",
                style: TextStyle(fontSize: 12),
              )),
            ],
          ),
          // Información del objetivo (si hay uno establecido)
          if (controller.workoutData.value.goal != null) ...[
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
                  value:
                      '${controller.workoutData.value.goal!.targetDistanceKm} km',
                  label: 'Distancia',
                ),
                _buildMetricTile(
                  icon: Icons.timer,
                  value:
                      '${controller.workoutData.value.goal!.targetTimeMinutes} min',
                  label: 'Tiempo',
                ),
                _buildProgressTile(controller),
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
                    '${(controller.workoutData.value.distanceMeters / 1000).toStringAsFixed(2)} km',
                label: 'Distancia',
              ),
              _buildMetricTile(
                icon: Icons.timer,
                value: controller.getFormattedElapsedTime(),
                label: 'Tiempo',
              ),
              _buildMetricTile(
                icon: Icons.speed,
                value: controller.workoutData.value.isWorkoutActive
                    ? controller.workoutData.value
                        .getPaceFormatted() // Usar el nuevo método
                    : "--:--",
                label: 'Ritmo (min/km)', // Cambiar la etiqueta para claridad
              ),
            ],
          ),
          SizedBox(height: 16),

          // Botón de inicio/parada
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.workoutData.value.isWorkoutActive
                  ? controller.stopWorkout
                  : controller.startWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.workoutData.value.isWorkoutActive
                    ? Colors.red
                    : TColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                controller.workoutData.value.isWorkoutActive
                    ? 'DETENER'
                    : 'INICIAR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Añadir botón de opciones avanzadas cuando el entrenamiento está activo
          if (controller.workoutData.value.isWorkoutActive) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Mostrar opciones avanzadas
                Get.bottomSheet(
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Opciones avanzadas",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text("Reiniciar visualización"),
                          subtitle: Text("Centra el mapa en tu posición actual"),
                          onTap: () {
                            controller.resetMapView();
                            Get.back();
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.route),
                          title: Text("Optimizar ruta"),
                          subtitle: Text("Elimina puntos redundantes para mejorar la precisión"),
                          onTap: () {
                            controller.workoutData.value.optimizeRoute();
                            controller.workoutData.refresh();
                            Get.back();
                          },
                        ),
                        // Añadir opción para cambiar estilo del mapa
                        ListTile(
                          leading: Icon(Icons.map),
                          title: Text("Estilo del mapa"),
                          subtitle: Text("Cambia entre estilos de visualización"),
                          onTap: () {
                            _showMapStyleOptions(controller);
                            Get.back();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Text("Opciones avanzadas"),
            ),
          ],
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
        Icon(icon, color: TColors.primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTile(MapController controller) {
    // Calcular el progreso
    final elapsedSeconds = controller.getElapsedTimeSeconds();
    final targetSeconds =
        controller.workoutData.value.goal!.targetTimeMinutes * 60;
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

  Widget _buildGoalSelector(MapController controller) {
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
              ...controller.availableGoals
                  .map((goal) => _buildGoalOption(controller, goal)),
              SizedBox(height: 16),
              TextButton(
                onPressed: controller.toggleGoalSelector,
                child: Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalOption(MapController controller, WorkoutGoal goal) {
    final isSelected = controller.workoutData.value.goal?.targetDistanceKm ==
            goal.targetDistanceKm &&
        controller.workoutData.value.goal?.targetTimeMinutes ==
            goal.targetTimeMinutes;

    return GestureDetector(
      onTap: () => controller.setWorkoutGoal(goal),
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

  String getGpsQualityIndicator(MapController controller) {
    if (controller.workoutData.value.previousPosition == null) return "⚪"; // Sin datos
    
    double accuracy = controller.workoutData.value.previousPosition!.accuracy;
    
    if (accuracy <= 10) return "🟢"; // Excelente
    if (accuracy <= 20) return "🟡"; // Buena
    if (accuracy <= 40) return "🟠"; // Regular
    return "🔴"; // Mala
  }

  // Y luego añade un método para obtener la altura del panel
  double getInfoPanelHeight() {
    if (infoPanelKey.currentContext != null) {
      final RenderBox box = infoPanelKey.currentContext!.findRenderObject() as RenderBox;
      return box.size.height;
    }
    return 220; // Valor por defecto si no se puede medir
  }

  void _showMapStyleOptions(MapController controller) {
    Get.dialog(
      AlertDialog(
        title: Text("Estilo del mapa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Running (Simple)"),
              leading: Icon(Icons.run_circle_outlined, color: TColors.primaryColor),
              onTap: () {
                controller.setMapStyle("running_simple");
                Get.back();
              },
            ),
            ListTile(
              title: Text("Running (Detallado)"),
              leading: Icon(Icons.directions_run, color: TColors.primaryColor),
              onTap: () {
                controller.setMapStyle("running_detailed");
                Get.back();
              },
            ),
            ListTile(
              title: Text("Terreno"),
              leading: Icon(Icons.terrain, color: Colors.green),
              onTap: () {
                controller.setMapStyle("terrain");
                Get.back();
              },
            ),
            ListTile(
              title: Text("Noche"),
              leading: Icon(Icons.nightlight_round, color: Colors.blueGrey),
              onTap: () {
                controller.setMapStyle("night");
                Get.back();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancelar"),
          ),
        ],
      ),
    );
  }
}
