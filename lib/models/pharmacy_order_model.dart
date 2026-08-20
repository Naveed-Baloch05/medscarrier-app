class PharmacyOrderModel {
  final String orderId;
  final String customerName;
  final String orderTime;
  final int medicineCount;
  final String status;
  final bool controlledDrug;
  final bool coldChain;

  const PharmacyOrderModel({
    required this.orderId,
    required this.customerName,
    required this.orderTime,
    required this.medicineCount,
    required this.status,
    this.controlledDrug = false,
    this.coldChain = false,
  });
}