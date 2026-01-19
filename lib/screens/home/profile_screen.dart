import 'dart:async'; 
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; 
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

  bool _isConnected = false;
  StreamSubscription? _bluetoothSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchUserProfile());
    _monitorBluetoothConnection(); 
  }

  @override
  void dispose() {
    _bluetoothSubscription?.cancel();
    super.dispose();
  }

  void _monitorBluetoothConnection() {
    _bluetoothSubscription = FlutterBluePlus.adapterState.listen((state) async {
      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      if (mounted) {
        setState(() {
          _isConnected = connectedDevices.isNotEmpty;
        });
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (auth.patientId == null) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (auth.patientId == null) {
      setState(() {
        _errorMessage = "Patient ID introuvable. Reconnectez-vous.";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiService.get("/profile/${auth.patientId}");
      
      if (response.statusCode == 200 && mounted) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        
        setState(() {
          _userData = decodedResponse.containsKey('data') 
              ? decodedResponse['data'] 
              : decodedResponse;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = "Profil non trouvé (Code: ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erreur de connexion au serveur";
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await File(image.path).readAsBytes();
      final String base64Image = base64Encode(bytes);

      final response = await ApiService.put("/profile/${auth.patientId}", {
        "photo_base64": base64Image,
      });

      if (response.statusCode == 200) {
        _fetchUserProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Photo synchronisée !"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      debugPrint("Erreur photo: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGETS ---
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0089BA);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(onPressed: _fetchUserProfile, child: const Text("Réessayer"))
            ],
          ),
        ),
      );
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
                    _buildInfoRow("Taille", "${_userData?['taille_cm'] ?? '--'} cm", Icons.straighten),
                    _buildInfoRow("Poids", "${_userData?['poids_kg'] ?? '--'} kg", Icons.monitor_weight_outlined),
                    _buildInfoRow("Fumeur", (_userData?['est_fumeur'] == true) ? "Oui" : "Non", Icons.smoke_free),
                    const Divider(height: 30),
                    _buildInfoRow("Pathologie", _userData?['pathologie'] ?? "Non spécifié", Icons.assignment_outlined),
                    const SizedBox(height: 20),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _showEditDialog,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Mettre à jour mon profil"),
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
    String name = _userData?['prenom'] ?? 'Patient';
    String lastName = _userData?['nom'] ?? '';
    String? photoBase64 = _userData?['photo_url']; // Dans ton backend, c'est souvent stocké ici

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withBlue(200)]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 53,
                backgroundColor: Colors.white24,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: (photoBase64 != null && photoBase64.length > 100)
                      ? MemoryImage(base64Decode(photoBase64))
                      : null,
                  child: (photoBase64 == null || photoBase64.length < 100)
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
          Text("$name $lastName", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_userData?['email'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final tCtrl = TextEditingController(text: _userData?['taille_cm']?.toString());
    final pCtrl = TextEditingController(text: _userData?['poids_kg']?.toString());
    final pathCtrl = TextEditingController(text: _userData?['pathologie']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Modifier mes constantes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: tCtrl, decoration: const InputDecoration(labelText: "Taille (cm)"), keyboardType: TextInputType.number),
            TextField(controller: pCtrl, decoration: const InputDecoration(labelText: "Poids (kg)"), keyboardType: TextInputType.number),
            TextField(controller: pathCtrl, decoration: const InputDecoration(labelText: "Pathologie")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await ApiService.put("/profile/${auth.patientId}", {
                  "taille_cm": int.tryParse(tCtrl.text),
                  "poids_kg": double.tryParse(pCtrl.text),
                  "pathologie": pathCtrl.text,
                });
                Navigator.pop(context);
                _fetchUserProfile();
              },
              child: const Text("Enregistrer"),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
      child: Row(children: [
        Icon(_isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: _isConnected ? Colors.green : Colors.grey),
        const SizedBox(width: 15),
        Text(_isConnected ? "Capteur SmartBreath Connecté" : "Capteur déconnecté"),
      ]),
    );
  }
}