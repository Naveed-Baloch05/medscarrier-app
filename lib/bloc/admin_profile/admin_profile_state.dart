import '../../models/user_model.dart';

abstract class AdminProfileState {
  const AdminProfileState();
}

class AdminProfileInitial extends AdminProfileState {
  const AdminProfileInitial();
}

class AdminProfileLoading extends AdminProfileState {
  const AdminProfileLoading();
}

class AdminProfileLoaded extends AdminProfileState {
  const AdminProfileLoaded(this.admin);
  final UserModel admin;
}

class AdminProfileUpdating extends AdminProfileState {
  const AdminProfileUpdating(this.admin);
  final UserModel admin;
}

class AdminProfileError extends AdminProfileState {
  const AdminProfileError(this.message);
  final String message;
}

class AdminProfileUnauthorized extends AdminProfileState {
  const AdminProfileUnauthorized();
}

class AdminProfileClearedState extends AdminProfileState {
  const AdminProfileClearedState();
}
