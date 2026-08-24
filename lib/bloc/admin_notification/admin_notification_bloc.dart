import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/admin_notification_service.dart';
import '../../models/admin_notification_model.dart';
import 'admin_notification_event.dart';
import 'admin_notification_state.dart';

class AdminNotificationBloc
    extends Bloc<AdminNotificationEvent, AdminNotificationState> {
  AdminNotificationBloc({
    AdminNotificationService? service,
  })  : _service = service ?? AdminNotificationService.instance,
        super(const AdminNotificationInitial()) {
    on<AdminNotificationLoadRequested>(_onLoadRequested);
    on<AdminNotificationMarkRead>(_onMarkRead);
    on<AdminNotificationMarkAllRead>(_onMarkAllRead);
  }

  final AdminNotificationService _service;
  StreamSubscription<List<AdminNotificationModel>>? _subscription;

  void _onLoadRequested(
    AdminNotificationLoadRequested event,
    Emitter<AdminNotificationState> emit,
  ) {
    _subscription?.cancel();
    _subscription = _service.streamNotifications().listen((notifications) {
      final unreadCount = notifications.where((n) => !n.isRead).length;
      if (!isClosed) {
        emit(AdminNotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      }
    });
  }

  Future<void> _onMarkRead(
    AdminNotificationMarkRead event,
    Emitter<AdminNotificationState> emit,
  ) async {
    await _service.markAsRead(event.notificationId);
  }

  Future<void> _onMarkAllRead(
    AdminNotificationMarkAllRead event,
    Emitter<AdminNotificationState> emit,
  ) async {
    await _service.markAllAsRead();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
