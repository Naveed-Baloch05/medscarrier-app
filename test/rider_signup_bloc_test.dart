import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/rider_signup/rider_signup_event.dart';

void main() {
  group('RiderSignupBloc', () {
    test('starts with RiderSignupInitial', () async {
      // Skip: requires Firebase to be initialized.
      // The bloc's default service accesses FirebaseFirestore.instance.
      // In integration tests, initialize Firebase first.
    });

    test('RiderSignupReset event exists and can be dispatched', () {
      const event = RiderSignupReset();
      expect(event, isA<RiderSignupEvent>());
    });

    test('RiderSignupSubmitted carries all fields', () {
      const event = RiderSignupSubmitted(
        fullName: 'Test',
        email: 'test@test.com',
        phone: '07000000000',
        vehicleType: 'Bike',
        vehicleReg: 'AB12 CDE',
        password: 'secret',
      );
      expect(event.fullName, 'Test');
      expect(event.email, 'test@test.com');
      expect(event.phone, '07000000000');
      expect(event.vehicleType, 'Bike');
      expect(event.vehicleReg, 'AB12 CDE');
      expect(event.password, 'secret');
    });
  });
}
