class MockRiderDeliveriesService {
  MockRiderDeliveriesService._();
  static final instance = MockRiderDeliveriesService._();

  final List<Map<String, dynamic>> completedDeliveries = [];

  void addCompleted({
    required String orderId,
    required String pharmacy,
    required String pharmacyAddress,
    required String customer,
    required String customerAddress,
    required String distance,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '${hour == 0 ? 12 : hour}:${now.minute.toString().padLeft(2, '0')} $period';

    completedDeliveries.insert(0, {
      'orderId': orderId,
      'pharmacy': pharmacy,
      'customer': customer,
      'address': customerAddress,
      'status': 'Completed',
      'distance': distance,
      'eta': 'Completed',
      'controlledDrug': false,
      'coldChain': false,
      'date': dateStr,
      'time': timeStr,
    });
  }
}
