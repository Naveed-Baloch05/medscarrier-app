import 'package:flutter_test/flutter_test.dart';
import 'package:medscarrier/bloc/pharmacy_home/pharmacy_home_bloc.dart';
import 'package:medscarrier/bloc/pharmacy_home/pharmacy_home_event.dart';
import 'package:medscarrier/bloc/pharmacy_home/pharmacy_home_state.dart';

void main() {
  group('PharmacyHomeEvent', () {
    test('LoadPharmacyHome is const', () {
      const event = LoadPharmacyHome('test_id');
      expect(event, isA<PharmacyHomeEvent>());
    });

    test('PharmacyHomeRefreshed is const', () {
      const event = PharmacyHomeRefreshed('test_id');
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
  });
}
