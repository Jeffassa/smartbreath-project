import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/emergency_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  double _spo2 = 0.0, _riskScore = 0.0;
  int _bpm = 0;
  String _status = "INITIALISATION", _recommendation = "Connexion...";
  Color _accentColor = Colors.blueGrey;
  bool _showEmergency = false;
  String _lastNotifiedStatus = "";

  final List<FlSpot> _spo2Spots = [];
  final List<FlSpot> _bpmSpots = [];
  double _timerCounter = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (t) => _fetchLatestData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLatestData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.patientId == null) return;

    try {
      final res = await ApiService.get("/status/${auth.patientId}");
      if (res.statusCode == 200 && mounted) {
        final d = jsonDecode(res.body);
        setState(() {
          _spo2 = (d['spo2'] ?? 0.0).toDouble();
          _bpm = (d['bpm'] ?? 0).toInt();
          _status = d['status'] ?? "STABLE";
          _recommendation = d['recommendation'] ?? "Patient en observation";
          _riskScore = (d['risk_score'] ?? 0.0).toDouble();
          _showEmergency = d['emergency'] ?? false;
          _accentColor = _getColor(d['color']);

          _timerCounter++;
          _spo2Spots.add(FlSpot(_timerCounter, _spo2));
          _bpmSpots.add(FlSpot(_timerCounter, _bpm.toDouble()));

          if (_spo2Spots.length > 30) {
            _spo2Spots.removeAt(0);
            _bpmSpots.removeAt(0);
          }
        });

        if (_status != _lastNotifiedStatus) {
          _lastNotifiedStatus = _status;
          if (_status == "CRITIQUE") {
            HapticFeedback.heavyImpact();
            NotificationService.showCriticalAlert("ALERTE CRITIQUE", _recommendation);
          } else if (_status == "PRÉVENTION") {
            HapticFeedback.mediumImpact();
            NotificationService.showPreventiveAlert(_recommendation);
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur Dashboard API: $e");
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      appBar: AppBar(
        title: Text("Santé de ${auth.patientName ?? 'Patient'}"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _fetchLatestData,
          ),
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
              if (_showEmergency) _buildEmergencyButton(),
              const SizedBox(height: 20),
              _buildChartSection(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildMetricTile(
                    "Saturation O₂", "$_spo2%", Icons.air, Colors.lightBlue
                  )),
                  const SizedBox(width: 15),
                  Expanded(child: _buildMetricTile(
                    "Pulsations", "$_bpm BPM", Icons.favorite, Colors.redAccent
                  )),
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
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: _accentColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
        ],
        border: Border.all(color: _accentColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _status == "CRITIQUE" ? Icons.warning_amber_rounded : 
                _status == "PRÉVENTION" ? Icons.info_outline : Icons.check_circle_outline,
                color: _accentColor,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                _status,
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Text(
            _recommendation,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    bool hasEnoughData = _spo2Spots.length >= 2 && _bpmSpots.length >= 2;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("MONITORING LIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.lightBlue),
                    SizedBox(width: 4),
                    Text("O2", style: TextStyle(fontSize: 10)),
                    SizedBox(width: 10),
                    Icon(Icons.circle, size: 8, color: Colors.redAccent),
                    SizedBox(width: 4),
                    Text("BPM", style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: !hasEnoughData 
              ? const Center(child: Text("Collecte des données...", style: TextStyle(color: Colors.grey)))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _spo2Spots,
                        isCurved: true,
                        color: Colors.lightBlue,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Colors.lightBlue.withOpacity(0.1)),
                      ),
                      LineChartBarData(
                        spots: _bpmSpots,
                        isCurved: true,
                        color: Colors.redAccent.withOpacity(0.5),
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ElevatedButton.icon(
        onPressed: () => EmergencyService.triggerFullEmergency(
          Provider.of<AuthProvider>(context, listen: false).patientName ?? "Patient"
        ),
        icon: const Icon(Icons.emergency_share, color: Colors.white),
        label: const Text(
          "DÉCLENCHER ALERTE URGENCE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          minimumSize: const Size(double.infinity, 65),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRiskSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("INDICE DE RISQUE IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                  Text("Analyse prédictive en cours", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              Icon(Icons.auto_awesome, size: 20, color: _accentColor),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: _riskScore,
            minHeight: 12,
            color: _accentColor,
            backgroundColor: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 12),
          Text(
            "${(_riskScore * 100).toInt()}% d'essoufflement critique prédit",
            style: TextStyle(fontWeight: FontWeight.bold, color: _accentColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}