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
      items: ['Ibuprofen 200mg', 'Paracetamol 500mg', 'Cetirizine 10mg'],
    ),
    const PharmacyOrder(
      id: '#ORD-2049',
      customerName: 'Sarah Wilson',
      medicineCount: 2,
      time: '10:18 AM',
      status: 'Preparing',
      totalAmount: 31.50,
      items: ['Amoxicillin 500mg', 'Omeprazole 20mg'],
    ),
    const PharmacyOrder(
      id: '#ORD-2050',
      customerName: 'Michael Brown',
      medicineCount: 5,
      time: '09:55 AM',
      status: 'Ready',
      totalAmount: 45.00,
      items: ['Metformin 850mg', 'Amlodipine 5mg', 'Atorvastatin 20mg', 'Omeprazole 20mg', 'Salbutamol Inhaler'],
      riderName: 'Ahmed Khan',
      riderPhone: '07987654321',
    ),
    const PharmacyOrder(
      id: '#ORD-2051',
      customerName: 'Emily Davis',
      medicineCount: 2,
      time: '09:30 AM',
      status: 'Delivered',
      totalAmount: 18.75,
      items: ['Loratadine 10mg', 'Fexofenadine 120mg'],
      riderName: 'David Lee',
      riderPhone: '07456123789',
    ),
    const PharmacyOrder(
      id: '#ORD-2052',
      customerName: 'James Johnson',
      medicineCount: 4,
      time: '09:12 AM',
      status: 'New',
      totalAmount: 33.20,
      items: ['Naproxen 500mg', 'Codeine Phosphate 30mg', 'Tramadol 50mg', 'Paracetamol 1g'],
    ),
    const PharmacyOrder(
      id: '#ORD-2053',
      customerName: 'Olivia Taylor',
      medicineCount: 1,
      time: '08:45 AM',
      status: 'Preparing',
      totalAmount: 8.99,
      items: ['Salbutamol Inhaler'],
    ),
    const PharmacyOrder(
      id: '#ORD-2054',
      customerName: 'William Anderson',
      medicineCount: 2,
      time: '08:20 AM',
      status: 'Delivered',
      totalAmount: 22.00,
      items: ['Metformin 850mg', 'Gliclazide 80mg'],
      riderName: 'Ahmed Khan',
      riderPhone: '07987654321',
    ),
    const PharmacyOrder(
      id: '#ORD-2055',
      customerName: 'Priya Patel',
      medicineCount: 3,
      time: '08:05 AM',
      status: 'Ready',
      totalAmount: 28.50,
      items: ['Co-codamol 30/500', 'Ibuprofen 400mg', 'Paracetamol 500mg'],
      riderName: 'David Lee',
      riderPhone: '07456123789',
    ),
    const PharmacyOrder(
      id: '#ORD-2056',
      customerName: 'Emma Watson',
      medicineCount: 1,
      time: 'Yesterday',
      status: 'Delivered',
      totalAmount: 14.99,
      items: ['Fluticasone Nasal Spray'],
      riderName: 'Ahmed Khan',
      riderPhone: '07987654321',
    ),
    const PharmacyOrder(
      id: '#ORD-2057',
      customerName: 'Tom Richards',
      medicineCount: 2,
      time: 'Yesterday',
      status: 'Delivered',
      totalAmount: 19.98,
      items: ['Azithromycin 250mg', 'Lansoprazole 30mg'],
      riderName: 'David Lee',
      riderPhone: '07456123789',
    ),
  ];

  int _nextId = 2058;

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

  Future<void> updateOrderStatus({
    required String id,
    required String newStatus,
    String riderName = '',
    String riderPhone = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _orders.indexWhere((o) => o.id == id);
    if (index == -1) {
      throw Exception('Order not found.');
    }

    _orders[index] = _orders[index].copyWith(
      status: newStatus,
      riderName: riderName,
      riderPhone: riderPhone,
    );
  }
}
