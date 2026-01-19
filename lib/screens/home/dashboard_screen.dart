import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; 
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/emergency_service.dart';
import 'bluetooth_search_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  double _spo2 = 0.0, _riskScore = 0.0;
  int _bpm = 0;
  int? _currentDataId; 
  String _status = "INITIALISATION", _recommendation = "En attente de données...";
  Color _accentColor = Colors.blueGrey;
  bool _showEmergency = false;
  bool _feedbackSentForThisAlert = false;
  String _lastNotifiedStatus = "";

  BluetoothDevice? _connectedDevice;
  StreamSubscription? _notifySubscription;
  StreamSubscription? _connectionStateSubscription;

  final List<FlSpot> _spo2Spots = [];
  final List<FlSpot> _bpmSpots = [];
  double _timerCounter = 0;

  @override
  void initState() {
    super.initState();
    // Démarrage du timer pour rafraîchir l'interface toutes les 3 secondes
    _timer = Timer.periodic(const Duration(seconds: 3), (t) => _fetchLatestData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notifySubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  void _handleBluetoothConnection(BluetoothDevice device) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await device.connect();
      setState(() => _connectedDevice = device);

      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && mounted) {
          setState(() => _connectedDevice = null);
        }
      });

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            _notifySubscription = characteristic.lastValueStream.listen((value) {
              _processAndSendData(value, auth.patientId);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur Bluetooth : $e");
    }
  }

  void _processAndSendData(List<int> rawData, String? patientId) async {
    if (patientId == null || rawData.isEmpty) return;
    try {
      String decodedString = utf8.decode(rawData);
      List<String> values = decodedString.split(',');
      if (values.length < 2) return;

      final Map<String, dynamic> jsonData = {
        "patient_id": patientId,
        "spo2": double.tryParse(values[0]) ?? 0.0,
        "bpm": int.tryParse(values[1]) ?? 0,
        "flow_rate": 15.0, 
        "muscle_strength": 5.0,
        "temperature": 36.6
      };
      await ApiService.post("/analyze", jsonData);
    } catch (e) {
      debugPrint("Erreur Envoi IoT : $e");
    }
  }

  // --- RÉCUPÉRATION DES DONNÉES (FILTRÉES) ---
  Future<void> _fetchLatestData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.patientId == null) return;

    try {
      final res = await ApiService.get("/status/${auth.patientId}");
      if (res.statusCode == 200 && mounted) {
        final d = jsonDecode(res.body);
        
        // SÉCURITÉ : Si les données sont à 0, on ignore pour éviter la "crise fantôme"
        if ((d['spo2'] ?? 0) == 0 && (d['bpm'] ?? 0) == 0) {
          setState(() {
            _status = "EN ATTENTE";
            _recommendation = "Lancez le simulateur pour voir les données.";
            _accentColor = Colors.blueGrey;
          });
          return;
        }

        setState(() {
          _currentDataId = d['data_id'];
          _spo2 = (d['spo2'] ?? 0.0).toDouble();
          _bpm = (d['bpm'] ?? 0).toInt();
          _status = d['status'] ?? "STABLE";
          _recommendation = d['recommendation'] ?? "Analyse en cours...";
          _riskScore = (d['risk_score'] ?? 0.0).toDouble();
          _showEmergency = d['emergency'] ?? false;
          _accentColor = _getColor(d['color']);

          if (_status == "STABLE") _feedbackSentForThisAlert = false;

          _timerCounter++;
          _spo2Spots.add(FlSpot(_timerCounter, _spo2));
          _bpmSpots.add(FlSpot(_timerCounter, _bpm.toDouble()));

          if (_spo2Spots.length > 20) {
            _spo2Spots.removeAt(0);
            _bpmSpots.removeAt(0);
          }
        });

        // Notifications
        if (_status != _lastNotifiedStatus) {
          _lastNotifiedStatus = _status;
          if (_status == "CRITIQUE") {
            HapticFeedback.vibrate();
            NotificationService.showCriticalAlert("URGENCE RESPIRATOIRE", _recommendation);
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur Sync API : $e");
    }
  }

  Color _getColor(String? c) {
    switch (c) {
      case 'red': return Colors.redAccent;
      case 'orange': return Colors.orange;
      case 'yellow': return Colors.amber;
      case 'green': return const Color(0xFF2ECC71);
      default: return const Color(0xFF0089BA);
    }
  }

  // --- INTERFACE (WIDGETS) ---
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      appBar: AppBar(
        title: Text("Santé de ${auth.patientName ?? 'Patient'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bluetooth, color: _connectedDevice != null ? Colors.green : Colors.grey),
            onPressed: () async {
              final device = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BluetoothSearchScreen()));
              if (device != null && device is BluetoothDevice) _handleBluetoothConnection(device);
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLatestData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLatestData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStatusCard(),
              if (_status != "STABLE" && _status != "EN ATTENTE" && !_feedbackSentForThisAlert) _buildFeedbackPrompt(),
              if (_showEmergency) _buildEmergencyButton(),
              const SizedBox(height: 20),
              _buildChartSection(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildMetricTile("Saturation O₂", "$_spo2%", Icons.air, Colors.lightBlue)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildMetricTile("Pulsations", "$_bpm BPM", Icons.favorite, Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 20),
              _buildRiskSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.1), blurRadius: 20)],
        border: Border.all(color: _accentColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(_status, style: TextStyle(color: _accentColor, fontSize: 32, fontWeight: FontWeight.black)),
          const SizedBox(height: 10),
          Text(_recommendation, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: _spo2Spots, isCurved: true, color: Colors.blue, barWidth: 4, dotData: const FlDotData(show: false)),
          LineChartBarData(spots: _bpmSpots, isCurved: true, color: Colors.red.withOpacity(0.3), barWidth: 2, dotData: const FlDotData(show: false)),
        ],
      )),
    );
  }

  Widget _buildRiskSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          const Text("ANALYSE PRÉDICTIVE XGBOOST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 15),
          LinearProgressIndicator(value: _riskScore, minHeight: 10, color: _accentColor, backgroundColor: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 10),
          Text("${(_riskScore * 100).toStringAsFixed(1)}% de probabilité de crise", style: TextStyle(fontWeight: FontWeight.bold, color: _accentColor)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFeedbackPrompt() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text("L'IA détecte une anomalie. Est-ce correct ?", style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              TextButton(onPressed: () => _submitFeedback(0, "Fausse alerte"), child: const Text("NON")),
              TextButton(onPressed: () => _submitFeedback(1, "Gêne confirmée"), child: const Text("OUI, JE SENS UNE GÊNE", style: TextStyle(color: Colors.red))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: ElevatedButton(
        onPressed: () => EmergencyService.triggerFullEmergency(Provider.of<AuthProvider>(context, listen: false).patientName ?? "Patient"),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 60)),
        child: const Text("APPEL D'URGENCE SMS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _submitFeedback(int outcome, String note) async {
    if (_currentDataId == null) return;
    bool success = await ApiService.sendFeedback(_currentDataId!, outcome, note);
    if (success && mounted) {
      setState(() => _feedbackSentForThisAlert = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Merci, l'IA apprend de votre retour.")));
    }
  }
}