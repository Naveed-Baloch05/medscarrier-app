import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/pharmacy_home/pharmacy_home_bloc.dart';
import 'package:medscarrier/bloc/pharmacy_home/pharmacy_home_event.dart';
import 'package:medscarrier/bloc/pharmacy_home/pharmacy_home_state.dart';

void main() {
  group('PharmacyHomeEvent', () {
    test('LoadPharmacyHome is const', () {
      const event = LoadPharmacyHome();
      expect(event, isA<PharmacyHomeEvent>());
    });

    test('PharmacyHomeRefreshed is const', () {
      const event = PharmacyHomeRefreshed();
      expect(event, isA<PharmacyHomeEvent>());
    });
  });

  group('PharmacyHomeState', () {
    test('PharmacyHomeInitial is const', () {
      const state = PharmacyHomeInitial();
      expect(state, isA<PharmacyHomeState>());
    });

    test('PharmacyHomeLoading is const', () {
      const state = PharmacyHomeLoading();
      expect(state, isA<PharmacyHomeState>());
    });

    test('PharmacyHomeError carries message', () {
      const state = PharmacyHomeError('Something went wrong');
      expect(state.message, 'Something went wrong');
    });
  });

  group('PharmacyHomeBloc', () {
    late PharmacyHomeBloc bloc;

    setUp(() {
      bloc = PharmacyHomeBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('starts with PharmacyHomeInitial', () {
      expect(bloc.state, isA<PharmacyHomeInitial>());
    });

    test('emits Loading then Loaded with mock data', () async {
      final expected = [
        isA<PharmacyHomeLoading>(),
        isA<PharmacyHomeLoaded>(),
      ];

      expectLater(bloc.stream, emitsInOrder(expected));

      bloc.add(const LoadPharmacyHome());
    });

    test('loaded state has mock pharmacy data', () async {
      bloc.add(const LoadPharmacyHome());

      final state = await bloc.stream.firstWhere(
        (s) => s is PharmacyHomeLoaded,
      ) as PharmacyHomeLoaded;

      expect(state.pharmacy.pharmacyName, isNotEmpty);
      expect(state.totalOrders, greaterThanOrEqualTo(0));
      expect(state.activeOrders, greaterThanOrEqualTo(0));
    });
  });
}
