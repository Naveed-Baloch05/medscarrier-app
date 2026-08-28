abstract class PharmacyOrdersEvent {
  const PharmacyOrdersEvent();
}

class LoadPharmacyOrders extends PharmacyOrdersEvent {
  const LoadPharmacyOrders([this.pharmacyId = '']);

  final String pharmacyId;
}

class PharmacyOrdersRefreshed extends PharmacyOrdersEvent {
  const PharmacyOrdersRefreshed();
}

class PharmacyOrdersSearched extends PharmacyOrdersEvent {
  const PharmacyOrdersSearched(this.query);

  final String query;
}

class PharmacyOrdersFiltered extends PharmacyOrdersEvent {
  const PharmacyOrdersFiltered(this.status);

  final String status;
}

class PharmacyOrderAdded extends PharmacyOrdersEvent {
  const PharmacyOrderAdded({
    required this.customerName,
    required this.medicineCount,
    required this.status,
    required this.totalAmount,
  });

  final String customerName;
  final int medicineCount;
  final String status;
  final double totalAmount;
}

class PharmacyOrderUpdated extends PharmacyOrdersEvent {
  const PharmacyOrderUpdated({
    required this.id,
    required this.customerName,
    required this.medicineCount,
    required this.status,
    required this.totalAmount,
  });

  final String id;
  final String customerName;
  final int medicineCount;
  final String status;
  final double totalAmount;
}

class PharmacyOrderDeleted extends PharmacyOrdersEvent {
  const PharmacyOrderDeleted(this.id);

  final String id;
}

class PharmacyOrderStatusChanged extends PharmacyOrdersEvent {
  const PharmacyOrderStatusChanged({
    required this.id,
    required this.newStatus,
    this.riderName = '',
    this.riderPhone = '',
  });

  final String id;
  final String newStatus;
  final String riderName;
  final String riderPhone;
}
