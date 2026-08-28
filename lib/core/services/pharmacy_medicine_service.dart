import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/medicine_model.dart';

class PharmacyMedicineService {
  PharmacyMedicineService._();
  static final PharmacyMedicineService instance =
      PharmacyMedicineService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _medicinesRef(
    String pharmacyId,
  ) =>
      _firestore
          .collection('pharmacy_medicines')
          .doc(pharmacyId)
          .collection('medicines');

  Future<List<MedicineModel>> getMedicines(String pharmacyId) async {
    final snapshot = await _medicinesRef(pharmacyId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MedicineModel.fromFirestore(doc))
        .toList();
  }

  Future<MedicineModel> addMedicine({
    required String pharmacyId,
    required String name,
    required String genericName,
    required String category,
    required int stock,
    required double price,
    required bool prescription,
    required int lowStockThreshold,
  }) async {
    final docRef = await _medicinesRef(pharmacyId).add({
      'name': name,
      'genericName': genericName,
      'category': category,
      'stock': stock,
      'price': price,
      'prescription': prescription,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return MedicineModel.fromFirestore(doc);
  }

  Future<void> updateMedicine({
    required String pharmacyId,
    required String medicineId,
    required String name,
    required String genericName,
    required String category,
    required int stock,
    required double price,
    required bool prescription,
    required int lowStockThreshold,
  }) async {
    await _medicinesRef(pharmacyId).doc(medicineId).update({
      'name': name,
      'genericName': genericName,
      'category': category,
      'stock': stock,
      'price': price,
      'prescription': prescription,
      'lowStockThreshold': lowStockThreshold,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMedicine({
    required String pharmacyId,
    required String medicineId,
  }) async {
    await _medicinesRef(pharmacyId).doc(medicineId).delete();
  }
}
