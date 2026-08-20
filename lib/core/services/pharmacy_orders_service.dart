import 'package:flutter/material.dart';

import '../../bloc/pharmacy_orders/pharmacy_orders_state.dart';

class PharmacyOrdersService {
  PharmacyOrdersService._();
  static final PharmacyOrdersService instance =
      PharmacyOrdersService._();

  final List<PharmacyOrder> _orders = [
    const PharmacyOrder(
      id: '#ORD-2048',
      customerName: 'John Smith',
      medicineCount: 3,
      time: '10:24 AM',
      status: 'New',
      totalAmount: 24.99,
    ),
    const PharmacyOrder(
      id: '#ORD-2049',
      customerName: 'Sarah Wilson',
      medicineCount: 1,
      time: '10:18 AM',
      status: 'Preparing',
      totalAmount: 12.50,
    ),
    const PharmacyOrder(
      id: '#ORD-2050',
      customerName: 'Michael Brown',
      medicineCount: 5,
      time: '09:55 AM',
      status: 'Ready',
      totalAmount: 45.00,
    ),
    const PharmacyOrder(
      id: '#ORD-2051',
      customerName: 'Emily Davis',
      medicineCount: 2,
      time: '09:30 AM',
      status: 'Delivered',
      totalAmount: 18.75,
    ),
    const PharmacyOrder(
      id: '#ORD-2052',
      customerName: 'James Johnson',
      medicineCount: 4,
      time: '09:12 AM',
      status: 'New',
      totalAmount: 33.20,
    ),
    const PharmacyOrder(
      id: '#ORD-2053',
      customerName: 'Olivia Taylor',
      medicineCount: 1,
      time: '08:45 AM',
      status: 'Preparing',
      totalAmount: 8.99,
    ),
    const PharmacyOrder(
      id: '#ORD-2054',
      customerName: 'William Anderson',
      medicineCount: 2,
      time: '08:20 AM',
      status: 'Delivered',
      totalAmount: 22.00,
    ),
  ];

  int _nextId = 2055;

  Future<List<PharmacyOrder>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.unmodifiable(_orders);
  }

  Future<PharmacyOrder> addOrder({
    required String customerName,
    required int medicineCount,
    required String status,
    required double totalAmount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final now = TimeOfDay.now();
    final time =
        '${now.hourOfPeriod.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.period == DayPeriod.am ? 'AM' : 'PM'}';

    final order = PharmacyOrder(
      id: '#ORD-${_nextId++}',
      customerName: customerName,
      medicineCount: medicineCount,
      time: time,
      status: status,
      totalAmount: totalAmount,
    );

    _orders.insert(0, order);
    return order;
  }

  Future<void> updateOrder({
    required String id,
    required String customerName,
    required int medicineCount,
    required String status,
    required double totalAmount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _orders.indexWhere((o) => o.id == id);
    if (index == -1) {
      throw Exception('Order not found.');
    }

    _orders[index] = _orders[index].copyWith(
      customerName: customerName,
      medicineCount: medicineCount,
      status: status,
      totalAmount: totalAmount,
    );
  }

  Future<void> deleteOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _orders.removeWhere((o) => o.id == id);
  }
}
