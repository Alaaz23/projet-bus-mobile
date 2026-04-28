import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bus_tracking/utils/constants.dart';

/// Service centralisé pour accéder au backend Spring Boot (base de données PostgreSQL)
///
/// Architecture :
///   Flutter App ──HTTP──► Spring Boot :8081 ──JPA──► PostgreSQL :5432 (db: bus)
///
/// Endpoints disponibles :
///   POST /salaries/login           → Authentification salarié
///   POST /salaries/reset-password  → Réinitialisation mot de passe
///   GET  /stations/{id}            → Détails d'une station
///   GET  /buses/{id}               → Détails d'un bus
///   GET  /tragets/stations/{id}    → Trajet d'une station
///   POST /feedbacks/add            → Ajouter un feedback

class ApiService {
  // ─── Helpers HTTP ─────────────────────────────────────────────────────────

  /// En-têtes JSON par défaut
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─── AUTHENTIFICATION (unifié Admin + Salarié) ────────────────────────────

  /// Authentification unifiée via /auth/login
  /// Vérifie d'abord la table admins, puis la table salaries
  /// Retourne AuthResponse {success, message, username, displayName, role, token}
  static Future<Map<String, dynamic>> authLogin(
      String matricule, String password) async {
    final url = Uri.parse('$kBackendBaseUrl/auth/login');
    try {
      final response = await http
          .post(url,
              headers: _headers,
              body: json.encode({
                'matricule': matricule,
                'password': password,
              }))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException(
            'Erreur serveur: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Connexion impossible au serveur backend.\n'
          'Vérifiez que le serveur Spring Boot est démarré.\n'
          'Erreur: $e');
    }
  }

  // ─── SALARIÉS ─────────────────────────────────────────────────────────────

  /// Authentification d'un salarié par matricule + mot de passe
  static Future<Map<String, dynamic>> login(
      String matricule, String password) async {
    final url = Uri.parse('$kBackendBaseUrl/salaries/login');
    try {
      final response = await http
          .post(url,
              headers: _headers,
              body: json.encode({
                'matricule': matricule,
                'password': password,
              }))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException(
            'Erreur serveur: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Connexion impossible au serveur backend.\n'
          'Vérifiez que le serveur Spring Boot est démarré sur le port 8081.\n'
          'Erreur: $e');
    }
  }

  /// Réinitialisation du mot de passe
  static Future<bool> resetPassword(
      String matricule, String newPassword) async {
    final url = Uri.parse('$kBackendBaseUrl/salaries/reset-password');
    final response = await http.post(url,
        headers: _headers,
        body: json.encode({
          'matricule': matricule,
          'password': newPassword,
        }));
    return response.statusCode == 200;
  }

  // ─── STATIONS ─────────────────────────────────────────────────────────────

  /// Récupère les détails d'une station par son ID
  static Future<Map<String, dynamic>> getStation(int stationId) async {
    final url = Uri.parse('$kBackendBaseUrl/stations/$stationId');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw ApiException('Station introuvable', response.statusCode);
  }

  // ─── BUS ──────────────────────────────────────────────────────────────────

  /// Récupère les détails d'un bus par son ID
  static Future<Map<String, dynamic>> getBus(int busId) async {
    final url = Uri.parse('$kBackendBaseUrl/buses/$busId');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw ApiException('Bus introuvable', response.statusCode);
  }

  // ─── TRAJETS ──────────────────────────────────────────────────────────────

  /// Récupère le trajet associé à une station
  static Future<List<dynamic>> getTrajetByStation(int stationId) async {
    final url =
        Uri.parse('$kBackendBaseUrl/tragets/stations/$stationId');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw ApiException('Trajet introuvable', response.statusCode);
  }

  // ─── FEEDBACKS ────────────────────────────────────────────────────────────

  /// Envoie un feedback vers la base de données
  static Future<bool> addFeedback({
    required String nom,
    required String prenom,
    required String commentaire,
    required int rating,
  }) async {
    final url = Uri.parse('$kBackendBaseUrl/feedbacks/add');
    final response = await http.post(url,
        headers: _headers,
        body: json.encode({
          'nom': nom,
          'prenom': prenom,
          'commentaire': commentaire,
          'rating': rating,
        }));
    return response.statusCode == 200 || response.statusCode == 201;
  }
}

/// Exception personnalisée pour les erreurs API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (code: $statusCode)';
}


