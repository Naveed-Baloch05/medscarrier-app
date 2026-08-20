import '../../models/pharmacy_model.dart';

abstract class PharmacyLoginState {
  const PharmacyLoginState();
}

class PharmacyLoginInitial extends PharmacyLoginState {
  const PharmacyLoginInitial();
}

class PharmacyLoginLoading extends PharmacyLoginState {
  const PharmacyLoginLoading();
}

class PharmacyLoginSuccess extends PharmacyLoginState {
  const PharmacyLoginSuccess(this.pharmacy);

  final PharmacyModel pharmacy;
}

class PharmacyLoginFailure extends PharmacyLoginState {
  const PharmacyLoginFailure(this.message);

  final String message;
}
