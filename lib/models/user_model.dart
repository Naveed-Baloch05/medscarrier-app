class UserModel {
  const UserModel({
    this.id,
    required this.email,
    this.name,
    this.phone,
    this.createdAt,
  });

  final String? id;
  final String email;
  final String? name;
  final String? phone;
  final DateTime? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String?,
      email: json['email'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
