import '../../models/rider_model.dart';

class RiderHomeService {
  RiderHomeService._();
  static final RiderHomeService instance = RiderHomeService._();

  final Map<String, RiderModel> _riders = {
    'rider_1': const RiderModel(
      id: 'rider_1',
      fullName: 'Demo Rider',
      email: 'rider@test.com',
      phone: '07123456789',
      vehicleType: 'Bike',
      vehicleReg: 'AB12 CDE',
    ),
  };

  Future<RiderModel?> getRider(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _riders[id];
  }
}
