import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:runap/common/widgets/appbar/appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:runap/utils/device/device_utility.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        leadingOnPressed: () => Get.back(),
        title: Text('Debug - Almacenamiento Local', style: Theme.of(context).textTheme.headlineSmall),
      ),
      
      body: FutureBuilder(
        future: _getStorageData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final Map<String, dynamic> data =
              snapshot.data as Map<String, dynamic>;

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final key = data.keys.elementAt(index);
              final value = data[key];

              return ListTile(
                title: Text(key),
                subtitle: Text(value.toString()),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    TDiviceUtility.vibrateMedium();
                    // Eliminar el valor
                    final storage = GetStorage();
                    await storage.remove(key);
                    // Refrescar la pantalla
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.delete_sweep),
        onPressed: () async {
          TDiviceUtility.vibrateMedium();
          // Limpiar todo el almacenamiento
          final storage = GetStorage();
          await storage.erase();
          // Refrescar la pantalla
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getStorageData() async {
    Map<String, dynamic> result = {};

    // GetStorage
    try {
      final getStorage = GetStorage();
      final keys = getStorage.getKeys();
      if (keys != null) {
        for (var key in keys) {
          result['GetStorage: $key'] = getStorage.read(key.toString());
        }
      } else {
        result['GetStorage'] = 'No keys found';
      }
    } catch (e) {
      result['GetStorage: Error'] = e.toString();
    }

    // SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      for (var key in prefs.getKeys()) {
        result['SharedPrefs: $key'] = prefs.get(key);
      }
    } catch (e) {
      result['SharedPrefs: Error'] = e.toString();
    }

    // Workout JSON Files
    try {
      final directory = await getApplicationDocumentsDirectory();
      final workoutsPath = '${directory.path}/workouts';
      final workoutsDir = Directory(workoutsPath);

      if (await workoutsDir.exists()) {
        final List<FileSystemEntity> entities = workoutsDir.listSync();
        final List<File> workoutFiles = entities.whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList();
        
        if (workoutFiles.isEmpty) {
          result['WorkoutFiles'] = 'No workout JSON files found in $workoutsPath';
        } else {
          result['WorkoutFiles_Path'] = workoutsPath;
          for (var file in workoutFiles) {
            String filename = file.path.split(Platform.pathSeparator).last;
            try {
              String content = file.readAsStringSync();
              result['WorkoutFile: $filename'] = content;
            } catch (e) {
              result['WorkoutFile: $filename'] = 'Error reading file: ${e.toString()}';
            }
          }
        }
      } else {
        result['WorkoutFiles'] = 'Workouts directory does not exist: $workoutsPath';
      }
    } catch (e) {
      result['WorkoutFiles: Error'] = e.toString();
    }

    return result;
  }
}
