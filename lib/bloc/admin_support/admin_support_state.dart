sealed class AdminSupportState {
  const AdminSupportState();
}

final class AdminSupportInitial extends AdminSupportState {
  const AdminSupportInitial();
}

final class AdminSupportTicketsLoaded extends AdminSupportState {
  const AdminSupportTicketsLoaded({required this.tickets});
  final List<dynamic> tickets;
}

final class AdminSupportMessagesLoaded extends AdminSupportState {
  const AdminSupportMessagesLoaded({
    required this.messages,
    required this.ticketId,
  });
  final List<dynamic> messages;
  final String ticketId;
}

final class AdminSupportMessageSending extends AdminSupportState {
  const AdminSupportMessageSending({required this.ticketId});
  final String ticketId;
}

final class AdminSupportError extends AdminSupportState {
  const AdminSupportError(this.message);
  final String message;
}
