import '../../models/pharmacy_model.dart';

abstract class PharmacySignupState {
  const PharmacySignupState();
}

class PharmacySignupInitial extends PharmacySignupState {
  const PharmacySignupInitial();
}

class PharmacySignupLoading extends PharmacySignupState {
  const PharmacySignupLoading();
}

class PharmacySignupSuccess extends PharmacySignupState {
  const PharmacySignupSuccess(this.pharmacy);

  final PharmacyModel pharmacy;
}

class PharmacySignupFailure extends PharmacySignupState {
  const PharmacySignupFailure(this.message);

  final String message;
}
