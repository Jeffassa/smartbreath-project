import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedSexe = "M";
  String _selectedPathologie = "Non spécifié";
  bool _isSmoker = false; 

  final List<String> _pathologies = [
    "Non spécifié", "Asthme", "BPCO", "Pneumonie", "Infection"
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post("/register", {
        "nom": _nomController.text.trim(),
        "prenom": _prenomController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "date_naissance": _dobController.text,
        "sexe": _selectedSexe,
        "taille_cm": int.parse(_heightController.text),
        "poids_kg": double.parse(_weightController.text),
        "pathologie": _selectedPathologie,
        "est_fumeur": _isSmoker, 
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compte créé ! L'IA est calibrée."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        _showError("Email déjà utilisé ou données invalides.");
      }
    } catch (e) {
      _showError("Erreur de connexion au serveur.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un profil SmartBreath"),
        backgroundColor: const Color(0xFF0089BA),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Identité",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              _buildField(_prenomController, "Prénom", Icons.person_outline),
              _buildField(_nomController, "Nom", Icons.person),
              
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      _dobController,
                      "Date de Naissance",
                      Icons.calendar_month,
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _dobController.text = 
                            picked.toString().split(' ')[0]);
                        }
                      }
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSexe,
                      decoration: const InputDecoration(
                        labelText: "Sexe",
                        border: OutlineInputBorder()
                      ),
                      items: const [
                        DropdownMenuItem(value: "M", child: Text("Homme")),
                        DropdownMenuItem(value: "F", child: Text("Femme")),
                      ],
                      onChanged: (val) => setState(() => _selectedSexe = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text(
                "Données Physiques (Calibrage IA)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildField(
                    _heightController, "Taille (cm)", Icons.height,
                    type: TextInputType.number
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(
                    _weightController, "Poids (kg)", Icons.monitor_weight_outlined,
                    type: TextInputType.number
                  )),
                ],
              ),

              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedPathologie,
                decoration: const InputDecoration(
                  labelText: "Pathologie principale",
                  border: OutlineInputBorder()
                ),
                items: _pathologies.map((p) => 
                  DropdownMenuItem(value: p, child: Text(p))
                ).toList(),
                onChanged: (val) => setState(() => _selectedPathologie = val!),
              ),

              const SizedBox(height: 15),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  title: const Text("Êtes-vous fumeur ?"),
                  subtitle: const Text(
                    "L'IA ajuste ses seuils d'alerte selon ce paramètre",
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isSmoker,
                  secondary: Icon(
                    Icons.smoking_rooms,
                    color: _isSmoker ? Colors.orange : Colors.grey
                  ),
                  onChanged: (val) => setState(() => _isSmoker = val),
                ),
              ),

              const Divider(height: 40),
              _buildField(
                _emailController, "Email", Icons.email_outlined
              ),
              _buildField(
                _passwordController, "Mot de passe", Icons.lock_outline,
                isPassword: true
              ),

              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0089BA),
                      ),
                      child: const Text(
                        "VALIDER MON PROFIL",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        readOnly: readOnly,
        onTap: onTap,
        validator: (v) => v!.isEmpty ? "Requis" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
