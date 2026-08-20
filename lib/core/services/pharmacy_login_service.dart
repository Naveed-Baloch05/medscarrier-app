import '../../models/pharmacy_model.dart';

class PharmacyLoginService {
  PharmacyLoginService._();
  static final PharmacyLoginService instance = PharmacyLoginService._();

  final List<PharmacyModel> _pharmacies = [
    const PharmacyModel(
      id: 'pharmacy_demo',
      pharmacyName: 'Boots Pharmacy',
      contactName: 'Sarah Manager',
      email: 'pharmacy@test.com',
      phone: '02071234567',
      businessAddress: '123 High Street, London',
      gphcNumber: '1234567',
    ),
  ];

  Future<PharmacyModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final pharmacy = _pharmacies.cast<PharmacyModel?>().firstWhere(
          (p) => p!.email.toLowerCase() == email.toLowerCase(),
          orElse: () => null,
        );

    if (pharmacy == null) {
      throw Exception('No account found for this email.');
    }

    if (password.length < 4) {
      throw Exception('Incorrect password.');
    }

    return pharmacy;
  }
}
