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
    _tailleController = TextEditingController(
        text: (widget.currentData['taille_cm'] ?? widget.currentData['taille'] ?? "").toString());
    _poidsController = TextEditingController(
        text: (widget.currentData['poids_kg'] ?? widget.currentData['poids'] ?? "").toString());
    _pathoController = TextEditingController(
        text: (widget.currentData['pathologie'] ?? "").toString());
  }

  @override
  void dispose() {
    _tailleController.dispose();
    _poidsController.dispose();
    _pathoController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    if (_tailleController.text.isEmpty || _poidsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez remplir la taille et le poids")));
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final response = await ApiService.put("/profile/${widget.patientId}", {
        "taille_cm": int.tryParse(_tailleController.text) ?? 0,
        "poids_kg": double.tryParse(_poidsController.text) ?? 0.0,
        "pathologie": _pathoController.text,
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("IA Recalibrée avec succès !"), backgroundColor: Colors.green)
        );
        
        Navigator.pop(context, true); 
      } else {
        throw Exception("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de recalibrage : $e"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0089BA);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Recalibrage de l'IA", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.psychology, size: 80, color: primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              "Mettez à jour vos constantes pour affiner les prédictions du modèle XGBoost.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 40),
            
            _buildCustomField(_tailleController, "Taille (cm)", Icons.height),
            const SizedBox(height: 20),
            _buildCustomField(_poidsController, "Poids (kg)", Icons.monitor_weight_outlined, isDecimal: true),
            const SizedBox(height: 20),
            _buildCustomField(_pathoController, "Pathologie / Diagnostic", Icons.medical_information_outlined, isText: true),
            
            const SizedBox(height: 40),
            _isSaving 
              ? const Center(child: CircularProgressIndicator(color: primaryColor)) 
              : ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: const Text(
                    "SYNCHRONISER AVEC L'IA", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomField(TextEditingController controller, String label, IconData icon, {bool isDecimal = false, bool isText = false}) {
    return TextField(
      controller: controller,
      keyboardType: isText ? TextInputType.text : TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0089BA)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF0089BA))),
      ),
    );
  }
}