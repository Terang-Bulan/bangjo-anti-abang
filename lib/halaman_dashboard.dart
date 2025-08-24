import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'halaman_cctv.dart';
import 'halaman_notifikasi.dart';
import 'halaman_peta.dart';
import 'halaman_profil.dart';
import 'layanan_cctv.dart';
import 'layanan_user.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final CctvDataService _cctvService = CctvDataService();
  final UserService _userService = UserService();
  late Future<List<dynamic>> _dataFuture;
  PageController? _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dataFuture = Future.wait([
      _cctvService.fetchAllCctvData(),
      _userService.getCurrentUserProfile(),
    ]);
  }

  void _setupCarousel(int itemCount) {
    if (_timer != null && _timer!.isActive) return;
    if (itemCount == 0) return;
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _currentPage = (_currentPage + 1) % itemCount;
      if (_pageController!.hasClients) {
        _pageController!.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
          }

          final allCctvLocations = snapshot.data![0] as List<CctvLocation>;
          final userProfile = snapshot.data![1] as UserProfile?;
          final carouselCctvLocations = allCctvLocations.take(8).toList();

          if (carouselCctvLocations.isNotEmpty && _pageController == null) {
            _setupCarousel(carouselCctvLocations.length);
          }

          LatLng? userInitialLocation;
          if (userProfile?.geoCoordinates != null) {
            userInitialLocation = LatLng(
              userProfile!.geoCoordinates!.latitude,
              userProfile.geoCoordinates!.longitude,
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, userProfile),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: _buildSlidingVehicleStats(carouselCctvLocations),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeatureCard(
                              icon: Icons.map_outlined,
                              label: "Akses Peta",
                              color: Colors.blueAccent,
                              onTap: () {
                                if (allCctvLocations.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MapPage(
                                            cctvLocations: allCctvLocations,
                                            initialCenter: userInitialLocation,
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Data CCTV tidak tersedia.",
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildFeatureCard(
                              icon: Icons.videocam_outlined,
                              label: "Akses CCTV",
                              color: Colors.green,
                              onTap: () {
                                if (allCctvLocations.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CctvPage(
                                            cctvLocations: allCctvLocations,
                                            initialIndex: 0,
                                          ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Data CCTV tidak tersedia.",
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfile? profile) {
    final displayName = profile?.displayName ?? 'Pengguna';
    final location = profile?.location ?? 'Lokasi tidak diatur';
    final photoUrl = profile?.photoURL;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 96, 80, 167),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderButton(
                icon: Icons.notifications_none,
                label: "Notifikasi",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
              ),
              _buildHeaderButton(
                icon: Icons.logout,
                label: "Keluar",
                onPressed: _signOut,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                  image:
                      (photoUrl != null && photoUrl.isNotEmpty)
                          ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    (photoUrl == null || photoUrl.isEmpty)
                        ? Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey.shade400,
                        )
                        : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Selamat Datang,",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_pin,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ).then((_) => setState(() => _loadData()));
              },
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                "Ganti Biodata",
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidingVehicleStats(List<CctvLocation> cctvLocations) {
    if (cctvLocations.isEmpty) {
      return const Center(
        child: Text("Tidak ada data CCTV untuk ditampilkan."),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 239, 239),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: cctvLocations.length,
              onPageChanged: (int page) => setState(() => _currentPage = page),
              itemBuilder:
                  (context, index) =>
                      _buildVehicleStatCard(cctvLocations[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(cctvLocations.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == index
                            ? const Color.fromARGB(255, 96, 80, 167)
                            : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStatCard(CctvLocation cctv) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cctv.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVehicleCount(
                  "Mobil",
                  cctv.vehicleData.mobil,
                  Icons.directions_car,
                ),
                _buildVehicleCount(
                  "Motor",
                  cctv.vehicleData.motor,
                  Icons.two_wheeler,
                ),
                _buildVehicleCount(
                  "Truk",
                  cctv.vehicleData.truk,
                  Icons.local_shipping,
                ),
                _buildVehicleCount(
                  "Darurat",
                  cctv.vehicleData.darurat,
                  Icons.emergency,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCount(String label, int count, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 30, color: Colors.grey.shade700),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 30),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 239, 239),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
