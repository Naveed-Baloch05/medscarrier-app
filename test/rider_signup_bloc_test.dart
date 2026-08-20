import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/rider_signup/rider_signup_bloc.dart';
import 'package:medscarrier/bloc/rider_signup/rider_signup_event.dart';
import 'package:medscarrier/bloc/rider_signup/rider_signup_state.dart';
import 'package:medscarrier/core/services/rider_signup_service.dart';

void main() {
  group('RiderSignupBloc', () {
    late RiderSignupService service;
    late RiderSignupBloc bloc;

    setUp(() {
      service = RiderSignupService.instance;
      service.reset();
      bloc = RiderSignupBloc(service: service);
    });

    tearDown(() {
      bloc.close();
    });

    test('starts with RiderSignupInitial', () {
      expect(bloc.state, isA<RiderSignupInitial>());
    });

    test('emits Loading then Success on valid submission', () async {
      final expected = [
        isA<RiderSignupLoading>(),
        isA<RiderSignupSuccess>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const RiderSignupSubmitted(
        fullName: 'John Rider',
        email: 'john@test.com',
        phone: '07123456789',
        vehicleType: 'Bike',
        vehicleReg: 'AB12 CDE',
        password: 'password123',
      ));
    });

    test('emits Loading then Failure on duplicate email', () async {
      // First register
      bloc.add(const RiderSignupSubmitted(
        fullName: 'John Rider',
        email: 'john@test.com',
        phone: '07123456789',
        vehicleType: 'Bike',
        vehicleReg: 'AB12 CDE',
        password: 'password123',
      ));
      await bloc.stream
          .firstWhere((s) => s is RiderSignupSuccess);

      // Now try duplicate
      final expected = [
        isA<RiderSignupLoading>(),
        isA<RiderSignupFailure>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const RiderSignupSubmitted(
        fullName: 'Jane',
        email: 'john@test.com',
        phone: '07999999999',
        vehicleType: 'Car',
        vehicleReg: 'XY99 ZZZ',
        password: 'pass456',
      ));
    });

    test('RiderSignupReset returns to initial', () async {
      bloc.add(const RiderSignupSubmitted(
        fullName: 'Test',
        email: 'test@test.com',
        phone: '07111111111',
        vehicleType: 'Scooter',
        vehicleReg: 'SC01 ABC',
        password: 'test1234',
      ));
      await bloc.stream
          .firstWhere((s) => s is RiderSignupSuccess);

      bloc.add(const RiderSignupReset());
      await bloc.stream.firstWhere((s) => s is RiderSignupInitial);

      expect(bloc.state, isA<RiderSignupInitial>());
    });

    test('success state carries RiderModel with correct data', () async {
      bloc.add(const RiderSignupSubmitted(
        fullName: 'Alice Rider',
        email: 'alice@test.com',
        phone: '07222222222',
        vehicleType: 'Car',
        vehicleReg: 'CD34 EFG',
        password: 'secret123',
      ));

      final state = await bloc.stream.firstWhere(
        (s) => s is RiderSignupSuccess,
      ) as RiderSignupSuccess;

      expect(state.rider.fullName, 'Alice Rider');
      expect(state.rider.email, 'alice@test.com');
      expect(state.rider.phone, '07222222222');
      expect(state.rider.vehicleType, 'Car');
      expect(state.rider.vehicleReg, 'CD34 EFG');
      expect(state.rider.id, isNotEmpty);
    });
  });
}
