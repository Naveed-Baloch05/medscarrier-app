import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/pharmacy_notification_service.dart';
import '../../models/pharmacy_notification_model.dart';
import 'pharmacy_notifications_event.dart';
import 'pharmacy_notifications_state.dart';

class PharmacyNotificationsBloc
    extends Bloc<PharmacyNotificationsEvent, PharmacyNotificationsState> {
  PharmacyNotificationsBloc({PharmacyNotificationService? service})
      : _service = service ?? PharmacyNotificationService.instance,
        super(const PharmacyNotificationsInitial()) {
    on<LoadPharmacyNotifications>(_onLoad);
    on<PharmacyNotificationMarkedRead>(_onMarkRead);
    on<PharmacyNotificationsMarkAllRead>(_onMarkAllRead);
  }

  final PharmacyNotificationService _service;
  String _uid = '';
  StreamSubscription<List<PharmacyNotificationModel>>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    LoadPharmacyNotifications event,
    Emitter<PharmacyNotificationsState> emit,
  ) async {
    _uid = event.uid;
    await _sub?.cancel();

    if (state is! PharmacyNotificationsLoaded) {
      emit(const PharmacyNotificationsLoading());
    }

    _sub = _service.streamNotifications(_uid).listen(
      (notifications) async {
        final unreadCount = await _service.getUnreadCount(_uid);
        if (!isClosed) {
          emit(PharmacyNotificationsLoaded(
            notifications: notifications,
            unreadCount: unreadCount,
          ));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(PharmacyNotificationsError(
            error.toString().replaceFirst('Exception: ', ''),
          ));
        }
      },
    );
  }

  Future<void> _onMarkRead(
    PharmacyNotificationMarkedRead event,
    Emitter<PharmacyNotificationsState> emit,
  ) async {
    await _service.markAsRead(_uid, event.notificationId);
  }

  Future<void> _onMarkAllRead(
    PharmacyNotificationsMarkAllRead event,
    Emitter<PharmacyNotificationsState> emit,
  ) async {
    await _service.markAllAsRead(_uid);
  }
}
