abstract class AdminProfileEvent {
  const AdminProfileEvent();
}

class AdminProfileLoadRequested extends AdminProfileEvent {
  const AdminProfileLoadRequested();
}

class AdminProfileUpdateRequested extends AdminProfileEvent {
  const AdminProfileUpdateRequested({
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;
}

class AdminProfileCleared extends AdminProfileEvent {
  const AdminProfileCleared();
}
