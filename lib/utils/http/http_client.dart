import 'dart:convert';
import 'package:http/http.dart' as http;

class THttpHelper {
  static const String _baseUrl =
      'https://runapi-gwfuaxbuc7gbfacu.canadacentral-01.azurewebsites.net'; // Replace with your API base URL 
  // Helper method to make GET requests
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));

    if (response.statusCode == 200) {
      return _handleResponse(response);
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Helper method to make POST requests
  static Future<Map<String, dynamic>> post(
      String endpoint, dynamic data) async {
    final response = await http.post(Uri.parse('$_baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data));

    if (response.statusCode == 201) {
      return _handleResponse(response);
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Helper method to make PUT requests
  static Future<Map<String, dynamic>> put(String endpoint, dynamic data) async {
    final response = await http.put(Uri.parse('$_baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data));

    if (response.statusCode == 200) {
      return _handleResponse(response);
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Helper method to make DELETE requests
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$endpoint'));

    if (response.statusCode == 200) {
      return _handleResponse(response);
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Handle the HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}
