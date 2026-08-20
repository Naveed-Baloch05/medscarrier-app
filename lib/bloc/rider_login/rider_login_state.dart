import '../../models/rider_model.dart';

abstract class RiderLoginState {
  const RiderLoginState();
}

class RiderLoginInitial extends RiderLoginState {
  const RiderLoginInitial();
}

class RiderLoginLoading extends RiderLoginState {
  const RiderLoginLoading();
}

class RiderLoginSuccess extends RiderLoginState {
  const RiderLoginSuccess(this.rider);

  final RiderModel rider;
}

class RiderLoginFailure extends RiderLoginState {
  const RiderLoginFailure(this.message);

  final String message;
}
