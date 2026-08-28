abstract class RiderProfileState {
  const RiderProfileState();
}

class RiderProfileInitial extends RiderProfileState {
  const RiderProfileInitial();
}

class RiderProfileLoading extends RiderProfileState {
  const RiderProfileLoading();
}

class RiderProfileLoaded extends RiderProfileState {
  const RiderProfileLoaded({required this.data});

  final Map<String, dynamic> data;

  String get riderId => (data['id'] as String?) ?? (data['uid'] as String?) ?? '';
  String get fullName =>
      (data['fullName'] as String?) ?? (data['name'] as String?) ?? '';
  String get phone => (data['phone'] as String?) ?? '';
  String get email => (data['email'] as String?) ?? '';
  String get vehicleType => (data['vehicleType'] as String?) ?? '';
  String get vehicleReg =>
      (data['vehicleReg'] as String?) ??
      (data['vehicleRegistrationNumber'] as String?) ??
      '';
  int get deliveries => (data['deliveries'] as int?) ?? 0;
  double get rating => (data['rating'] as num?)?.toDouble() ?? 0;
  bool get isOnline => (data['online'] as bool?) ?? false;
  bool get notificationsEnabled =>
      (data['notificationsEnabled'] as bool?) ?? true;
  String? get profilePhotoUrl => (data['profilePhotoUrl'] as String?);
}

class RiderProfileUpdating extends RiderProfileState {
  const RiderProfileUpdating(this.data);

  final Map<String, dynamic> data;
}

class RiderProfileError extends RiderProfileState {
  const RiderProfileError(this.message);

  final String message;
}

class RiderProfileOperationSuccess extends RiderProfileState {
  const RiderProfileOperationSuccess(this.message, this.data);

  final String message;
  final Map<String, dynamic> data;
}
