import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/pharmacy_login/pharmacy_login_bloc.dart';
import 'package:medscarrier/bloc/pharmacy_login/pharmacy_login_event.dart';
import 'package:medscarrier/bloc/pharmacy_login/pharmacy_login_state.dart';
import 'package:medscarrier/models/pharmacy_model.dart';

void main() {
  group('PharmacyLoginBloc', () {
    late PharmacyLoginBloc bloc;

    setUp(() {
      bloc = PharmacyLoginBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('starts with PharmacyLoginInitial', () {
      expect(bloc.state, isA<PharmacyLoginInitial>());
    });

    test('PharmacyLoginSubmitted carries email and password', () {
      const event = PharmacyLoginSubmitted(
        email: 'pharmacy@test.com',
        password: 'password123',
      );
      expect(event.email, 'pharmacy@test.com');
      expect(event.password, 'password123');
    });

    test('PharmacyLoginReset event can be dispatched', () {
      const event = PharmacyLoginReset();
      expect(event, isA<PharmacyLoginEvent>());
    });

    test('PharmacyLoginSuccess carries PharmacyModel with correct data', () {
      const pharmacy = PharmacyModel(
        id: 'pharm_1',
        pharmacyName: 'Boots Pharmacy',
        contactName: 'Sarah Manager',
        email: 'pharmacy@test.com',
        phone: '02071234567',
        businessAddress: '123 High St',
        gphcNumber: '1234567',
      );

      const state = PharmacyLoginSuccess(pharmacy);
      expect(state.pharmacy.pharmacyName, 'Boots Pharmacy');
      expect(state.pharmacy.email, 'pharmacy@test.com');
      expect(state.pharmacy.contactName, 'Sarah Manager');
    });

    test('PharmacyLoginFailure carries error message', () {
      const state = PharmacyLoginFailure('Invalid credentials');
      expect(state.message, 'Invalid credentials');
    });
  });
}
