class RiderModel {
  const RiderModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleReg,
    this.online = false,
    this.active = true,
    this.location,
    this.deliveries = 0,
    this.currentOrder,
    this.lastSeen,
    this.deliveryStatus,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleReg;
  final bool online;
  final bool active;
  final Map<String, dynamic>? location;
  final int deliveries;
  final String? currentOrder;
  final DateTime? lastSeen;
  final String? deliveryStatus;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'vehicleType': vehicleType,
        'vehicleReg': vehicleReg,
        'online': online,
        'active': active,
        'location': location,
        'deliveries': deliveries,
        'currentOrder': currentOrder,
        'lastSeen': lastSeen?.toIso8601String(),
        'deliveryStatus': deliveryStatus,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory RiderModel.fromJson(Map<String, dynamic> json) => RiderModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        vehicleType: json['vehicleType'] as String,
        vehicleReg: json['vehicleReg'] as String,
        online: json['online'] as bool? ?? false,
        active: json['active'] as bool? ?? true,
        location: json['location'] as Map<String, dynamic>?,
        deliveries: json['deliveries'] as int? ?? 0,
        currentOrder: json['currentOrder'] as String?,
        lastSeen: json['lastSeen'] != null
            ? DateTime.parse(json['lastSeen'] as String)
            : null,
        deliveryStatus: json['deliveryStatus'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}
