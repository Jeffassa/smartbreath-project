import 'package:flutter/material.dart';
import '/services/api_service.dart';  // ← À ADAPTER à ton ApiClient

class FeedbackWidget extends StatelessWidget {
  final int dataId;

  // ← CONSTRUCTEUR CORRIGÉ (doit être statique)
  const FeedbackWidget({super.key, required this.dataId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Alerte de santé"),
      content: const Text("L'IA remarque une anomalie. Comment vous sentez-vous ?"),
      actions: [
        ElevatedButton(
          onPressed: () {
            // ← REMPLACÉ par ton ApiClient
            // ApiClient().sendFeedback(dataId, 0, "Fausse alerte");
            Navigator.pop(context);
          },
          child: const Text("Je vais bien"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            // ← REMPLACÉ par ton ApiClient
            // ApiClient().sendFeedback(dataId, 1, "Crise confirmée");
            Navigator.pop(context);
          },
          child: const Text("Je me sens mal"),
        ),
      ],
    );
  }
}
