import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class EmergencyService {
  // Contact d'urgence (Proche ou Médecin)
  static const String contactUrgence = "0711081247";
  
  static const String numSecours = "185";

  static Future<void> triggerFullEmergency(String patientName) async {
    Position? position;
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.always || 
            permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5)
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print("Erreur GPS : $e");
    }

    String mapLink = position != null 
        ? "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}"
        : "GPS non disponible.";
    
    String message = "URGENCE SmartBreath !\n$patientName a besoin d'aide immédiate.\nPosition : $mapLink";
    
    final String separator = kIsWeb || !defaultTargetPlatform.toString().contains('iOS') ? '?' : '&';
    final Uri smsUri = Uri.parse('sms:$contactUrgence${separator}body=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (kDebugMode) print(" Impossible de lancer le gestionnaire de SMS");
      }
    } catch (e) {
      if (kDebugMode) print("Erreur lancement SMS : $e");
    }
    
    final Uri telUri = Uri(scheme: 'tel', path: numSecours);

    await Future.delayed(const Duration(seconds: 1));

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri, mode: LaunchMode.externalApplication);
      } else {
        if (kDebugMode) print("Impossible de lancer l'appel au $numSecours");
      }
    } catch (e) {
      if (kDebugMode) print("Erreur lancement Appel : $e");
    }
  }
}