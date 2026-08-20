class PharmacyOrder {
  const PharmacyOrder({
    required this.id,
    required this.customerName,
    required this.medicineCount,
    required this.time,
    required this.status,
    required this.totalAmount,
  });

  final String id;
  final String customerName;
  final int medicineCount;
  final String time;
  final String status;
  final double totalAmount;

  PharmacyOrder copyWith({
    String? id,
    String? customerName,
    int? medicineCount,
    String? time,
    String? status,
    double? totalAmount,
  }) {
    return PharmacyOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      medicineCount: medicineCount ?? this.medicineCount,
      time: time ?? this.time,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
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
