abstract class PharmacyProfileState {
  const PharmacyProfileState();
}

class PharmacyProfileInitial extends PharmacyProfileState {
  const PharmacyProfileInitial();
}

class PharmacyProfileLoading extends PharmacyProfileState {
  const PharmacyProfileLoading();
}

class PharmacyProfileLoaded extends PharmacyProfileState {
  const PharmacyProfileLoaded({
    required this.data,
  });

  final Map<String, dynamic> data;

  String get uid => (data['uid'] as String?) ?? '';
  String get pharmacyName =>
      (data['pharmacyName'] as String?) ?? '';
  String get contactName =>
      (data['contactName'] as String?) ?? '';
  String get phone => (data['phone'] as String?) ?? '';
  String get email => (data['email'] as String?) ?? '';
  String get businessAddress =>
      (data['businessAddress'] as String?) ?? '';
  String get gphcNumber =>
      (data['gphcNumber'] as String?) ?? '';
  String get openingTime =>
      (data['openingTime'] as String?) ?? '09:00 AM';
  String get closingTime =>
      (data['closingTime'] as String?) ?? '10:00 PM';
  bool get notificationsEnabled =>
      data['notificationsEnabled'] as bool? ?? true;
  bool get pharmacyOpen => data['active'] as bool? ?? false;
  String? get profilePhotoUrl =>
      data['profilePhotoUrl'] as String?;
}

class PharmacyProfileUpdating extends PharmacyProfileState {
  const PharmacyProfileUpdating(this.data);

  final Map<String, dynamic> data;
}

class PharmacyProfileError extends PharmacyProfileState {
  const PharmacyProfileError(this.message);

  final String message;
}

class PharmacyProfileOperationSuccess extends PharmacyProfileState {
  const PharmacyProfileOperationSuccess(this.message, this.data);

  final String message;
  final Map<String, dynamic> data;
}
