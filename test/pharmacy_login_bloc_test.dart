import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/pharmacy_login/pharmacy_login_bloc.dart';
import 'package:medscarrier/bloc/pharmacy_login/pharmacy_login_event.dart';
import 'package:medscarrier/bloc/pharmacy_login/pharmacy_login_state.dart';
import 'package:medscarrier/core/services/pharmacy_login_service.dart';

void main() {
  group('PharmacyLoginBloc', () {
    late PharmacyLoginService service;
    late PharmacyLoginBloc bloc;

    setUp(() {
      service = PharmacyLoginService.instance;
      bloc = PharmacyLoginBloc(service: service);
    });

    tearDown(() {
      bloc.close();
    });

    test('starts with PharmacyLoginInitial', () {
      expect(bloc.state, isA<PharmacyLoginInitial>());
    });

    test('emits Loading then Success on valid credentials', () async {
      final expected = [
        isA<PharmacyLoginLoading>(),
        isA<PharmacyLoginSuccess>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const PharmacyLoginSubmitted(
        email: 'pharmacy@test.com',
        password: 'password123',
      ));
    });

    test('emits Loading then Failure on unknown email', () async {
      final expected = [
        isA<PharmacyLoginLoading>(),
        isA<PharmacyLoginFailure>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const PharmacyLoginSubmitted(
        email: 'unknown@test.com',
        password: 'password123',
      ));
    });

    test('emits Loading then Failure on short password', () async {
      final expected = [
        isA<PharmacyLoginLoading>(),
        isA<PharmacyLoginFailure>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const PharmacyLoginSubmitted(
        email: 'pharmacy@test.com',
        password: 'ab',
      ));
    });

    test('success state carries PharmacyModel with correct data', () async {
      bloc.add(const PharmacyLoginSubmitted(
        email: 'pharmacy@test.com',
        password: 'password123',
      ));

      final state = await bloc.stream.firstWhere(
        (s) => s is PharmacyLoginSuccess,
      ) as PharmacyLoginSuccess;

      expect(state.pharmacy.pharmacyName, 'Boots Pharmacy');
      expect(state.pharmacy.email, 'pharmacy@test.com');
      expect(state.pharmacy.contactName, 'Sarah Manager');
    });
  });
}
