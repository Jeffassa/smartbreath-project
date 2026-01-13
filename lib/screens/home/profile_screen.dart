import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  File? _localImage; 

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _pickAndUploadImage() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() {
        _localImage = File(image.path);
        _isLoading = true;
      });

      final bytes = await _localImage!.readAsBytes();
      final String base64Image = base64Encode(bytes);

      final response = await ApiService.put("/profile/${auth.patientId}", {
        "photo_base64": base64Image,
      });

      if (response.statusCode == 200) {
        await _fetchUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Photo de profil synchronisée !"), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (auth.patientId == null) {
      setState(() {
        _errorMessage = "Patient ID introuvable";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.get("/profile/${auth.patientId}");
      
      if (response.statusCode == 200 && mounted) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        setState(() {
          _userData = decodedResponse['data'];
          _isLoading = false;
          _errorMessage = null;
          _localImage = null; 
        });
      } else {
        throw Exception("Erreur serveur : ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erreur réseau : $e";
        });
      }
    }
  }

  void _showEditDialog() {
    if (_userData == null) return;

    final tailleCtrl = TextEditingController(text: (_userData!['taille_cm'] ?? _userData!['height'] ?? "").toString());
    final poidsCtrl = TextEditingController(text: (_userData!['poids_kg'] ?? _userData!['weight'] ?? "").toString());
    final pathoCtrl = TextEditingController(text: _userData!['pathologie']?.toString() ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 30, left: 25, right: 25
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Icon(Icons.psychology, size: 50, color: Color(0xFF0089BA)),
            const SizedBox(height: 10),
            const Text("Recalibrage de l'IA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            _buildTextField(tailleCtrl, "Taille (cm)", Icons.height, TextInputType.number),
            const SizedBox(height: 15),
            _buildTextField(poidsCtrl, "Poids (kg)", Icons.monitor_weight_outlined, const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 15),
            _buildTextField(pathoCtrl, "Pathologie", Icons.medical_services_outlined, TextInputType.text),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                try {
                  await ApiService.put("/profile/${auth.patientId}", {
                    "taille_cm": int.tryParse(tailleCtrl.text) ?? 0,
                    "poids_kg": double.tryParse(poidsCtrl.text) ?? 0.0,
                    "pathologie": pathoCtrl.text,
                  });
                  await _fetchUserProfile();
                } catch (e) {
                  debugPrint("Erreur update: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0089BA),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("SYNCHRONISER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0089BA)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0089BA);
    
    if (_isLoading && _userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      body: RefreshIndicator(
        onRefresh: _fetchUserProfile,
        child: Column(
          children: [
            _buildHeader(primaryColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                children: [
                  _buildInfoCard("Données Médicales", [
                    _buildInfoRow("Âge", "${_userData?['age'] ?? '--'} ans", Icons.cake_outlined),
                    _buildInfoRow("Taille", "${_userData?['taille_cm'] ?? _userData?['height'] ?? '--'} cm", Icons.straighten),
                    _buildInfoRow("Poids", "${_userData?['poids_kg'] ?? _userData?['weight'] ?? '--'} kg", Icons.monitor_weight_outlined),
                    _buildInfoRow("Fumeur", (_userData?['est_fumeur'] == true || _userData?['is_smoker'] == true) ? "Oui" : "Non", Icons.smoke_free),
                    const Divider(height: 30),
                    _buildInfoRow("Pathologie", _userData?['pathologie'] ?? "Non spécifié", Icons.assignment_outlined),
                    const SizedBox(height: 20),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _showEditDialog,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Modifier les infos"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildDeviceCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    String displayName = "${_userData?['prenom'] ?? ''} ${_userData?['nom'] ?? 'Patient'}";
    String? photoUrl = _userData?['photo_url'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withBlue(200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 53,
                backgroundColor: Colors.white.withOpacity(0.5),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  // FIX : Gestion hybride local/réseau pour éviter l'erreur unsupported
                  backgroundImage: _localImage != null 
                    ? FileImage(_localImage!) as ImageProvider
                    : (photoUrl != null && photoUrl.isNotEmpty) 
                        ? NetworkImage(photoUrl) 
                        : null,
                  child: (_localImage == null && (photoUrl == null || photoUrl.isEmpty))
                      ? const Icon(Icons.person, size: 50, color: Color(0xFF0089BA))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF0089BA)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_userData?['email'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0089BA))),
        const SizedBox(height: 15),
        ...children,
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 15),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: const Row(children: [
        Icon(Icons.bluetooth_connected, color: Colors.green),
        SizedBox(width: 15),
        Text("Capteur SmartBreath Connecté", style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}