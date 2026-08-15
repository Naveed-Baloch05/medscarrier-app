import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // =========================
  // Create User Profile
  // =========================
  Future<void> createUser({
    required UserModel user,
  }) async {
    await _usersCollection.doc(user.id).set({
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'phone': user.phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // Get User Profile
  // =========================
  Future<UserModel?> getUser(String uid) async {
    final document = await _usersCollection.doc(uid).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    final data = document.data()!;

    return UserModel(
      id: data['id'] as String?,
      email: data['email'] as String? ?? '',
      name: data['name'] as String?,
      phone: data['phone'] as String?,
      createdAt: _convertTimestamp(data['createdAt']),
    );
  }

  // =========================
  // Update User Profile
  // =========================
  Future<void> updateUser({
    required String uid,
    String? name,
    String? phone,
  }) async {
    final Map<String, dynamic> data = {};

    if (name != null) {
      data['name'] = name;
    }

    if (phone != null) {
      data['phone'] = phone;
    }

    if (data.isNotEmpty) {
      await _usersCollection.doc(uid).update(data);
    }
  }

  // =========================
  // Delete User Profile
  // =========================
  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }

  // =========================
  // Convert Firestore Timestamp
  // =========================
  DateTime? _convertTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}