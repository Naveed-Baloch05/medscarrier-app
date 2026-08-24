import '../../models/pharmacy_application_model.dart';

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
  const PharmacySignupSuccess(this.application);

  final PharmacyApplicationModel application;
}

class PharmacySignupFailure extends PharmacySignupState {
  const PharmacySignupFailure(this.message);

  final String message;
}
