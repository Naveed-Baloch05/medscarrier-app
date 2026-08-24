sealed class AdminSupportEvent {
  const AdminSupportEvent();
}

final class AdminSupportLoadTickets extends AdminSupportEvent {
  const AdminSupportLoadTickets();
}

final class AdminSupportSendMessage extends AdminSupportEvent {
  const AdminSupportSendMessage({
    required this.ticketId,
    required this.message,
  });
  final String ticketId;
  final String message;
}

final class AdminSupportMarkRead extends AdminSupportEvent {
  const AdminSupportMarkRead(this.ticketId);
  final String ticketId;
}

final class AdminSupportCloseTicket extends AdminSupportEvent {
  const AdminSupportCloseTicket(this.ticketId);
  final String ticketId;
}

final class AdminSupportReopenTicket extends AdminSupportEvent {
  const AdminSupportReopenTicket(this.ticketId);
  final String ticketId;
}
