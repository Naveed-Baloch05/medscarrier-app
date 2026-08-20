import '../../models/rider_model.dart';

class RiderLoginService {
  RiderLoginService._();
  static final RiderLoginService instance = RiderLoginService._();

  final List<RiderModel> _riders = [
    const RiderModel(
      id: 'rider_demo',
      fullName: 'Demo Rider',
      email: 'rider@test.com',
      phone: '07123456789',
      vehicleType: 'Bike',
      vehicleReg: 'AB12 CDE',
    ),
  ];

  Future<RiderModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final rider = _riders.cast<RiderModel?>().firstWhere(
          (r) => r!.email.toLowerCase() == email.toLowerCase(),
          orElse: () => null,
        );

    if (rider == null) {
      throw Exception('No account found for this email.');
    }

    if (password.length < 4) {
      throw Exception('Incorrect password.');
    }

    return rider;
  }
}
