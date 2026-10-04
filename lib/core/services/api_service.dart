import 'package:eda_launch_mobile/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  // ==============================
  // GESTION DU TOKEN
  // ==============================

  // Sauvegarder le token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Récupérer le token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Supprimer le token (déconnexion)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Vérifier si connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // ==============================
  // HEADERS
  // ==============================

  // Headers sans token (routes publiques)
  static Map<String, String> get publicHeaders => {
    'Content-Type': 'application/json',
  };

  // Headers avec token (routes protégées)
  static Future<Map<String, String>> get privateHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==============================
  // REQUÊTES HTTP
  // ==============================

  // GET — récupérer des données
  static Future<Map<String, dynamic>> get(String url) async {
    try {
      final headers = await privateHeaders;
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      return await _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // POST — envoyer des données
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool isPublic = false,
  }) async {
    try {
      final headers = isPublic ? publicHeaders : await privateHeaders;
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return await _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // PUT — modifier des données
  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await privateHeaders;
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return await _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // PATCH — modifier partiellement
  static Future<Map<String, dynamic>> patch(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await privateHeaders;
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      return await _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // DELETE — supprimer des données
  static Future<Map<String, dynamic>> delete(String url) async {
    try {
      final headers = await privateHeaders;
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      return await _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ==============================
  // GESTION DES RÉPONSES
  // ==============================

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': body['data'],
          'message': body['message'],
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        final body401 = body as Map<String, dynamic>;
        final message = body401['message'] ?? '';
        
        // Si c'est une erreur de credentials (login), on retourne juste l'erreur
        if (message.toLowerCase().contains('incorrect') ||
            message.toLowerCase().contains('invalide') ||
            message.toLowerCase().contains('introuvable') ||
            message.toLowerCase().contains('mot de passe') ||
            message.toLowerCase().contains('compte')){
          return {
            'success': false,
            'message': message,
            'statusCode': 401,
          };
        }
        
        // Sinon token expiré → rediriger
        await deleteToken();
        redirectToLogin();
        return {
          'success': false,
          'message': 'Votre session a expiré. Veuillez vous reconnecter.',
          'statusCode': 401,
          'tokenExpired': true,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Une erreur est survenue',
          'errors': body['errors'],
          'statusCode': response.statusCode,
        };
      }
  }

  static Map<String, dynamic> _handleError(dynamic error) {
      print('❌ Erreur API: $error'); // ← ajoute
    String message = 'Erreur de connexion. Vérifiez votre internet.';

    if (error.toString().contains('TimeoutException')) {
      message = 'La connexion a expiré. Réessayez.';
    }

    return {
      'success': false,
      'message': message,
      'statusCode': 0,
    };
  }
}
