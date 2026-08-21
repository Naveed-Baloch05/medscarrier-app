class PharmacyOrder {
  const PharmacyOrder({
    required this.id,
    required this.customerName,
    required this.medicineCount,
    required this.time,
    required this.status,
    required this.totalAmount,
    this.items = const [],
    this.riderName = '',
    this.riderPhone = '',
  });

  final String id;
  final String customerName;
  final int medicineCount;
  final String time;
  final String status;
  final double totalAmount;
  final List<String> items;
  final String riderName;
  final String riderPhone;

  PharmacyOrder copyWith({
    String? id,
    String? customerName,
    int? medicineCount,
    String? time,
    String? status,
    double? totalAmount,
    List<String>? items,
    String? riderName,
    String? riderPhone,
  }) {
    return PharmacyOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      medicineCount: medicineCount ?? this.medicineCount,
      time: time ?? this.time,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
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
