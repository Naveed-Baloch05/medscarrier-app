class PharmacyModel {
  const PharmacyModel({
    required this.id,
    required this.pharmacyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.businessAddress,
    required this.gphcNumber,
    this.createdAt,
  });

  final String id;
  final String pharmacyName;
  final String contactName;
  final String email;
  final String phone;
  final String businessAddress;
  final String gphcNumber;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'pharmacyName': pharmacyName,
        'contactName': contactName,
        'email': email,
        'phone': phone,
        'businessAddress': businessAddress,
        'gphcNumber': gphcNumber,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory PharmacyModel.fromJson(Map<String, dynamic> json) => PharmacyModel(
        id: json['id'] as String,
        pharmacyName: json['pharmacyName'] as String,
        contactName: json['contactName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        businessAddress: json['businessAddress'] as String,
        gphcNumber: json['gphcNumber'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}
