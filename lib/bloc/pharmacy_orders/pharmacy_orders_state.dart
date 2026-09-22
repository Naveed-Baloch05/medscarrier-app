class PharmacyOrder {
  const PharmacyOrder({
    required this.id,
    this.rawId = '',
    required this.customerName,
    this.customerPhone = '',
    this.deliveryAddress = '',
    required this.medicineCount,
    required this.time,
    required this.status,
    required this.totalAmount,
    this.items = const [],
    this.riderId = '',
    this.riderName = '',
    this.riderPhone = '',
    this.dropoffLat,
    this.dropoffLng,
    this.failureReason,
    this.failureNote,
    this.assignedAt,
    this.deliveredAt,
    this.failedAt,
    this.controlledDrug = false,
    this.coldChain = false,
  });

  final String id;
  final String rawId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final int medicineCount;
  final String time;
  final String status;
  final double totalAmount;
  final List<String> items;
  final String riderId;
  final String riderName;
  final String riderPhone;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? failureReason;
  final String? failureNote;
  final DateTime? assignedAt;
  final DateTime? deliveredAt;
  final DateTime? failedAt;
  final bool controlledDrug;
  final bool coldChain;

  String get docId => rawId.isNotEmpty
      ? rawId
      : (id.startsWith('#ORD-') ? id.substring(5) : (id.startsWith('#') ? id.substring(1) : id));

  bool get isAssigned =>
      riderId.isNotEmpty || riderName.isNotEmpty || status.toLowerCase() == 'assigned';

  bool get isInTransit =>
      status.toLowerCase() == 'on the way' ||
      status.toLowerCase() == 'picked up' ||
      status.toLowerCase() == 'arrived' ||
      status.toLowerCase() == 'out for delivery';

  bool get isDelivered =>
      status.toLowerCase() == 'delivered' || status.toLowerCase() == 'completed';

  bool get isFailed =>
      status.toLowerCase() == 'failed' || status.toLowerCase() == 'delivery failed';

  bool get canTrackLive =>
      (riderId.isNotEmpty || riderName.isNotEmpty) && !isDelivered && !isFailed;

  PharmacyOrder copyWith({
    String? id,
    String? rawId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    int? medicineCount,
    String? time,
    String? status,
    double? totalAmount,
    List<String>? items,
    String? riderId,
    String? riderName,
    String? riderPhone,
    double? dropoffLat,
    double? dropoffLng,
    String? failureReason,
    String? failureNote,
    DateTime? assignedAt,
    DateTime? deliveredAt,
    DateTime? failedAt,
    bool? controlledDrug,
    bool? coldChain,
  }) {
    return PharmacyOrder(
      id: id ?? this.id,
      rawId: rawId ?? this.rawId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      medicineCount: medicineCount ?? this.medicineCount,
      time: time ?? this.time,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      failureReason: failureReason ?? this.failureReason,
      failureNote: failureNote ?? this.failureNote,
      assignedAt: assignedAt ?? this.assignedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      failedAt: failedAt ?? this.failedAt,
      controlledDrug: controlledDrug ?? this.controlledDrug,
      coldChain: coldChain ?? this.coldChain,
    );
  }
}

abstract class PharmacyOrdersState {
  const PharmacyOrdersState();
}

class PharmacyOrdersInitial extends PharmacyOrdersState {
  const PharmacyOrdersInitial();
}

class PharmacyOrdersLoading extends PharmacyOrdersState {
  const PharmacyOrdersLoading();
}

class PharmacyOrdersLoaded extends PharmacyOrdersState {
  const PharmacyOrdersLoaded({
    required this.orders,
    required this.allOrders,
    required this.selectedStatus,
  });

  final List<PharmacyOrder> orders;
  final List<PharmacyOrder> allOrders;
  final String selectedStatus;
}

class PharmacyOrdersError extends PharmacyOrdersState {
  const PharmacyOrdersError(this.message);

  final String message;
}
