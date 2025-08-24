import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_client;

// Model untuk data profil pengguna
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String location;
  final String timeZone;
  final String photoURL;
  final String? photoPath; // Path file di Supabase untuk proses hapus
  final GeoPoint? geoCoordinates;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.location = "Belum diatur",
    this.timeZone = "WIB",
    this.photoURL = "",
    this.photoPath,
    this.geoCoordinates,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Pengguna',
      location: data['location'] ?? 'Belum diatur',
      timeZone: data['timeZone'] ?? 'WIB',
      photoURL: data['photoURL'] ?? '',
      photoPath: data['photoPath'],
      geoCoordinates: data['geoCoordinates'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'location': location,
      'timeZone': timeZone,
      'photoURL': photoURL,
      'photoPath': photoPath,
      'geoCoordinates': geoCoordinates,
    };
  }
}

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final supabase_client.SupabaseClient _supabase =
      supabase_client.Supabase.instance.client;

  Future<void> createUserProfile(User user, String name) async {
    final profile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: name,
    );
    await _db.collection('users').doc(user.uid).set(profile.toMap());
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    } else {
      return UserProfile(
        uid: user.uid,
        displayName: user.displayName ?? 'Pengguna',
        email: user.email ?? '',
        photoURL: user.photoURL ?? '',
      );
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update(data);
  }

  Future<Map<String, String>> uploadProfileImage(
    File imageFile,
    UserProfile? currentProfile,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Pengguna belum login");

    if (currentProfile?.photoPath != null &&
        currentProfile!.photoPath!.isNotEmpty) {
      try {
        await _supabase.storage.from('profile-images').remove([
          currentProfile.photoPath!,
        ]);
      } catch (e) {
        print("Error deleting old image: $e");
      }
    }

    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = '${user.uid}/$fileName';

    await _supabase.storage
        .from('foto-profil')
        .upload(
          path,
          imageFile,
          fileOptions: const supabase_client.FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    final publicUrl = _supabase.storage.from('foto-profil').getPublicUrl(path);
    return {'photoURL': publicUrl, 'photoPath': path};
  }
}
