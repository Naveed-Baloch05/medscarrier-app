import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pharmacy_orders/pharmacy_orders_bloc.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_event.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_state.dart';

import '../widgets/pharmacy_order_card.dart';
import '../widgets/pharmacy_order_filter.dart';

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
  State<_PharmacyOrdersView> createState() =>
      _PharmacyOrdersViewState();
}

class _PharmacyOrdersViewState extends State<_PharmacyOrdersView> {
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Orders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context
                  .read<PharmacyOrdersBloc>()
                  .add(const PharmacyOrdersRefreshed());
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrderForm(context),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {});
                    context
                        .read<PharmacyOrdersBloc>()
                        .add(PharmacyOrdersSearched(value));
                  },
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.grey.shade600),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                  context
                                      .read<PharmacyOrdersBloc>()
                                      .add(
                                          const PharmacyOrdersSearched(''));
                                },
                                icon: const Icon(
                                    Icons.close_rounded, size: 19),
                              )
                            : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // FILTER
              BlocBuilder<PharmacyOrdersBloc, PharmacyOrdersState>(
                buildWhen: (prev, cur) => cur is PharmacyOrdersLoaded,
                builder: (context, state) {
                  if (state is! PharmacyOrdersLoaded) {
                    return const SizedBox.shrink();
                  }
                  return PharmacyOrderFilter(
                    selectedStatus: state.selectedStatus,
                    onStatusSelected: (status) {
                      context
                          .read<PharmacyOrdersBloc>()
                          .add(PharmacyOrdersFiltered(status));
                    },
                  );
                },
              ),

              const SizedBox(height: 18),

              // LIST
              Expanded(
                child:
                    BlocBuilder<PharmacyOrdersBloc, PharmacyOrdersState>(
                  builder: (context, state) {
                    if (state is PharmacyOrdersLoading) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (state is PharmacyOrdersError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 45,
                                color: Colors.grey.shade500),
                            const SizedBox(height: 12),
                            Text(state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () {
                                context.read<PharmacyOrdersBloc>().add(
                                    const LoadPharmacyOrders());
                              },
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is PharmacyOrdersInitial) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (state is PharmacyOrdersLoaded) {
                      if (state.orders.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context
                              .read<PharmacyOrdersBloc>()
                              .add(const PharmacyOrdersRefreshed());
                          await Future.delayed(
                              const Duration(milliseconds: 400));
                        },
                        child: ListView.separated(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.only(bottom: 80),
                          itemCount: state.orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = state.orders[index];
                            return PharmacyOrderCard(
                              order: order,
                              onTap: () => _showOrderDetails(
                                  context, order),
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

  void _showOrderForm(BuildContext context,
      {PharmacyOrder? existing}) {
    final isEditing = existing != null;

    final nameCtrl = TextEditingController(
        text: isEditing ? existing.customerName : '');
    final qtyCtrl = TextEditingController(
        text: isEditing ? '${existing.medicineCount}' : '');
    final totalCtrl = TextEditingController(
        text: isEditing ? existing.totalAmount.toStringAsFixed(2) : '');

    String status = isEditing ? existing.status : 'New';

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    MediaQuery.of(ctx).viewInsets.bottom + 24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isEditing
                              ? 'Edit Order'
                              : 'New Order',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // CUSTOMER NAME
                        _formField(
                          controller: nameCtrl,
                          hint: 'Customer name',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null ||
                                v.trim().isEmpty) {
                              return 'Please enter a customer name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // MEDICINE COUNT
                        _formField(
                          controller: qtyCtrl,
                          hint: 'Number of medicines',
                          icon: Icons.medication_outlined,
                          keyboardType:
                              TextInputType.number,
                          validator: (v) {
                            if (v == null ||
                                v.trim().isEmpty) {
                              return 'Please enter medicine count';
                            }
                            if (int.tryParse(v.trim()) ==
                                    null ||
                                int.parse(v.trim()) <
                                    1) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // TOTAL
                        _formField(
                          controller: totalCtrl,
                          hint: 'Total amount (£)',
                          icon:
                              Icons.account_balance_wallet_outlined,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          validator: (v) {
                            if (v == null ||
                                v.trim().isEmpty) {
                              return 'Please enter total amount';
                            }
                            if (double.tryParse(
                                    v.trim()) ==
                                null) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // STATUS DROPDOWN
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                                Icons.flag_outlined),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color:
                                      Colors.grey.shade300),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color:
                                      Colors.grey.shade300),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'New',
                                child: Text('New')),
                            DropdownMenuItem(
                                value: 'Preparing',
                                child:
                                    Text('Preparing')),
                            DropdownMenuItem(
                                value: 'Ready',
                                child: Text('Ready')),
                            DropdownMenuItem(
                                value: 'Delivered',
                                child:
                                    Text('Delivered')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setSheetState(
                                  () => status = v);
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // SUBMIT
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!
                                  .validate()) {
                                return;
                              }

                              if (isEditing) {
                                context
                                    .read<
                                        PharmacyOrdersBloc>()
                                    .add(
                                      PharmacyOrderUpdated(
                                        id: existing.id,
                                        customerName:
                                            nameCtrl.text
                                                .trim(),
                                        medicineCount:
                                            int.parse(
                                                qtyCtrl
                                                    .text
                                                    .trim()),
                                        status: status,
                                        totalAmount:
                                            double.parse(
                                                totalCtrl
                                                    .text
                                                    .trim()),
                                      ),
                                    );
                              } else {
                                context
                                    .read<
                                        PharmacyOrdersBloc>()
                                    .add(
                                      PharmacyOrderAdded(
                                        customerName:
                                            nameCtrl.text
                                                .trim(),
                                        medicineCount:
                                            int.parse(
                                                qtyCtrl
                                                    .text
                                                    .trim()),
                                        status: status,
                                        totalAmount:
                                            double.parse(
                                                totalCtrl
                                                    .text
                                                    .trim()),
                                      ),
                                    );
                              }

                              Navigator.pop(ctx);

                              ScaffoldMessenger.of(
                                      context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(isEditing
                                      ? 'Order updated.'
                                      : 'Order added.'),
                                  backgroundColor:
                                      Colors.teal,
                                ),
                              );
                            },
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.black,
                              foregroundColor:
                                  Colors.white,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        15),
                              ),
                            ),
                            child: Text(
                              isEditing
                                  ? 'Update Order'
                                  : 'Add Order',
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w700),
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

  void _showOrderDetails(
      BuildContext context, PharmacyOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _detailRow('Order ID', order.id),
                _detailRow('Customer', order.customerName),
                _detailRow('Medicines',
                    '${order.medicineCount}'),
                _detailRow('Time', order.time),
                _detailRow('Status', order.status),
                _detailRow('Total',
                    '£${order.totalAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showOrderForm(context,
                                existing: order);
                          },
                          icon: const Icon(
                              Icons.edit_outlined,
                              size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(
                                color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
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
                            Navigator.pop(context);
                            context
                                .read<PharmacyOrdersBloc>()
                                .add(PharmacyOrderDeleted(
                                    order.id));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Order deleted.'),
                                backgroundColor:
                                    Colors.red,
                              ),
                            );
                          },
                          icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18),
                          label: const Text('Delete'),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        errorStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ==============================================================
  // DETAIL ROW
  // ==============================================================

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ==============================================================
  // EMPTY STATE
  // ==============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 38, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 18),
          const Text('No orders found',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(
            'There are no orders matching your search.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
