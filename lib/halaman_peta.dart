import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'halaman_cctv.dart';
import 'layanan_cctv.dart';

class MapPage extends StatefulWidget {
  final List<CctvLocation> cctvLocations;
  final LatLng? initialCenter;

  const MapPage({super.key, required this.cctvLocations, this.initialCenter});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  CctvLocation? _selectedCctv;
  static const LatLng _defaultPosition = LatLng(-7.9786, 112.6318);

  List<Marker> _createMarkers() {
    return widget.cctvLocations
        .map((cctv) {
          try {
            final lat = double.parse(cctv.latitude);
            final lng = double.parse(cctv.longitude);
            final isSelected = _selectedCctv?.streamId == cctv.streamId;

            return Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(lat, lng),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCctv = cctv;
                    _mapController.move(LatLng(lat, lng), 15.0);
                  });
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isSelected ? 1.5 : 1.0,
                  child: Icon(
                    Icons.location_pin,
                    color: isSelected ? Colors.blueAccent : Colors.deepPurple,
                    size: 40.0,
                  ),
                ),
              ),
            );
          } catch (e) {
            print('Error parsing coordinates for ${cctv.name}: $e');
            return null;
          }
        })
        .whereType<Marker>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 96, 80, 167),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  "Peta Lokasi CCTV",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter ?? _defaultPosition,
              initialZoom: 13.0,
              onTap: (_, __) {
                setState(() {
                  _selectedCctv = null;
                });
              },
            ),
            children: [
              TileLayer(urlTemplate: ''),
              MarkerLayer(markers: _createMarkers()),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _selectedCctv != null ? 10 : -250,
            left: 10,
            right: 10,
            child: _buildInfoCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    if (_selectedCctv == null) {
      return const SizedBox.shrink();
    }
    final cctv = _selectedCctv!;
    final trafficStatus = "Lancar";
    final statusColor = Colors.green;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cctv.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedCctv = null),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Status: $trafficStatus",
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVehicleCount(
                  "Mobil",
                  cctv.vehicleData.mobil,
                  Icons.directions_car,
                  Colors.blueAccent,
                ),
                _buildVehicleCount(
                  "Motor",
                  cctv.vehicleData.motor,
                  Icons.two_wheeler,
                  Colors.orange,
                ),
                _buildVehicleCount(
                  "Truk",
                  cctv.vehicleData.truk,
                  Icons.local_shipping,
                  Colors.brown,
                ),
                _buildVehicleCount(
                  "Darurat",
                  cctv.vehicleData.darurat,
                  Icons.emergency,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.videocam_outlined),
                label: const Text("Lihat Live CCTV"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 96, 80, 167),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final index = widget.cctvLocations.indexWhere(
                    (loc) => loc.streamId == cctv.streamId,
                  );
                  if (index != -1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CctvPage(
                              cctvLocations: widget.cctvLocations,
                              initialIndex: index,
                            ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCount(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
