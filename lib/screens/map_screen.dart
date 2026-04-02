import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/checkin_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController(); 
  
  Position? _currentPosition;
  String _currentAddress = "Press 'Scan Radar' to find repair stations";
  bool _isLoading = false;
  int _selectedIndex = 0; 
  int _totalPoints = 0; 

  LatLng _mapCenter = const LatLng(1.5323, 103.7088);
  List<Map<String, dynamic>> _stations = [];

  // core function: Radar scanning + dynamic station generation + distance calculation
  Future<void> _scanArea() async {
    setState(() {
      _isLoading = true;
      _currentAddress = "Scanning eco-radar... 📡";
    });

    try {
      Position pos = await _locationService.getCurrentLocation();
      String addr = await _locationService.getAddressFromCoordinates(pos);

      // 🌟 Core Feature: Dynamic Station Generation
      // The first station is very close to you (about 40 meters), ensuring you can test check-ins!
      // The other two stations are farther away, demonstrating the "TOO FAR" anti-cheat mechanism!
      List<Map<String, dynamic>> newStations = [
        {"name": "EcoFix Express (Nearest)", "lat": pos.latitude + 0.0004, "lng": pos.longitude + 0.0004, "points": 50},
        {"name": "Green Tech Repair", "lat": pos.latitude - 0.0025, "lng": pos.longitude + 0.0015, "points": 30},
        {"name": "Ah Beng Fix-It", "lat": pos.latitude + 0.0030, "lng": pos.longitude - 0.0020, "points": 40},
      ];

      // Calculate the real straight-line distance between you and each station
      for (var station in newStations) {
        station['distance'] = _locationService.calculateDistance(
            pos.latitude, pos.longitude, station['lat'], station['lng']);
      }

      setState(() {
        _currentPosition = pos;
        _currentAddress = addr;
        _mapCenter = LatLng(pos.latitude, pos.longitude);
        _stations = newStations;
        _selectedIndex = 0; 
        _mapController.move(_mapCenter, 16.0); 
      });
    } catch (e) {
      setState(() { _currentAddress = "Error: $e"; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // core function: Eco-Check-in
  Future<void> _checkIn(Map<String, dynamic> station) async {
    await CheckInService.addCheckIn(station['name']); // Store in local ledger

    setState(() {
      _totalPoints += station['points'] as int; // Increase points
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Checked into ${station['name']}! +${station['points']} Points!'), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoFix Stations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // ================= bottom layer: real map =================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecofix.app',
              ),
              
              // ================= bottom layer: radar scan circle (800 meters) =================
              if (_currentPosition != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _mapCenter,
                      color: Colors.blue.withOpacity(0.15),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                      useRadiusInMeter: true,
                      radius: 800, 
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  // ================= bottom layer: your location (blue dot) =================
                  if (_currentPosition != null)
                    Marker(
                      point: _mapCenter,
                      width: 50, height: 50,
                      child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 45),
                    ),
                    
                  // ================= bottom layer: all repair stations (selected ones are larger and red, unselected ones are green) =================
                  ..._stations.map((station) {
                    bool isSelected = _stations.indexOf(station) == _selectedIndex;
                    return Marker(
                      point: LatLng(station["lat"], station["lng"]),
                      width: isSelected ? 60 : 40,
                      height: isSelected ? 60 : 40,
                      child: Icon(
                        Icons.build_circle, 
                        color: isSelected ? Colors.redAccent : Colors.green, 
                        size: isSelected ? 50 : 35
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ================= top layer: address bar & points bar =================
          Positioned(
            top: 15, left: 15, right: 15,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF1A212E).withOpacity(0.9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text("📍 $_currentAddress", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Chip(
                  backgroundColor: Colors.orangeAccent,
                  label: Text("🏆 $_totalPoints Pt", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ],
            ),
          ),

          // ================= top layer: horizontal scrolling cards (game-changing feature) =================
          if (_stations.isNotEmpty)
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: _stations.length,
                  itemBuilder: (context, index) {
                    final station = _stations[index];
                    bool isSelected = index == _selectedIndex;
                    bool canJoin = station['distance'] <= 100; // Anti-cheat: can only check-in within 100 meters

                    return GestureDetector(
                      onTap: () {
                        setState(() { _selectedIndex = index; });
                        _mapController.move(LatLng(station['lat'], station['lng']), 17.0); // Smooth camera movement
                      },
                      child: Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 15),
                        child: Card(
                          color: const Color(0xFF1A212E),
                          elevation: isSelected ? 15 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: isSelected ? Colors.green : Colors.transparent, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(station['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text("🎁 Reward: ${station['points']} Points", style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                                Text("📏 Distance: ${station['distance'].toStringAsFixed(0)} meters", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                const Spacer(),
                                
                                // ================= top layer: status indicator & check-in button =================
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      canJoin ? "✅ NEARBY" : "❌ TOO FAR", 
                                      style: TextStyle(color: canJoin ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)
                                    ),
                                    ElevatedButton(
                                      onPressed: (canJoin && isSelected) ? () => _checkIn(station) : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        disabledBackgroundColor: Colors.grey[800],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text("Check In", style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      // ================= bottom layer: floating action button for radar scan =================
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _stations.isNotEmpty ? 190 : 20),
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _scanArea,
          backgroundColor: Colors.blueAccent,
          icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.radar, color: Colors.white),
          label: const Text("Scan Radar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}