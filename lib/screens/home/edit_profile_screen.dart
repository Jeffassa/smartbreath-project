import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> currentData;

  const EditProfileScreen({super.key, required this.patientId, required this.currentData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _tailleController;
  late TextEditingController _poidsController;
  late TextEditingController _pathoController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tailleController = TextEditingController(text: widget.currentData['taille'].toString());
    _poidsController = TextEditingController(text: widget.currentData['poids'].toString());
    _pathoController = TextEditingController(text: widget.currentData['pathologie']);
  }

  void _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final response = await ApiService.post("/profile/${widget.patientId}", { // Note: Utilisez ApiService.put si vous l'avez créé, sinon adaptez ApiService
        "taille_cm": int.parse(_tailleController.text),
        "poids_kg": double.parse(_poidsController.text),
        "pathologie": _pathoController.text,
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true); // Retourne 'true' pour rafraîchir le profil
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la sauvegarde")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier le profil"), backgroundColor: const Color(0xFF0089BA)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _tailleController, decoration: const InputDecoration(labelText: "Taille (cm)"), keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            TextField(controller: _poidsController, decoration: const InputDecoration(labelText: "Poids (kg)"), keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            TextField(controller: _pathoController, decoration: const InputDecoration(labelText: "Pathologie")),
            const SizedBox(height: 30),
            _isSaving 
              ? const CircularProgressIndicator() 
              : ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0089BA), minimumSize: const Size(double.infinity, 50)),
                  child: const Text("ENREGISTRER", style: TextStyle(color: Colors.white)),
                )
          ],
        ),
      ),
    );
  }
}