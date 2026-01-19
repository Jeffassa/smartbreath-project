import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothSearchScreen extends StatefulWidget {
  const BluetoothSearchScreen({super.key});

  @override
  State<BluetoothSearchScreen> createState() => _BluetoothSearchScreenState();
}

class _BluetoothSearchScreenState extends State<BluetoothSearchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  List<ScanResult> _scanResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _stopScan();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]!.isDenied || 
        statuses[Permission.location]!.isDenied) {
      _showErrorSnackBar("Permissions requises pour scanner les appareils.");
      return;
    }

    setState(() {
      _isSearching = true;
      _scanResults = [];
    });

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      _showErrorSnackBar("Veuillez activer le Bluetooth sur votre téléphone");
      setState(() => _isSearching = false);
      return;
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          results.sort((a, b) => b.rssi.compareTo(a.rssi));
          _scanResults = results;
        });
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true, 
      );
    } catch (e) {
      debugPrint("Erreur lors du scan: $e");
    }

    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning && mounted) {
        setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _stopScan() async {
    _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FA),
      appBar: AppBar(
        title: const Text("Détecter ma montre"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isSearching)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * 2 * math.pi,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.blue.withOpacity(0.0),
                                Colors.blue.withOpacity(0.5)
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _isSearching ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (_isSearching)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                    ],
                  ),
                  child: Icon(
                    _isSearching ? Icons.watch : Icons.watch_off,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            _isSearching ? "Recherche en cours..." : "Recherche terminée",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _scanResults.isEmpty && !_isSearching
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      final device = result.device;
                      final name = device.platformName.isNotEmpty 
                          ? device.platformName 
                          : "Appareil inconnu";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth,
                            color: _getSignalColor(result.rssi),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(device.remoteId.toString()),
                          trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                          onTap: () async {
                            await _stopScan();
                            if (context.mounted) {
                              Navigator.pop(context, device);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.refresh),
                label: const Text("RELANCER LA RECHERCHE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "Aucun appareil BLE détecté",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 5),
          const Text(
            "Vérifiez que la montre est allumée et à proximité",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }
}