import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug - Almacenamiento Local')),
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
    final getStorage = GetStorage();
    for (var key in getStorage.getKeys()) {
      result['GetStorage: $key'] = getStorage.read(key.toString());
    }

    // SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    for (var key in prefs.getKeys()) {
      result['SharedPrefs: $key'] = prefs.get(key);
    }

    return result;
  }
}
