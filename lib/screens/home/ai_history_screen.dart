import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';

class AIHistoryScreen extends StatefulWidget {
  const AIHistoryScreen({super.key});

  @override
  State<AIHistoryScreen> createState() => _AIHistoryScreenState();
}

class _AIHistoryScreenState extends State<AIHistoryScreen> {
  List<dynamic> _fullHistory = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String _activeTab = "Semaine";

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadAllData());
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.patientId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Charger l'historique et les stats en parallèle
      final historyResponse = await ApiService.get("/ai-history/${auth.patientId}");
      final statsResponse = await ApiService.get("/stats/${auth.patientId}");

      if (historyResponse.statusCode == 200 && statsResponse.statusCode == 200) {
        setState(() {
          _fullHistory = jsonDecode(historyResponse.body);
          _stats = jsonDecode(statsResponse.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Erreur chargement données: $e");
      setState(() => _isLoading = false);
    }
  }

  List<FlSpot> _getFilteredSpots() {
    if (_fullHistory.isEmpty) return [];
    
    List<dynamic> filtered;
    
    if (_activeTab == "Semaine") {
      filtered = _fullHistory.length > 50 
          ? _fullHistory.sublist(_fullHistory.length - 50)
          : _fullHistory;
    } else if (_activeTab == "Mois") {
      filtered = _fullHistory;
    } else {
      filtered = _fullHistory;
    }
    
    return filtered.asMap().entries.map((e) {
      double spo2 = 0;
      if (e.value['spo2'] != null) {
        spo2 = (e.value['spo2'] is int)
            ? (e.value['spo2'] as int).toDouble()
            : (e.value['spo2'] as double);
      }
      return FlSpot(e.key.toDouble(), spo2);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildRespiratoryTrendCard(),
                        const SizedBox(height: 20),
                        _buildQualityCard(),
                        const SizedBox(height: 20),
                        _buildDailyActivityCard(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF0089BA),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0089BA), Color(0xFF26C6DA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Statistiques",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton("Semaine", "Semaine"),
                    _buildTabButton("Mois", "Mois"),
                    _buildTabButton("Année", "Année"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    bool isSelected = _activeTab == value;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0089BA) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRespiratoryTrendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tendance respiratoire (SpO2)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _fullHistory.isEmpty
                ? const Center(child: Text("Aucune donnée disponible"))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 80,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getFilteredSpots(),
                          isCurved: true,
                          color: const Color(0xFF0089BA),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF0089BA).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("L", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("M", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("M", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("J", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("V", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("S", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text("D", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard() {
    if (_stats == null) return const SizedBox();
    
    double risqueMoyen = (_stats!['risque_moyen'] as num? ?? 0).toDouble();
    double qualite = (1.0 - risqueMoyen) * 100;
    String note = qualite > 80 ? "Excellente" : qualite > 60 ? "Bonne" : qualite > 40 ? "Moyenne" : "Faible";
    Color noteColor = qualite > 80 ? Colors.green : qualite > 60 ? Colors.lightGreen : qualite > 40 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Score de Santé IA",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Icon(Icons.auto_awesome, color: noteColor, size: 24),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "État général / $note",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: qualite / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade100,
            color: noteColor,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: noteColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.thermostat, size: 16, color: noteColor),
                    const SizedBox(width: 5),
                    Text(
                      "${qualite.toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: noteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  qualite > 70 
                      ? "Paramètres vitaux optimaux"
                      : "Stabilité thermique à surveiller",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivityCard() {
    if (_stats == null) return const SizedBox();
    
    int joursConsecutifs = (_stats!['jours_consecutifs'] as int? ?? 0);
    int objectifJours = 30;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Activité de suivi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$joursConsecutifs",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0089BA),
                ),
              ),
              const SizedBox(width: 5),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  "jours",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Objectif: $objectifJours jours",
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: (joursConsecutifs / objectifJours).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            color: const Color(0xFF0089BA),
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            Icons.warning_amber_rounded,
            "Alertes IA",
            "${_stats!['alertes_preventives'] ?? 0} préventions",
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            Icons.trending_up,
            "Index de stabilité",
            "${_stats!['amelioration_pourcent'] ?? 0}%",
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            Icons.emergency,
            "Épisodes critiques",
            "${_stats!['crises'] ?? 0}",
            (_stats!['crises'] as int? ?? 0) == 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
