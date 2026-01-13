import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String _activeTab = "semaine";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.patientId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final responses = await Future.wait([
        ApiService.get("/stats/${auth.patientId}?periode=$_activeTab"),
        ApiService.get("/dashboard-summary/${auth.patientId}"),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        if (mounted) {
          setState(() {
            _stats = jsonDecode(responses[0].body);
            _summary = jsonDecode(responses[1].body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Erreur serveur");
      }
    } catch (e) {
      debugPrint("Erreur stats: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Données indisponibles pour cette période")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0089BA)))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSummaryCards(),
                          const SizedBox(height: 20),
                          _buildChartSection(), 
                          const SizedBox(height: 20),
                          _buildProgressSection(),
                          const SizedBox(height: 20),
                          _buildAchievementsSection(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0089BA),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Analyse de Santé",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton("Semaine", "semaine"),
              _buildTabButton("Mois", "mois"),
              _buildTabButton("Année", "annee"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    bool isSelected = _activeTab == value;
    return GestureDetector(
      onTap: () {
        if (_activeTab != value) {
          setState(() => _activeTab = value);
          _loadData();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? const Color(0xFF0089BA) : Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_summary == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0089BA), Color(0xFF26C6DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: const Color(0xFF0089BA).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insights, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text("État Actuel (24h)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat("SpO2 Moyen", "${_summary!['spo2_moyen'] ?? '--'}%", Icons.air),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildSummaryStat("Risque IA", "${_summary!['risque_moyen'] ?? '--'}%", Icons.psychology_outlined),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAlertCount("Critiques", _summary!['nb_alertes_critiques'] ?? 0, Colors.redAccent),
                _buildAlertCount("Préventives", _summary!['nb_alertes_preventives'] ?? 0, Colors.orangeAccent),
                _buildAlertCount("Mesures", _summary!['total_mesures'] ?? 0, Colors.greenAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    if (_stats == null || _stats!['graph_data'] == null) return const SizedBox();
    
    // CORRECTION : Utilisation des bonnes clés risk_values et conversion sécurisée
    final labels = List<String>.from(_stats!['graph_data']['labels'] ?? []);
    final riskData = _stats!['graph_data']['risk_values'] as List?;
    
    if (labels.isEmpty || riskData == null) return const Center(child: Text("Aucune donnée graphique"));

    final List<FlSpot> spots = [];
    for (int i = 0; i < riskData.length; i++) {
      spots.add(FlSpot(i.toDouble(), (riskData[i] as num).toDouble()));
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Évolution du Risque (%)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(labels[index], style: const TextStyle(fontSize: 9, color: Colors.grey)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF0089BA),
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF0089BA).withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_stats == null) return const SizedBox();
    final risk = (_stats!['risque_moyen'] ?? 0.0).toDouble();
    final amelioration = (_stats!['amelioration_pourcent'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Niveau de Risque Global", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(amelioration >= 0 ? Icons.trending_down : Icons.trending_up, 
                   color: amelioration >= 0 ? Colors.green : Colors.red),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (risk / 100).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.grey.shade100,
              color: risk < 30 ? Colors.green : (risk < 70 ? Colors.orange : Colors.red),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            amelioration >= 0 
              ? "Bravo ! Votre risque a diminué de ${amelioration.abs()}%."
              : "Attention : Augmentation du risque de ${amelioration.abs()}% constatée.",
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    if (_stats == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Badges & Activité", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _buildAchievementRow("Mesures totales", "${_stats!['jours_consecutifs'] ?? 0}", Icons.analytics, Colors.blue),
          const Divider(height: 30),
          _buildAchievementRow("Stabilité SpO2", "Excellente", Icons.verified_user, Colors.green),
          const Divider(height: 30),
          _buildAchievementRow("Badge", _activeTab == "semaine" ? "Assiduité" : "Sénior", Icons.workspace_premium, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildAlertCount(String label, dynamic count, Color color) {
    return Column(
      children: [
        Text("${count ?? 0}", style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _buildAchievementRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}