import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/rider_login/rider_login_bloc.dart';
import 'package:medscarrier/bloc/rider_login/rider_login_event.dart';
import 'package:medscarrier/bloc/rider_login/rider_login_state.dart';
import 'package:medscarrier/models/rider_model.dart';

void main() {
  group('RiderLoginBloc', () {
    late RiderLoginBloc bloc;

    setUp(() {
      bloc = RiderLoginBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('starts with RiderLoginInitial', () {
      expect(bloc.state, isA<RiderLoginInitial>());
    });

    test('RiderLoginSubmitted carries email and password', () {
      const event = RiderLoginSubmitted(
        email: 'rider@test.com',
        password: 'password123',
      );
      expect(event.email, 'rider@test.com');
      expect(event.password, 'password123');
    });

    test('RiderLoginReset event can be dispatched', () {
      const event = RiderLoginReset();
      expect(event, isA<RiderLoginEvent>());
    });

    test('RiderLoginSuccess carries RiderModel with correct data', () {
      const rider = RiderModel(
        id: 'rider_1',
        fullName: 'Demo Rider',
        email: 'rider@test.com',
        phone: '07123456789',
        vehicleType: 'Bike',
        vehicleReg: 'AB12 CDE',
      );

      const state = RiderLoginSuccess(rider);
      expect(state.rider.fullName, 'Demo Rider');
      expect(state.rider.email, 'rider@test.com');
      expect(state.rider.vehicleType, 'Bike');
    });

    test('RiderLoginFailure carries error message', () {
      const state = RiderLoginFailure('Invalid credentials');
      expect(state.message, 'Invalid credentials');
    });
  });
}
