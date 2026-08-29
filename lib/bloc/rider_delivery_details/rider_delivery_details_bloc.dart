import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/rider_delivery_details_service.dart';
import '../../models/order_model.dart';
import 'rider_delivery_details_event.dart';
import 'rider_delivery_details_state.dart';

class RiderDeliveryDetailsBloc
    extends Bloc<RiderDeliveryDetailsEvent, RiderDeliveryDetailsState> {
  RiderDeliveryDetailsBloc({RiderDeliveryDetailsService? service})
      : _service = service ?? RiderDeliveryDetailsService.instance,
        super(const RiderDeliveryDetailsInitial()) {
    on<SubscribeToOrder>(_onSubscribe);
    on<LoadOrder>(_onLoad);
    on<VerifyPickupQR>(_onVerifyPickupQR);
    on<StartDelivery>(_onStartDelivery);
    on<CompleteDelivery>(_onCompleteDelivery);
  }

  final RiderDeliveryDetailsService _service;

  StreamSubscription<RiderOrderUpdate?>? _orderSubscription;
  String? _pickupQrValue;
  OrderModel? _latestOrder;

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    return super.close();
  }

  OrderModel _currentOrder() {
    if (_latestOrder != null) return _latestOrder!;
    final s = state;
    if (s is RiderDeliveryDetailsLoaded) return s.order;
    if (s is RiderDeliveryDetailsUpdating) return s.order;
    if (s is RiderDeliveryDetailsOperationSuccess) return s.order;
    if (s is RiderDeliveryDetailsError && s.order != null) return s.order!;
    throw StateError('Order not loaded yet.');
  }

  void _applyOrder(
    Emitter<RiderDeliveryDetailsState> emit, {
    OrderModel? order,
    String? pickupQrValue,
    bool notify = false,
    String message = '',
  }) {
    final resolvedOrder = order ?? _latestOrder;
    if (resolvedOrder == null) return;
    _latestOrder = resolvedOrder;
    if (pickupQrValue != null) _pickupQrValue = pickupQrValue;

    if (notify) {
      emit(RiderDeliveryDetailsOperationSuccess(
        message: message,
        order: resolvedOrder,
        pickupQrValue: _pickupQrValue,
      ));
    } else {
      emit(RiderDeliveryDetailsLoaded(
        order: resolvedOrder,
        pickupQrValue: _pickupQrValue,
      ));
    }
  }

  Future<void> _onSubscribe(
    SubscribeToOrder event,
    Emitter<RiderDeliveryDetailsState> emit,
  ) async {
    emit(RiderDeliveryDetailsLoading());
    await _orderSubscription?.cancel();

    // Fallback so the details screen never hangs on loading if the real-time
    // stream does not deliver its initial emission.
    Timer? fallback;
    bool gotEmission = false;

    _orderSubscription = _service.orderStream(event.orderId).listen((update) {
      if (!isClosed && update != null) {
        gotEmission = true;
        fallback?.cancel();
        _applyOrder(emit, order: update.order, pickupQrValue: update.pickupQrValue);
      }
    }, onError: (Object error) {
      if (!isClosed) {
        gotEmission = true;
        fallback?.cancel();
        emit(RiderDeliveryDetailsError(
          message: 'Unable to load order updates.',
          order: _latestOrder,
          pickupQrValue: _pickupQrValue,
        ));
      }
    });

    fallback = Timer(const Duration(seconds: 4), () async {
      if (isClosed || gotEmission) return;
      try {
        final order = await _service.getOrder(event.orderId);
        if (isClosed) return;
        if (order == null) {
          emit(RiderDeliveryDetailsError(message: 'Order not found.'));
          return;
        }
        _applyOrder(emit, order: order);
      } catch (error) {
        if (isClosed) return;
        emit(RiderDeliveryDetailsError(
          message: error.toString().replaceFirst('Exception: ', ''),
          order: _latestOrder,
          pickupQrValue: _pickupQrValue,
        ));
      }
    });
  }

  Future<void> _onLoad(
    LoadOrder event,
    Emitter<RiderDeliveryDetailsState> emit,
  ) async {
    try {
      final order = await _service.getOrder(event.orderId);
      if (order == null) {
        emit(const RiderDeliveryDetailsError(message: 'Order not found.'));
        return;
      }
      _applyOrder(emit, order: order);
    } catch (error) {
      emit(RiderDeliveryDetailsError(
        message: error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onVerifyPickupQR(
    VerifyPickupQR event,
    Emitter<RiderDeliveryDetailsState> emit,
  ) async {
    final current = _currentOrder();
    emit(RiderDeliveryDetailsUpdating(
      order: current,
      pickupQrValue: _pickupQrValue,
    ));

    try {
      await _service.verifyPickupQR(
        orderId: event.orderId,
        qrValue: event.qrValue,
      );
      _pickupQrValue = event.qrValue.trim();
    } catch (error) {
      emit(RiderDeliveryDetailsError(
        message: error.toString().replaceFirst('Exception: ', ''),
        order: current,
        pickupQrValue: _pickupQrValue,
      ));
    }
  }

  Future<void> _onStartDelivery(
    StartDelivery event,
    Emitter<RiderDeliveryDetailsState> emit,
  ) async {
    final current = _currentOrder();
    emit(RiderDeliveryDetailsUpdating(
      order: current,
      pickupQrValue: _pickupQrValue,
    ));

    try {
      await _service.startDelivery(event.orderId);
    } catch (error) {
      emit(RiderDeliveryDetailsError(
        message: error.toString().replaceFirst('Exception: ', ''),
        order: current,
        pickupQrValue: _pickupQrValue,
      ));
    }
  }

  Future<void> _onCompleteDelivery(
    CompleteDelivery event,
    Emitter<RiderDeliveryDetailsState> emit,
  ) async {
    final current = _currentOrder();
    emit(RiderDeliveryDetailsUpdating(
      order: current,
      pickupQrValue: _pickupQrValue,
    ));

    try {
      await _service.completeDelivery(
        orderId: event.orderId,
        recipientName: event.recipientName,
        signaturePoints: event.signaturePoints,
        medicineHandoverConfirmed: event.medicineHandoverConfirmed,
      );
    } catch (error) {
      emit(RiderDeliveryDetailsError(
        message: error.toString().replaceFirst('Exception: ', ''),
        order: current,
        pickupQrValue: _pickupQrValue,
      ));
    }
  }
}
