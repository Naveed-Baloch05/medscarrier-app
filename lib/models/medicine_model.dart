import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineModel {
  const MedicineModel({
    required this.id,
    required this.name,
    required this.genericName,
    required this.category,
    required this.stock,
    required this.price,
    required this.prescription,
    required this.lowStockThreshold,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String genericName;
  final String category;
  final int stock;
  final double price;
  final bool prescription;
  final int lowStockThreshold;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLowStock => stock <= lowStockThreshold;

  factory MedicineModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return MedicineModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      genericName: data['genericName'] as String? ?? '',
      category: data['category'] as String? ?? 'OTC',
      stock: data['stock'] as int? ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      prescription: data['prescription'] as bool? ?? false,
      lowStockThreshold: data['lowStockThreshold'] as int? ?? 10,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'genericName': genericName,
        'category': category,
        'stock': stock,
        'price': price,
        'prescription': prescription,
        'lowStockThreshold': lowStockThreshold,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
