import '../../models/pharmacy_model.dart';

class PharmacySignupService {
  PharmacySignupService._();
  static final PharmacySignupService instance = PharmacySignupService._();

  final List<PharmacyModel> _pharmacies = [];

  Future<PharmacyModel> register({
    required String pharmacyName,
    required String contactName,
    required String email,
    required String phone,
    required String businessAddress,
    required String gphcNumber,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final exists = _pharmacies.any(
      (p) => p.email.toLowerCase() == email.toLowerCase(),
    );
    if (exists) {
      throw Exception('An account with this email already exists.');
    }

    final pharmacy = PharmacyModel(
      id: 'pharmacy_${_pharmacies.length + 1}',
      pharmacyName: pharmacyName,
      contactName: contactName,
      email: email,
      phone: phone,
      businessAddress: businessAddress,
      gphcNumber: gphcNumber,
      createdAt: DateTime.now(),
    );

    _pharmacies.add(pharmacy);
    return pharmacy;
  }

  void reset() => _pharmacies.clear();
}
