import '../../models/pharmacy_model.dart';

class PharmacyHomeService {
  PharmacyHomeService._();
  static final PharmacyHomeService instance = PharmacyHomeService._();

  final Map<String, PharmacyModel> _pharmacies = {
    'pharmacy_1': const PharmacyModel(
      id: 'pharmacy_1',
      pharmacyName: 'Boots Pharmacy',
      contactName: 'Sarah Manager',
      email: 'sarah@boots.co.uk',
      phone: '02071234567',
      businessAddress: '123 High Street, London',
      gphcNumber: '1234567',
    ),
    'pharmacy_2': const PharmacyModel(
      id: 'pharmacy_2',
      pharmacyName: 'Lloyds Pharmacy',
      contactName: 'Tom Director',
      email: 'tom@lloyds.co.uk',
      phone: '02079876543',
      businessAddress: '456 Oxford Street, London',
      gphcNumber: '7654321',
    ),
  };

  Future<PharmacyModel?> getPharmacy(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _pharmacies[id];
  }

  void addPharmacy(PharmacyModel pharmacy) {
    _pharmacies[pharmacy.id] = pharmacy;
  }

  void reset() {
    _pharmacies.clear();
  }
}
