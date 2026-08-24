import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/admin_support_service.dart';
import '../../models/support_ticket_model.dart';
import 'admin_support_event.dart';
import 'admin_support_state.dart';

class AdminSupportBloc extends Bloc<AdminSupportEvent, AdminSupportState> {
  AdminSupportBloc({
    AdminSupportService? service,
  })  : _service = service ?? AdminSupportService.instance,
        super(const AdminSupportInitial()) {
    on<AdminSupportLoadTickets>(_onLoadTickets);
    on<AdminSupportSendMessage>(_onSendMessage);
    on<AdminSupportMarkRead>(_onMarkRead);
    on<AdminSupportCloseTicket>(_onCloseTicket);
    on<AdminSupportReopenTicket>(_onReopenTicket);
  }

  final AdminSupportService _service;
  StreamSubscription<List<SupportTicketModel>>? _ticketsSub;

  void _onLoadTickets(
    AdminSupportLoadTickets event,
    Emitter<AdminSupportState> emit,
  ) {
    _ticketsSub?.cancel();
    _ticketsSub = _service.streamTickets().listen((tickets) {
      if (!isClosed) {
        emit(AdminSupportTicketsLoaded(tickets: tickets));
      }
    });
  }

  void _onSendMessage(
    AdminSupportSendMessage event,
    Emitter<AdminSupportState> emit,
  ) async {
    await _service.sendAdminMessage(
      ticketId: event.ticketId,
      message: event.message,
    );
  }

  void _onMarkRead(
    AdminSupportMarkRead event,
    Emitter<AdminSupportState> emit,
  ) async {
    await _service.markMessagesAsRead(event.ticketId);
  }

  void _onCloseTicket(
    AdminSupportCloseTicket event,
    Emitter<AdminSupportState> emit,
  ) async {
    await _service.closeTicket(event.ticketId);
  }

  void _onReopenTicket(
    AdminSupportReopenTicket event,
    Emitter<AdminSupportState> emit,
  ) async {
    await _service.reopenTicket(event.ticketId);
  }

  Stream<List<SupportMessageModel>> streamMessages(String ticketId) {
    return _service.streamMessages(ticketId);
  }

  @override
  Future<void> close() {
    _ticketsSub?.cancel();
    return super.close();
  }
}
