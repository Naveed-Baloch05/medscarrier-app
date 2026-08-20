import '../../models/rider_model.dart';

class RiderSignupService {
  RiderSignupService._();
  static final RiderSignupService instance = RiderSignupService._();

  final List<RiderModel> _riders = [];

  Future<RiderModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String vehicleType,
    required String vehicleReg,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final exists = _riders.any(
      (r) => r.email.toLowerCase() == email.toLowerCase(),
    );
    if (exists) {
      throw Exception('An account with this email already exists.');
    }

    final rider = RiderModel(
      id: 'rider_${_riders.length + 1}',
      fullName: fullName,
      email: email,
      phone: phone,
      vehicleType: vehicleType,
      vehicleReg: vehicleReg,
      createdAt: DateTime.now(),
    );

    _riders.add(rider);
    return rider;
  }

  void reset() => _riders.clear();
}
