import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/rider_login/rider_login_bloc.dart';
import 'package:medscarrier/bloc/rider_login/rider_login_event.dart';
import 'package:medscarrier/bloc/rider_login/rider_login_state.dart';
import 'package:medscarrier/core/services/rider_login_service.dart';

void main() {
  group('RiderLoginBloc', () {
    late RiderLoginService service;
    late RiderLoginBloc bloc;

    setUp(() {
      service = RiderLoginService.instance;
      bloc = RiderLoginBloc(service: service);
    });

    tearDown(() {
      bloc.close();
    });

    test('starts with RiderLoginInitial', () {
      expect(bloc.state, isA<RiderLoginInitial>());
    });

    test('emits Loading then Success on valid credentials', () async {
      final expected = [
        isA<RiderLoginLoading>(),
        isA<RiderLoginSuccess>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const RiderLoginSubmitted(
        email: 'rider@test.com',
        password: 'password123',
      ));
    });

    test('emits Loading then Failure on unknown email', () async {
      final expected = [
        isA<RiderLoginLoading>(),
        isA<RiderLoginFailure>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const RiderLoginSubmitted(
        email: 'unknown@test.com',
        password: 'password123',
      ));
    });

    test('emits Loading then Failure on short password', () async {
      final expected = [
        isA<RiderLoginLoading>(),
        isA<RiderLoginFailure>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const RiderLoginSubmitted(
        email: 'rider@test.com',
        password: 'ab',
      ));
    });

    test('success state carries RiderModel with correct data', () async {
      bloc.add(const RiderLoginSubmitted(
        email: 'rider@test.com',
        password: 'password123',
      ));

      final state = await bloc.stream.firstWhere(
        (s) => s is RiderLoginSuccess,
      ) as RiderLoginSuccess;

      expect(state.rider.fullName, 'Demo Rider');
      expect(state.rider.email, 'rider@test.com');
      expect(state.rider.vehicleType, 'Bike');
    });
  });
}
