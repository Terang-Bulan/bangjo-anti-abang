import 'package:flutter/material.dart';

enum NotificationType { info, warning, payment, emergencyVehicle }

class NotificationModel {
  final String title;
  final String message;
  final String timestamp;
  final NotificationType type;
  bool isRead;

  NotificationModel({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<NotificationModel> _allNotifications = [
    NotificationModel(
      title: "Ambulans Mendekat",
      message: "Sebuah ambulans terdeteksi di persimpangan Soekarno-Hatta.",
      timestamp: "Baru saja",
      type: NotificationType.emergencyVehicle,
      isRead: false,
    ),
    NotificationModel(
      title: "Iring-iringan Polisi",
      message: "Konvoi kendaraan polisi terdeteksi di Jalan Veteran.",
      timestamp: "2 menit yang lalu",
      type: NotificationType.emergencyVehicle,
      isRead: false,
    ),
    NotificationModel(
      title: "Pembayaran Berhasil",
      message: "Tagihan bulanan layanan CCTV telah berhasil dibayar.",
      timestamp: "1 jam yang lalu",
      type: NotificationType.payment,
      isRead: true,
    ),
    NotificationModel(
      title: "Pemadam Kebakaran",
      message: "Kendaraan pemadam kebakaran terdeteksi menuju Alun-Alun Kota.",
      timestamp: "5 menit yang lalu",
      type: NotificationType.emergencyVehicle,
      isRead: true,
    ),
  ];

  late List<NotificationModel> _emergencyNotifications;

  @override
  void initState() {
    super.initState();
    _emergencyNotifications =
        _allNotifications
            .where(
              (notification) =>
                  notification.type == NotificationType.emergencyVehicle,
            )
            .toList();
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _emergencyNotifications) {
        notification.isRead = true;
      }
    });
  }

  Icon _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.emergencyVehicle:
        return const Icon(
          Icons.emergency_outlined,
          color: Colors.red,
          size: 30,
        );
      default:
        return const Icon(Icons.info_outline, color: Colors.blue, size: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child:
                _emergencyNotifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 10, right: 10),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 96, 80, 167),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),

          const Expanded(
            child: Text(
              "Notifikasi Darurat",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _markAllAsRead,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Selesai",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Tidak ada notifikasi darurat",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _emergencyNotifications.length,
      itemBuilder: (context, index) {
        final notification = _emergencyNotifications[index];
        return Material(
          color: notification.isRead ? Colors.white : Colors.red.shade50,
          child: InkWell(
            onTap: () {
              setState(() {
                notification.isRead = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getIconForType(notification.type),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight:
                                notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.timestamp,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      margin: const EdgeInsets.only(left: 16, top: 4),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
