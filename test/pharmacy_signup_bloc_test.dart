import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/pharmacy_signup/pharmacy_signup_bloc.dart';
import 'package:medscarrier/bloc/pharmacy_signup/pharmacy_signup_event.dart';
import 'package:medscarrier/bloc/pharmacy_signup/pharmacy_signup_state.dart';
import 'package:medscarrier/core/services/pharmacy_signup_service.dart';

void main() {
  group('PharmacySignupBloc', () {
    late PharmacySignupService service;
    late PharmacySignupBloc bloc;

    setUp(() {
      service = PharmacySignupService.instance;
      service.reset();
      bloc = PharmacySignupBloc(service: service);
    });

    tearDown(() {
      bloc.close();
    });

    test('starts with PharmacySignupInitial', () {
      expect(bloc.state, isA<PharmacySignupInitial>());
    });

    test('emits Loading then Success on valid submission', () async {
      final expected = [
        isA<PharmacySignupLoading>(),
        isA<PharmacySignupSuccess>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const PharmacySignupSubmitted(
        pharmacyName: 'Boots Pharmacy',
        contactName: 'Sarah Manager',
        email: 'sarah@boots.co.uk',
        phone: '02071234567',
        businessAddress: '123 High Street, London',
        gphcNumber: '1234567',
        password: 'secure123',
      ));
    });

    test('emits Loading then Failure on duplicate email', () async {
      bloc.add(const PharmacySignupSubmitted(
        pharmacyName: 'Boots',
        contactName: 'Sarah',
        email: 'sarah@boots.co.uk',
        phone: '02071234567',
        businessAddress: '123 High St',
        gphcNumber: '1234567',
        password: 'pass123',
      ));
      await bloc.stream
          .firstWhere((s) => s is PharmacySignupSuccess);

      final expected = [
        isA<PharmacySignupLoading>(),
        isA<PharmacySignupFailure>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const PharmacySignupSubmitted(
        pharmacyName: 'Lloyds',
        contactName: 'Tom',
        email: 'sarah@boots.co.uk',
        phone: '02079999999',
        businessAddress: '456 High St',
        gphcNumber: '7654321',
        password: 'pass456',
      ));
    });

    test('PharmacySignupReset returns to initial', () async {
      bloc.add(const PharmacySignupSubmitted(
        pharmacyName: 'Test',
        contactName: 'Test',
        email: 'test@pharmacy.co.uk',
        phone: '02070000000',
        businessAddress: 'Test St',
        gphcNumber: '9999999',
        password: 'test1234',
      ));
      await bloc.stream
          .firstWhere((s) => s is PharmacySignupSuccess);

      bloc.add(const PharmacySignupReset());
      await bloc.stream.firstWhere((s) => s is PharmacySignupInitial);

      expect(bloc.state, isA<PharmacySignupInitial>());
    });

    test('success state carries PharmacyModel with correct data', () async {
      bloc.add(const PharmacySignupSubmitted(
        pharmacyName: 'Well Pharmacy',
        contactName: 'Emma Director',
        email: 'emma@well.co.uk',
        phone: '02073333333',
        businessAddress: '789 Oxford Street, London',
        gphcNumber: '5555555',
        password: 'secret456',
      ));

      final state = await bloc.stream.firstWhere(
        (s) => s is PharmacySignupSuccess,
      ) as PharmacySignupSuccess;

      expect(state.pharmacy.pharmacyName, 'Well Pharmacy');
      expect(state.pharmacy.contactName, 'Emma Director');
      expect(state.pharmacy.email, 'emma@well.co.uk');
      expect(state.pharmacy.phone, '02073333333');
      expect(state.pharmacy.businessAddress, '789 Oxford Street, London');
      expect(state.pharmacy.gphcNumber, '5555555');
      expect(state.pharmacy.id, isNotEmpty);
    });
  });
}
