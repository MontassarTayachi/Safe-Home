import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safehome/services/config_service.dart';

class ApiService {
  // Get the last image
  static Future<Map<String, dynamic>> fetchLastImage() async {
    try {
      final baseUrl = await ConfigService.getApiBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/images/last'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Aucune image trouvée');
      } else {
        throw Exception('Erreur de chargement: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching image: $e');
      throw Exception('Erreur réseau: $e');
    }
  }
  
  // Get all images
  static Future<List<dynamic>> fetchAllImages() async {
    try {
      final baseUrl = await ConfigService.getApiBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/images'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur de chargement des images: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all images: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  // Register a new user
  static Future<Map<String, dynamic>> registerUser(String name, String password, String token) async {
    try {
      final baseUrl = await ConfigService.getApiBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'password': password,
          'token': token,
        }),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        final errorMsg = jsonDecode(response.body)['message'] ?? 'Erreur d\'authentification';
        throw Exception(errorMsg);
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? 'Erreur inconnue';
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Error registering user: $e');
      throw Exception('Erreur: $e');
    }
  }
}
