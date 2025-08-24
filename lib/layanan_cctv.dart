import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

class VehicleData {
  final int mobil;
  final int motor;
  final int truk;
  final int darurat;

  VehicleData({
    this.mobil = 0,
    this.motor = 0,
    this.truk = 0,
    this.darurat = 0,
  });

  factory VehicleData.fromFirestore(Map<String, dynamic> data) {
    return VehicleData(
      mobil: data['mobil'] ?? 0,
      motor: data['motor'] ?? 0,
      truk: data['truk'] ?? 0,
      darurat: data['darurat'] ?? 0,
    );
  }
}

class CctvLocation {
  final String name;
  final String streamId;
  final String address;
  final String latitude;
  final String longitude;
  final VehicleData vehicleData;

  CctvLocation({
    required this.name,
    required this.streamId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.vehicleData,
  });

  factory CctvLocation.fromJson(
    Map<String, dynamic> json,
    VehicleData vehicleData,
  ) {
    return CctvLocation(
      name: json['name'] ?? 'Lokasi Tidak Dikenal',
      streamId: json['stream_id'] ?? '',
      address: json['address'] ?? 'Alamat tidak tersedia',
      latitude: json['latitude'] ?? '0.0',
      longitude: json['longitude'] ?? '0.0',
      vehicleData: vehicleData,
    );
  }

  String get streamWebUrl {
    return 'http://stream.cctv.malangkota.go.id/WebRTCApp/streams/$streamId.m3u8';
  }
}

class CctvDataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<CctvLocation>> fetchAllCctvData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/dataCCTV/dataCCTV.json',
      );
      final jsonResponse = json.decode(jsonString);
      final List<dynamic> cctvRecords = jsonResponse['records'];

      final vehicleSnapshot = await _db.collection('vehicle_counts').get();

      final Map<String, VehicleData> vehicleDataMap = {
        for (var doc in vehicleSnapshot.docs)
          doc.id: VehicleData.fromFirestore(doc.data()),
      };

      List<CctvLocation> combinedList = [];
      for (var record in cctvRecords) {
        String streamId = record['stream_id'];
        VehicleData vehicleData = vehicleDataMap[streamId] ?? VehicleData();
        combinedList.add(CctvLocation.fromJson(record, vehicleData));
      }
      return combinedList;
    } catch (e) {
      print("Error fetching CCTV data: $e");
      return [];
    }
  }
}
