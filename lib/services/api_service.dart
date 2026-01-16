import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000";

  static Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  static Future<Map<String, dynamic>> analyzeHealth(Map<String, dynamic> sensorData) async {
    try {
      final response = await post("/analyze", sensorData);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Échec de l'analyse IA: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erreur lors de l'analyse santé: $e");
    }
  }

  static Future<bool> sendFeedback(int dataId, int outcome, String comment) async {
    try {
      final data = {
        "data_id": dataId,
        "actual_outcome": outcome,
        "comment": comment,
      };
      final response = await post("/feedback", data);
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print("Erreur envoi feedback: $e");
      return false;
    }
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      _logRequest("POST", endpoint, data);
      final response = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception("Erreur réseau POST: $e");
    }
  }

  static Future<http.Response> get(String endpoint) async {
    try {
      _logRequest("GET", endpoint);
      final response = await http.get(
        Uri.parse("$baseUrl$endpoint"),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception("Erreur réseau GET: $e");
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    try {
      _logRequest("PUT", endpoint, data);
      final response = await http.put(
        Uri.parse("$baseUrl$endpoint"),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception("Erreur réseau PUT: $e");
    }
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      _logRequest("PATCH", endpoint, data);
      final response = await http.patch(
        Uri.parse("$baseUrl$endpoint"),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception("Erreur réseau PATCH: $e");
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    try {
      _logRequest("DELETE", endpoint);
      final response = await http.delete(
        Uri.parse("$baseUrl$endpoint"),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return _handleResponse(response);
    } catch (e) {
      throw Exception("Erreur réseau DELETE: $e");
    }
  }

  static void _logRequest(String method, String endpoint, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      print(" API $method: $baseUrl$endpoint");
      if (data != null) print(" Body: ${jsonEncode(data)}");
    }
  }

  static http.Response _handleResponse(http.Response response) {
    if (kDebugMode) {
      print("Status: ${response.statusCode}");
      if (response.statusCode >= 400) {
        print("Erreur Serveur: ${response.body}");
      } else {
        print("Réponse: ${response.body}");
      }
    }
    return response;
  }
}