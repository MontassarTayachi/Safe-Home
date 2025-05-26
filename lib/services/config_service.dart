import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _baseUrlKey = 'api_base_url';
  static const String _defaultBaseUrl = 'https://backend-safehome.onrender.com';

  // Obtenir l'URL de base complète
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  // Définir une nouvelle URL de base complète
  static Future<bool> setBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_baseUrlKey, baseUrl);
  }
  
  // Méthodes pour obtenir l'hôte et le port à partir de l'URL de base
  static Future<String> getIpAddress() async {
    final baseUrl = await getBaseUrl();
    try {
      final uri = Uri.parse(baseUrl);
      return uri.host;
    } catch (e) {
      return 'backend-safehome.onrender.com';
    }
  }

  static Future<String> getPort() async {
    final baseUrl = await getBaseUrl();
    try {
      final uri = Uri.parse(baseUrl);
      return uri.port.toString() == '0' ? '' : uri.port.toString();
    } catch (e) {
      return '';
    }
  }
  
  // Méthodes pour modifier l'URL de base à partir de l'IP et du port
  static Future<bool> setIpAddress(String ipAddress) async {
    String currentBaseUrl = await getBaseUrl();
    Uri currentUri;
    try {
      currentUri = Uri.parse(currentBaseUrl);
    } catch (e) {
      // Utiliser le schéma par défaut si l'URL actuelle est invalide
      currentUri = Uri.parse(_defaultBaseUrl);
    }
    
    // Conserver le protocole d'origine (http/https)
    String scheme = currentUri.scheme;
    String port = currentUri.port.toString() == '0' ? '' : ':${currentUri.port}';
    
    // Créer la nouvelle URL de base
    String newBaseUrl = '$scheme://$ipAddress$port';
    return await setBaseUrl(newBaseUrl);
  }
  
  static Future<bool> setPort(String port) async {
    String currentBaseUrl = await getBaseUrl();
    Uri currentUri;
    try {
      currentUri = Uri.parse(currentBaseUrl);
    } catch (e) {
      // Utiliser le schéma par défaut si l'URL actuelle est invalide
      currentUri = Uri.parse(_defaultBaseUrl);
    }
    
    // Conserver le protocole et l'hôte d'origine
    String scheme = currentUri.scheme;
    String host = currentUri.host;
    
    // Créer la nouvelle URL de base
    String newBaseUrl = port.isEmpty ? '$scheme://$host' : '$scheme://$host:$port';
    return await setBaseUrl(newBaseUrl);
  }

  // Obtenir l'URL de l'API complète (méthode principale utilisée par les services)
  static Future<String> getApiBaseUrl() async {
    return await getBaseUrl();
  }
}
