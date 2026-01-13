import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _patientId;
  String? _patientName;

  String? get patientId => _patientId;
  String? get patientName => _patientName;

  void login(String id, String name) {
    _patientId = id;
    _patientName = name;
    notifyListeners();
  }

  void logout() {
    _patientId = null;
    _patientName = null;
    notifyListeners();
  }
}