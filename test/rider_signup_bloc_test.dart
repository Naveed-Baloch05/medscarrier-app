import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/rider_signup/rider_signup_event.dart';
import 'package:medscarrier/bloc/rider_signup/rider_signup_state.dart';
import 'package:medscarrier/models/rider_application_model.dart';

void main() {
  group('RiderSignupBloc', () {
    test('RiderSignupReset event exists and can be dispatched', () {
      const event = RiderSignupReset();
      expect(event, isA<RiderSignupEvent>());
    });

    test('RiderSignupSubmitted carries all fields including password', () {
      const event = RiderSignupSubmitted(
        fullName: 'John Rider',
        email: 'john@test.com',
        phone: '07123456789',
        vehicleType: 'Bike',
        vehicleReg: 'AB12 CDE',
        password: 'password123',
      );
      expect(event.fullName, 'John Rider');
      expect(event.email, 'john@test.com');
      expect(event.phone, '07123456789');
      expect(event.vehicleType, 'Bike');
      expect(event.vehicleReg, 'AB12 CDE');
      expect(event.password, 'password123');
      expect(event.licenseFront, isNull);
      expect(event.licenseBack, isNull);
    });

    test('RiderSignupSuccess is a valid state', () {
      const state = RiderSignupSuccess(RiderApplicationModel(
        applicationId: 'app-1',
        uid: 'uid-1',
        fullName: 'John Rider',
        email: 'john@test.com',
        phone: '07123456789',
        vehicleType: 'Bike',
        vehicleRegistrationNumber: 'AB12 CDE',
        status: 'pending',
      ));
      expect(state, isA<RiderSignupState>());
      expect(state.application.applicationId, 'app-1');
    });

    test('RiderSignupFailure carries error message', () {
      const state = RiderSignupFailure('Something went wrong');
      expect(state.message, 'Something went wrong');
    });
  });
}
