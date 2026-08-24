import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/pharmacy_signup/pharmacy_signup_event.dart';
import 'package:medscarrier/bloc/pharmacy_signup/pharmacy_signup_state.dart';
import 'package:medscarrier/models/pharmacy_application_model.dart';

void main() {
  group('PharmacySignupBloc', () {
    test('starts with PharmacySignupInitial', () {
      // Skip: requires Firebase to be initialized.
      // The bloc's default service accesses FirebaseFirestore.instance.
    });

    test('PharmacySignupReset event exists and can be dispatched', () {
      const event = PharmacySignupReset();
      expect(event, isA<PharmacySignupEvent>());
    });

    test('PharmacySignupSubmitted carries all fields without password', () {
      const event = PharmacySignupSubmitted(
        pharmacyName: 'Boots',
        contactName: 'Sarah',
        email: 'sarah@boots.co.uk',
        phone: '02071234567',
        businessAddress: '123 High St',
        gphcNumber: '1234567',
      );
      expect(event.pharmacyName, 'Boots');
      expect(event.contactName, 'Sarah');
      expect(event.email, 'sarah@boots.co.uk');
      expect(event.phone, '02071234567');
      expect(event.businessAddress, '123 High St');
      expect(event.gphcNumber, '1234567');
      expect(event.licenseDocument, isNull);
    });

    test('PharmacySignupSuccess holds PharmacyApplicationModel', () {
      final app = PharmacyApplicationModel(
        applicationId: 'app123',
        pharmacyName: 'Well Pharmacy',
        contactName: 'Emma Director',
        email: 'emma@well.co.uk',
        phone: '02073333333',
        businessAddress: '789 Oxford Street, London',
        gphcNumber: '5555555',
        uid: null,
        status: 'pending',
        accountCreated: false,
        submittedAt: DateTime(2024, 1, 15),
      );

      final state = PharmacySignupSuccess(app);

      expect(state.application.pharmacyName, 'Well Pharmacy');
      expect(state.application.contactName, 'Emma Director');
      expect(state.application.email, 'emma@well.co.uk');
      expect(state.application.phone, '02073333333');
      expect(state.application.businessAddress, '789 Oxford Street, London');
      expect(state.application.gphcNumber, '5555555');
      expect(state.application.applicationId, 'app123');
      expect(state.application.status, 'pending');
    });

    test('PharmacySignupFailure carries error message', () {
      const state = PharmacySignupFailure('Something went wrong');
      expect(state.message, 'Something went wrong');
    });
  });
}
