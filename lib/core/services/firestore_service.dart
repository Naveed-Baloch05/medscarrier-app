
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';

class FirestoreService {
FirestoreService._();

static final FirestoreService instance = FirestoreService._();

FirebaseFirestore get _firestore => FirebaseFirestore.instance;

// General users collection.
// Used by Free Trial / normal authentication.
CollectionReference<Map<String, dynamic>> get _usersCollection =>
_firestore.collection('users');

// Pharmacies managed by Admin.
CollectionReference<Map<String, dynamic>> get _pharmaciesCollection =>
_firestore.collection('pharmacies');

// Riders managed by Admin.
CollectionReference<Map<String, dynamic>> get _ridersCollection =>
_firestore.collection('riders');

// Orders managed by Admin.
CollectionReference<Map<String, dynamic>> get _ordersCollection =>
_firestore.collection('orders');

// ============================================================
// USERS
// ============================================================

// ------------------------------------------------------------
// Create User Profile
// ------------------------------------------------------------

Future<void> createUser({
required UserModel user,
String role = 'user',
}) async {
await _usersCollection.doc(user.id).set({
'id': user.id,
'email': user.email,
'name': user.name,
'phone': user.phone,
'role': role,
'createdAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Get User Profile
// ------------------------------------------------------------

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
role: data['role'] as String?,
createdAt: _convertTimestamp(data['createdAt']),
);
}

// ------------------------------------------------------------
// Get User Role
// ------------------------------------------------------------

Future<String?> getUserRole(String uid) async {
final document = await _usersCollection.doc(uid).get();

if (!document.exists || document.data() == null) {
return null;
}

return document.data()!['role'] as String?;
}

// ------------------------------------------------------------
// Check Admin
// ------------------------------------------------------------

Future<bool> isAdmin(String uid) async {
final role = await getUserRole(uid);

return role == 'admin';
}

// ------------------------------------------------------------
// Update User Profile
// ------------------------------------------------------------

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

// ------------------------------------------------------------
// Delete User Profile
// ------------------------------------------------------------

Future<void> deleteUser(String uid) async {
await _usersCollection.doc(uid).delete();
}

// ============================================================
// PHARMACIES
// ============================================================

// ------------------------------------------------------------
// Create Pharmacy
// ------------------------------------------------------------

Future<void> createPharmacy({
required String pharmacyId,
required Map<String, dynamic> pharmacyData,
}) async {
await _pharmaciesCollection.doc(pharmacyId).set({
...pharmacyData,
'id': pharmacyId,
'createdAt': FieldValue.serverTimestamp(),
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Get Pharmacy
// ------------------------------------------------------------

Future<DocumentSnapshot<Map<String, dynamic>>> getPharmacy(
String pharmacyId,
) async {
return await _pharmaciesCollection.doc(pharmacyId).get();
}

// ------------------------------------------------------------
// Get All Pharmacies
// ------------------------------------------------------------

Future<QuerySnapshot<Map<String, dynamic>>> getAllPharmacies() async {
return await _pharmaciesCollection
    .orderBy('createdAt', descending: true)
    .get();
}

// ------------------------------------------------------------
// Update Pharmacy
// ------------------------------------------------------------

Future<void> updatePharmacy({
required String pharmacyId,
required Map<String, dynamic> data,
}) async {
await _pharmaciesCollection.doc(pharmacyId).update({
...data,
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Delete Pharmacy
// ------------------------------------------------------------

Future<void> deletePharmacy(String pharmacyId) async {
await _pharmaciesCollection.doc(pharmacyId).delete();
}

// ------------------------------------------------------------
// Approve Pharmacy
// ------------------------------------------------------------

Future<void> approvePharmacy(String pharmacyId) async {
await _pharmaciesCollection.doc(pharmacyId).update({
'status': 'Approved',
'active': true,
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Suspend Pharmacy
// ------------------------------------------------------------

Future<void> suspendPharmacy(String pharmacyId) async {
await _pharmaciesCollection.doc(pharmacyId).update({
'status': 'Suspended',
'active': false,
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Activate Pharmacy
// ------------------------------------------------------------

Future<void> activatePharmacy(String pharmacyId) async {
await _pharmaciesCollection.doc(pharmacyId).update({
'active': true,
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Deactivate Pharmacy
// ------------------------------------------------------------

Future<void> deactivatePharmacy(String pharmacyId) async {
await _pharmaciesCollection.doc(pharmacyId).update({
'active': false,
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ============================================================
// RIDERS
// ============================================================

// ------------------------------------------------------------
// Create Rider
// ------------------------------------------------------------

Future<void> createRider({
required String riderId,
required Map<String, dynamic> riderData,
}) async {
await _ridersCollection.doc(riderId).set({
...riderData,
'id': riderId,
'createdAt': FieldValue.serverTimestamp(),
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Get Rider
// ------------------------------------------------------------

Future<DocumentSnapshot<Map<String, dynamic>>> getRider(
String riderId,
) async {
return await _ridersCollection.doc(riderId).get();
}

// ------------------------------------------------------------
// Get All Riders
// ------------------------------------------------------------

Future<QuerySnapshot<Map<String, dynamic>>> getAllRiders() async {
return await _ridersCollection
    .orderBy('createdAt', descending: true)
    .get();
}

// ------------------------------------------------------------
// Update Rider
// ------------------------------------------------------------

Future<void> updateRider({
required String riderId,
required Map<String, dynamic> data,
}) async {
await _ridersCollection.doc(riderId).update({
...data,
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Activate Rider
// ------------------------------------------------------------

Future<void> activateRider(String riderId) async {
await _ridersCollection.doc(riderId).update({
'active': true,
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Deactivate Rider
// ------------------------------------------------------------

Future<void> deactivateRider(String riderId) async {
await _ridersCollection.doc(riderId).update({
'active': false,
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ============================================================
// ORDERS
// ============================================================

// ------------------------------------------------------------
// Get All Orders
// ------------------------------------------------------------

Future<QuerySnapshot<Map<String, dynamic>>> getAllOrders() async {
return await _ordersCollection
    .orderBy('createdAt', descending: true)
    .get();
}

// ------------------------------------------------------------
// Get Single Order
// ------------------------------------------------------------

Future<DocumentSnapshot<Map<String, dynamic>>> getOrder(
String orderId,
) async {
return await _ordersCollection.doc(orderId).get();
}

// ------------------------------------------------------------
// Update Order
// ------------------------------------------------------------

Future<void> updateOrder({
required String orderId,
required Map<String, dynamic> data,
}) async {
await _ordersCollection.doc(orderId).update({
...data,
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Assign Order To Rider
// ------------------------------------------------------------

Future<void> assignOrderToRider({
required String orderId,
required String riderId,
}) async {
await _ordersCollection.doc(orderId).update({
'riderId': riderId,
'status': 'Assigned',
'assignedAt': FieldValue.serverTimestamp(),
'updatedAt': FieldValue.serverTimestamp(),
});
}

// ============================================================
// RIDER LOCATION
// ============================================================

// ------------------------------------------------------------
// Update Rider Location
// ------------------------------------------------------------

Future<void> updateRiderLocation({
required String riderId,
required double latitude,
required double longitude,
}) async {
await _ridersCollection.doc(riderId).update({
'location': {
'latitude': latitude,
'longitude': longitude,
},
'locationUpdatedAt': FieldValue.serverTimestamp(),
});
}

// ------------------------------------------------------------
// Get Active Riders
// ------------------------------------------------------------

Future<QuerySnapshot<Map<String, dynamic>>> getActiveRiders() async {
return await _ridersCollection
    .where('active', isEqualTo: true)
    .get();
}

// ============================================================
// REPORT / DASHBOARD DATA
// ============================================================

// ------------------------------------------------------------
// Get Active Pharmacies
// ------------------------------------------------------------

Future<QuerySnapshot<Map<String, dynamic>>>
getActivePharmacies() async {
return await _pharmaciesCollection
    .where('active', isEqualTo: true)
    .get();
}

// ------------------------------------------------------------
// Get Pending Pharmacies
// ------------------------------------------------------------

Future<QuerySnapshot<Map<String, dynamic>>>
getPendingPharmacies() async {
return await _pharmaciesCollection
    .where('status', isEqualTo: 'Pending')
    .get();
}

// ------------------------------------------------------------
// Get Active Orders
// ------------------------------------------------------------

Future<QuerySnapshot<Map<String, dynamic>>>
getActiveOrders() async {
return await _ordersCollection
    .where(
'status',
whereIn: [
'Pending',
'Assigned',
'Picked Up',
'Out for Delivery',
],
)
    .get();
}

// ============================================================
// TIMESTAMP CONVERSION
// ============================================================

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

