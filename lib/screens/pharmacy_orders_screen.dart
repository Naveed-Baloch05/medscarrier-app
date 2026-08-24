import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pharmacy_orders/pharmacy_orders_bloc.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_event.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_state.dart';

import '../widgets/pharmacy_order_card.dart';
import '../widgets/pharmacy_order_filter.dart';
import '../widgets/pharmacy_order_status_badge.dart';

class PharmacyOrdersScreen extends StatelessWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PharmacyOrdersView();
  }
}

class _PharmacyOrdersView extends StatefulWidget {
  const _PharmacyOrdersView();

  @override
  State<_PharmacyOrdersView> createState() => _PharmacyOrdersViewState();
}

class _PharmacyOrdersViewState extends State<_PharmacyOrdersView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Orders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<PharmacyOrdersBloc>().add(const PharmacyOrdersRefreshed());
            },
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrderForm(context),
        backgroundColor: const Color(0xFF0F7253),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // SEARCH
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {});
                    context.read<PharmacyOrdersBloc>().add(PharmacyOrdersSearched(value));
                  },
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              context.read<PharmacyOrdersBloc>().add(const PharmacyOrdersSearched(''));
                            },
                            icon: Icon(Icons.close_rounded, size: 19, color: cs.onSurfaceVariant),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // FILTER
              BlocBuilder<PharmacyOrdersBloc, PharmacyOrdersState>(
                buildWhen: (prev, cur) => cur is PharmacyOrdersLoaded,
                builder: (context, state) {
                  if (state is! PharmacyOrdersLoaded) return const SizedBox.shrink();
                  return PharmacyOrderFilter(
                    selectedStatus: state.selectedStatus,
                    onStatusSelected: (status) {
                      context.read<PharmacyOrdersBloc>().add(PharmacyOrdersFiltered(status));
                    },
                  );
                },
              ),
              const SizedBox(height: 18),

              // LIST
              Expanded(
                child: BlocBuilder<PharmacyOrdersBloc, PharmacyOrdersState>(
                  builder: (context, state) {
                    if (state is PharmacyOrdersLoading || state is PharmacyOrdersInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is PharmacyOrdersError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 45, color: cs.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: cs.onSurface),
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () {
                                context.read<PharmacyOrdersBloc>().add(const LoadPharmacyOrders());
                              },
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is PharmacyOrdersLoaded) {
                      if (state.orders.isEmpty) return _buildEmptyState(context);

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<PharmacyOrdersBloc>().add(const PharmacyOrdersRefreshed());
                          await Future.delayed(const Duration(milliseconds: 400));
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: state.orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = state.orders[index];
                            return PharmacyOrderCard(
                              order: order,
                              onTap: () => _showOrderDetails(context, order),
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // ADD / EDIT ORDER BOTTOM SHEET
  // ==============================================================

  void _showOrderForm(BuildContext context, {PharmacyOrder? existing}) {
    final isEditing = existing != null;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nameCtrl = TextEditingController(text: isEditing ? existing.customerName : '');
    final qtyCtrl = TextEditingController(text: isEditing ? '${existing.medicineCount}' : '');
    final totalCtrl = TextEditingController(text: isEditing ? existing.totalAmount.toStringAsFixed(2) : '');

    String status = isEditing ? existing.status : 'New';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isEditing ? 'Edit Order' : 'New Order',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface),
                        ),
                        const SizedBox(height: 20),
                        _formField(
                          controller: nameCtrl,
                          hint: 'Customer name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter a customer name';
                            return null;
                          },
                          context: context,
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          controller: qtyCtrl,
                          hint: 'Number of medicines',
                          icon: Icons.medication_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter medicine count';
                            if (int.tryParse(v.trim()) == null || int.parse(v.trim()) < 1) return 'Enter a valid number';
                            return null;
                          },
                          context: context,
                        ),
                        const SizedBox(height: 14),
                        _formField(
                          controller: totalCtrl,
                          hint: 'Total amount (£)',
                          icon: Icons.account_balance_wallet_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter total amount';
                            if (double.tryParse(v.trim()) == null) return 'Enter a valid amount';
                            return null;
                          },
                          context: context,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.flag_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'New', child: Text('New')),
                            DropdownMenuItem(value: 'Preparing', child: Text('Preparing')),
                            DropdownMenuItem(value: 'Ready', child: Text('Ready')),
                            DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                          ],
                          onChanged: (v) {
                            if (v != null) setSheetState(() => status = v);
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              if (isEditing) {
                                context.read<PharmacyOrdersBloc>().add(PharmacyOrderUpdated(
                                      id: existing.id,
                                      customerName: nameCtrl.text.trim(),
                                      medicineCount: int.parse(qtyCtrl.text.trim()),
                                      status: status,
                                      totalAmount: double.parse(totalCtrl.text.trim()),
                                    ));
                              } else {
                                context.read<PharmacyOrdersBloc>().add(PharmacyOrderAdded(
                                      customerName: nameCtrl.text.trim(),
                                      medicineCount: int.parse(qtyCtrl.text.trim()),
                                      status: status,
                                      totalAmount: double.parse(totalCtrl.text.trim()),
                                    ));
                              }
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(isEditing ? 'Order updated.' : 'Order added.'),
                                backgroundColor: const Color(0xFF0F7253),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F7253),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text(
                              isEditing ? 'Update Order' : 'Add Order',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==============================================================
  // ORDER DETAILS
  // ==============================================================

  void _showOrderDetails(BuildContext context, PharmacyOrder order) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextStatus = _nextStatus(order.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order Details',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface),
                            ),
                          ),
                          PharmacyOrderStatusBadge(status: order.status),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _detailRow('Order ID', order.id, context),
                      _detailRow('Customer', order.customerName, context),
                      _detailRow('Time', order.time, context),
                      _detailRow('Medicines', '${order.medicineCount}', context),
                      _detailRow('Total', '£${order.totalAmount.toStringAsFixed(2)}', context),

                      if (order.items.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Items',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(color: const Color(0xFF0F7253), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Text(item, style: TextStyle(fontSize: 13, color: cs.onSurface)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (order.riderName.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A2744) : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.delivery_dining_rounded, size: 20, color: Colors.blue.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(order.riderName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
                                    Text(order.riderPhone, style: TextStyle(fontSize: 11, color: Colors.blue.shade500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      if (nextStatus != null) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (nextStatus == 'Ready') {
                                _showRiderAssignment(ctx, order, setSheetState);
                              } else {
                                context.read<PharmacyOrdersBloc>().add(PharmacyOrderStatusChanged(
                                      id: order.id,
                                      newStatus: nextStatus,
                                    ));
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Order marked as $nextStatus.'),
                                  backgroundColor: const Color(0xFF0F7253),
                                ));
                              }
                            },
                            icon: Icon(_statusActionIcon(nextStatus), size: 20),
                            label: Text(_statusActionLabel(nextStatus), style: const TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F7253),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showOrderForm(context, existing: order);
                                },
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: cs.onSurface,
                                  side: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context.read<PharmacyOrdersBloc>().add(PharmacyOrderDeleted(order.id));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Order deleted.'),
                                    backgroundColor: Colors.red,
                                  ));
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _nextStatus(String current) {
    switch (current) {
      case 'New':
        return 'Preparing';
      case 'Preparing':
        return 'Ready';
      case 'Ready':
        return 'Delivered';
      default:
        return null;
    }
  }

  String _statusActionLabel(String status) {
    switch (status) {
      case 'Preparing':
        return 'Start Preparing';
      case 'Ready':
        return 'Mark Ready for Pickup';
      case 'Delivered':
        return 'Hand to Rider';
      default:
        return '';
    }
  }

  IconData _statusActionIcon(String status) {
    switch (status) {
      case 'Preparing':
        return Icons.inventory_rounded;
      case 'Ready':
        return Icons.check_circle_outline;
      case 'Delivered':
        return Icons.delivery_dining_rounded;
      default:
        return Icons.arrow_forward;
    }
  }

  // ==============================================================
  // RIDER ASSIGNMENT
  // ==============================================================

  void _showRiderAssignment(BuildContext ctx, PharmacyOrder order, StateSetter setSheetState) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riders = [
      {'name': 'Ahmed Khan', 'phone': '07987654321'},
      {'name': 'David Lee', 'phone': '07456123789'},
    ];
    int selectedRider = 0;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (riderCtx) {
        return StatefulBuilder(
          builder: (riderCtx, setRiderState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assign Rider', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const SizedBox(height: 6),
                    Text(
                      'Select a rider to deliver order ${order.id}',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(riders.length, (i) {
                      final r = riders[i];
                      final isSelected = i == selectedRider;
                      return GestureDetector(
                        onTap: () => setRiderState(() => selectedRider = i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF1D322A) : Colors.green.shade50)
                                : (isDark ? const Color(0xFF131D19) : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0F7253) : (isDark ? const Color(0xFF2A3A33) : Colors.grey.shade200),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF2A3A33) : Colors.green.shade100)
                                      : (isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delivery_dining_rounded,
                                  size: 22,
                                  color: isSelected ? const Color(0xFF0F7253) : cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['name']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    Text(
                                      r['phone']!,
                                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected) Icon(Icons.check_circle, color: const Color(0xFF0F7253)),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final rider = riders[selectedRider];
                          Navigator.pop(riderCtx);
                          context.read<PharmacyOrdersBloc>().add(PharmacyOrderStatusChanged(
                                id: order.id,
                                newStatus: 'Ready',
                                riderName: rider['name']!,
                                riderPhone: rider['phone']!,
                              ));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Order marked as Ready. Assigned to ${rider['name']}.'),
                            backgroundColor: const Color(0xFF0F7253),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F7253),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Assign & Mark Ready', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==============================================================
  // FORM FIELD HELPER
  // ==============================================================

  Widget _formField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required BuildContext context,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        prefixIcon: Icon(icon, color: cs.onSurfaceVariant, size: 20),
        errorStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: const Color(0xFF0F7253)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ==============================================================
  // DETAIL ROW
  // ==============================================================

  Widget _detailRow(String title, String value, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }

  // ==============================================================
  // EMPTY STATE
  // ==============================================================

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 38, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          Text('No orders found', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 7),
          Text(
            'There are no orders matching your search.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
