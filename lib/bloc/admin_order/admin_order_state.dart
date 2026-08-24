abstract class AdminOrderState {
  const AdminOrderState();
}

class AdminOrderInitial extends AdminOrderState {
  const AdminOrderInitial();
}

class AdminOrderLoading extends AdminOrderState {
  const AdminOrderLoading();
}

class AdminOrderLoaded extends AdminOrderState {
  const AdminOrderLoaded(this.orders, {this.activeFilter});
  final List<Map<String, dynamic>> orders;
  final String? activeFilter;
}

class AdminOrderOperationSuccess extends AdminOrderState {
  const AdminOrderOperationSuccess(this.message);
  final String message;
}

class AdminOrderError extends AdminOrderState {
  const AdminOrderError(this.message);
  final String message;
}
