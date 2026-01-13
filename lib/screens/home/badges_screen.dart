import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final response = await ApiService.get("/stats/${auth.patientId}");
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _stats = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Serveur injoignable (Code: ${response.statusCode})");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Impossible de charger les succès. Vérifiez votre connexion.";
        });
      }
    }
  }

  List<Map<String, dynamic>> _getBadgesList() {
    if (_stats == null) return [];
    
    final badges = _stats!['badges'] as Map<String, dynamic>? ?? {};
    
    return [
      {
        "id": "pionnier",
        "title": "Pionnier SmartBreath",
        "desc": "Première mesure effectuée",
        "unlocked": badges['pionnier'] ?? false,
        "icon": Icons.rocket_launch,
        "color": Colors.deepPurple,
        "requirement": "Statut : ${_stats!['jours_consecutifs'] > 0 ? 'Complété' : 'À faire'}",
      },
      {
        "id": "poumon_bronze",
        "title": "Poumon de Bronze",
        "desc": "Baisse de 10% du risque IA",
        "unlocked": (_stats!['amelioration_pourcent'] ?? 0) >= 10,
        "icon": Icons.workspace_premium,
        "color": const Color(0xFFCD7F32),
        "requirement": "Progression : ${_stats!['amelioration_pourcent']}% / 10%",
      },
      {
        "id": "expert",
        "title": "Expert Santé",
        "desc": "50 mesures enregistrées",
        "unlocked": badges['expert'] ?? false,
        "icon": Icons.psychology,
        "color": Colors.blue,
        "requirement": "${_stats!['jours_consecutifs']} / 50 mesures",
      },
      {
        "id": "poumon_acier",
        "title": "Poumon d'Acier",
        "desc": "Atteindre 98% de SpO2",
        "unlocked": badges['poumon_acier'] ?? false,
        "icon": Icons.bolt,
        "color": Colors.blueGrey,
        "requirement": "Objectif : 98% SpO2",
      },
      {
        "id": "zen",
        "title": "Zone de Sérénité",
        "desc": "Risque IA inférieur à 20%",
        "unlocked": badges['zen'] ?? false,
        "icon": Icons.spa,
        "color": Colors.teal,
        "requirement": "Risque actuel : ${_stats!['risque_moyen']}%",
      },
      {
        "id": "champion",
        "title": "Champion",
        "desc": "Zéro alerte critique détectée",
        "unlocked": (_stats!['crises'] ?? 0) == 0 && (_stats!['jours_consecutifs'] ?? 0) > 0,
        "icon": Icons.emoji_events,
        "color": const Color(0xFFFFD700),
        "requirement": "${_stats!['crises']} alerte(s) ce mois",
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildScaffoldWrapper(
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF0089BA), strokeWidth: 5),
              SizedBox(height: 20),
              Text("Synchronisation avec l'IA...", style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildScaffoldWrapper(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _loadBadges,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Réessayer"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final badgesList = _getBadgesList();
    final unlockedCount = badgesList.where((b) => b['unlocked']).length;

    return _buildScaffoldWrapper(
      body: RefreshIndicator(
        onRefresh: _loadBadges,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(unlockedCount, badgesList.length)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildBadgeCard(badgesList[index]),
                  childCount: badgesList.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaffoldWrapper({required Widget body}) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text("Mes Succès IA", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0089BA),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: body,
    );
  }

  Widget _buildHeader(int unlocked, int total) {
    final double progress = total > 0 ? unlocked / total : 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0089BA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "$unlocked / $total Badges Obtenus",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final bool isUnlocked = badge['unlocked'];
    final Color color = badge['color'];

    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isUnlocked ? color.withOpacity(0.15) : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isUnlocked ? color.withOpacity(0.3) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: ColorTween(
                begin: Colors.grey[300],
                end: isUnlocked ? color : Colors.grey[300],
              ),
              duration: const Duration(seconds: 1),
              builder: (context, Color? animatedColor, child) {
                return Icon(badge['icon'], size: 48, color: animatedColor);
              },
            ),
            const SizedBox(height: 12),
            Text(
              badge['title'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isUnlocked ? Colors.black87 : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            if (!isUnlocked)
              const Icon(Icons.lock_outline, size: 16, color: Colors.grey)
            else
              const Icon(Icons.check_circle, size: 18, color: Colors.green),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badge['icon'], size: 80, color: badge['unlocked'] ? badge['color'] : Colors.grey),
            const SizedBox(height: 20),
            Text(badge['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(badge['desc'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Icon(badge['unlocked'] ? Icons.verified : Icons.info_outline, color: badge['color']),
                  const SizedBox(width: 12),
                  Text(badge['requirement'], style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0089BA),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Continuer mes efforts", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}