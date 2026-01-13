import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class EmergencyService {
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
      debugPrint("Erreur GPS : $e");
    }

    String mapLink = position != null 
        ? "\nPosition : https://www.google.com/maps?q=${position.latitude},${position.longitude}"
        : "\nPosition non disponible (GPS désactivé).";
    
    String message = "URGENCE SmartBreath ! $patientName a besoin d'aide immédiate.$mapLink";
    
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: contactUrgence,
      queryParameters: {'body': message},
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        debugPrint("Impossible de lancer le gestionnaire de SMS");
      }
    } catch (e) {
      debugPrint(" Erreur lancement SMS : $e");
    }
    
    final Uri telUri = Uri(scheme: 'tel', path: numSecours);
    
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        debugPrint("Impossible de lancer l'appel au $numSecours");
      }
    } catch (e) {
      debugPrint(" Erreur lancement Appel : $e");
    }
  }
}