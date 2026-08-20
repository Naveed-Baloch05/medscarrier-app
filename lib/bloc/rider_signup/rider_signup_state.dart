import '../../models/rider_model.dart';

abstract class RiderSignupState {
  const RiderSignupState();
}

class RiderSignupInitial extends RiderSignupState {
  const RiderSignupInitial();
}

class RiderSignupLoading extends RiderSignupState {
  const RiderSignupLoading();
}

class RiderSignupSuccess extends RiderSignupState {
  const RiderSignupSuccess(this.rider);

  final RiderModel rider;
}

class RiderSignupFailure extends RiderSignupState {
  const RiderSignupFailure(this.message);

  final String message;
}
