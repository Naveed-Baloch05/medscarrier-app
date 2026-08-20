class RiderModel {
  const RiderModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleReg,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleReg;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'vehicleType': vehicleType,
        'vehicleReg': vehicleReg,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory RiderModel.fromJson(Map<String, dynamic> json) => RiderModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        vehicleType: json['vehicleType'] as String,
        vehicleReg: json['vehicleReg'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}
