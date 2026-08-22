import 'package:flutter/material.dart';

import '../widgets/pharmacy_medicine_card.dart';
import '../widgets/pharmacy_medicine_options.dart';

class PharmacyMedicinesScreen extends StatefulWidget {
  const PharmacyMedicinesScreen({super.key});

  @override
  State<PharmacyMedicinesScreen> createState() => _PharmacyMedicinesScreenState();
}

class _PharmacyMedicinesScreenState extends State<PharmacyMedicinesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _medicines = [
    {'name': 'Paracetamol 500mg', 'genericName': 'Paracetamol', 'category': 'OTC', 'stock': 120, 'price': 5.50, 'prescription': false, 'lowStockThreshold': 10},
    {'name': 'Amoxicillin 500mg', 'genericName': 'Amoxicillin', 'category': 'Prescription', 'stock': 45, 'price': 12.00, 'prescription': true, 'lowStockThreshold': 15},
    {'name': 'Ibuprofen 400mg', 'genericName': 'Ibuprofen', 'category': 'OTC', 'stock': 75, 'price': 7.25, 'prescription': false, 'lowStockThreshold': 10},
    {'name': 'Cetirizine 10mg', 'genericName': 'Cetirizine', 'category': 'OTC', 'stock': 8, 'price': 4.50, 'prescription': false, 'lowStockThreshold': 12},
    {'name': 'Metformin 500mg', 'genericName': 'Metformin', 'category': 'Prescription', 'stock': 32, 'price': 9.75, 'prescription': true, 'lowStockThreshold': 10},
    {'name': 'Azithromycin 250mg', 'genericName': 'Azithromycin', 'category': 'Prescription', 'stock': 5, 'price': 15.50, 'prescription': true, 'lowStockThreshold': 8},
  ];

  List<Map<String, dynamic>> get _filteredMedicines {
    final search = _searchController.text.toLowerCase().trim();
    return _medicines.where((medicine) {
      final medicineName = medicine['name'].toString().toLowerCase();
      final genericName = medicine['genericName'].toString().toLowerCase();
      final matchesSearch = medicineName.contains(search) || genericName.contains(search);
      final stock = medicine['stock'] as int;
      final threshold = medicine['lowStockThreshold'] as int? ?? 10;
      final isLowStock = stock <= threshold;
      final matchesCategory = _selectedCategory == 'All' ||
          medicine['category'] == _selectedCategory ||
          (_selectedCategory == 'Low Stock' && isLowStock);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicines = _filteredMedicines;
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
          'Medicines',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            onPressed: () => _showMedicineForm(context),
            icon: Icon(Icons.add_rounded, color: cs.onSurface),
          ),
          const SizedBox(width: 8),
        ],
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
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
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
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _categoryButton('All', isDark, cs),
                    _categoryButton('OTC', isDark, cs),
                    _categoryButton('Prescription', isDark, cs),
                    _categoryButton('Low Stock', isDark, cs),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // INVENTORY SUMMARY
              Row(
                children: [
                  Text(
                    'Medicine Inventory',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                  const Spacer(),
                  Text(
                    '${medicines.length} items',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // MEDICINE LIST
              Expanded(
                child: medicines.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: medicines.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final medicine = medicines[index];
                          return PharmacyMedicineCard(
                            medicine: medicine,
                            onOptionsTap: () {
                              PharmacyMedicineOptions.show(
                                context: context,
                                medicine: medicine,
                                onEdit: () => _showMedicineForm(context, existing: medicine),
                                onDelete: () => _deleteMedicine(medicine),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryButton(String category, bool isDark, ColorScheme cs) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : (isDark ? const Color(0xFF131D19) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? cs.primary : (isDark ? const Color(0xFF2A3A33) : Colors.grey.shade200),
            ),
          ),
          child: Center(
            child: Text(
              category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

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
            child: Icon(Icons.medication_outlined, size: 38, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          Text('No medicines found', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 7),
          Text(
            'Try changing your search or category.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _deleteMedicine(Map<String, dynamic> medicine) {
    setState(() => _medicines.remove(medicine));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine removed.')));
  }

  void _showMedicineForm(BuildContext context, {Map<String, dynamic>? existing}) {
    final bool isEditing = existing != null;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nameCtrl = TextEditingController(text: isEditing ? existing['name'] : '');
    final genericCtrl = TextEditingController(text: isEditing ? existing['genericName'] : '');
    final stockCtrl = TextEditingController(text: isEditing ? '${existing['stock']}' : '');
    final priceCtrl = TextEditingController(text: isEditing ? (existing['price'] as num).toStringAsFixed(2) : '');
    final lowStockCtrl = TextEditingController(text: isEditing ? '${existing['lowStockThreshold'] ?? 10}' : '10');
    final stockAdjustmentCtrl = TextEditingController();
    String stockAction = 'Add Stock';
    String category = isEditing ? existing['category'] : 'OTC';
    bool prescription = isEditing ? existing['prescription'] : false;
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
                          isEditing ? 'Edit Medicine' : 'Add Medicine',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface),
                        ),
                        const SizedBox(height: 20),
                        _formField(controller: nameCtrl, hint: 'Medicine name', icon: Icons.medication_outlined, context: context,
                            validator: (v) { if (v == null || v.trim().isEmpty) return 'Please enter medicine name'; return null; }),
                        const SizedBox(height: 14),
                        _formField(controller: genericCtrl, hint: 'Generic name', icon: Icons.science_outlined, context: context,
                            validator: (v) { if (v == null || v.trim().isEmpty) return 'Please enter generic name'; return null; }),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _formField(controller: stockCtrl, hint: isEditing ? 'Current Stock' : 'Initial Stock', icon: Icons.inventory_2_outlined, context: context,
                                  keyboardType: TextInputType.number,
                                  validator: (v) { if (v == null || v.trim().isEmpty) return 'Required'; if (int.tryParse(v.trim()) == null || int.parse(v.trim()) < 0) return 'Invalid'; return null; }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _formField(controller: priceCtrl, hint: 'Price (£)', icon: Icons.payments_outlined, context: context,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) { if (v == null || v.trim().isEmpty) return 'Required'; if (double.tryParse(v.trim()) == null) return 'Invalid'; return null; }),
                            ),
                          ],
                        ),

                        if (isEditing) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131D19) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stock Adjustment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                                const SizedBox(height: 5),
                                Text('Current stock: ${existing['stock']}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: stockAction,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      stockAction == 'Add Stock' ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                      color: stockAction == 'Add Stock' ? Colors.green : Colors.red,
                                    ),
                                    labelText: 'Stock Action',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Add Stock', child: Text('Add Stock')),
                                    DropdownMenuItem(value: 'Remove Stock', child: Text('Remove Stock')),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setSheetState(() => stockAction = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _formField(
                                  controller: stockAdjustmentCtrl,
                                  hint: stockAction == 'Add Stock' ? 'Quantity to add' : 'Quantity to remove',
                                  icon: stockAction == 'Add Stock' ? Icons.add_rounded : Icons.remove_rounded,
                                  context: context,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Enter quantity';
                                    final quantity = int.tryParse(v.trim());
                                    if (quantity == null || quantity <= 0) return 'Enter a valid quantity';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        _formField(controller: lowStockCtrl, hint: 'Low stock threshold', icon: Icons.warning_amber_outlined, context: context,
                            keyboardType: TextInputType.number,
                            validator: (v) { if (v == null || v.trim().isEmpty) return 'Required'; final value = int.tryParse(v.trim()); if (value == null) return 'Invalid'; if (value < 1) return 'Must be greater than 0'; return null; }),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: InputDecoration(
                            labelText: 'Medicine Category',
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'OTC', child: Text('OTC')),
                            DropdownMenuItem(value: 'Prescription', child: Text('Prescription')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() {
                              category = value;
                              prescription = value == 'Prescription';
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        SwitchListTile(
                          title: const Text('Prescription only', style: TextStyle(fontSize: 14)),
                          subtitle: Text('Requires a prescription', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          value: prescription,
                          onChanged: (value) {
                            setSheetState(() {
                              prescription = value;
                              category = value ? 'Prescription' : 'OTC';
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: cs.primary,
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              int stock = int.parse(stockCtrl.text.trim());
                              if (isEditing && stockAdjustmentCtrl.text.trim().isNotEmpty) {
                                final quantity = int.parse(stockAdjustmentCtrl.text.trim());
                                if (stockAction == 'Add Stock') {
                                  stock += quantity;
                                } else {
                                  stock -= quantity;
                                  if (stock < 0) stock = 0;
                                }
                              }
                              final threshold = int.parse(lowStockCtrl.text.trim());
                              final newMedicine = <String, dynamic>{
                                'name': nameCtrl.text.trim(),
                                'genericName': genericCtrl.text.trim(),
                                'category': category,
                                'stock': stock,
                                'price': double.parse(priceCtrl.text.trim()),
                                'prescription': prescription,
                                'lowStockThreshold': threshold,
                              };
                              setState(() {
                                if (isEditing) {
                                  final index = _medicines.indexOf(existing);
                                  if (index != -1) _medicines[index] = newMedicine;
                                } else {
                                  _medicines.insert(0, newMedicine);
                                }
                              });
                              Navigator.pop(ctx);
                              String message;
                              if (!isEditing) {
                                message = 'Medicine added.';
                              } else if (stockAction == 'Add Stock' && stockAdjustmentCtrl.text.trim().isNotEmpty) {
                                message = 'Medicine updated. Stock added.';
                              } else if (stockAction == 'Remove Stock' && stockAdjustmentCtrl.text.trim().isNotEmpty) {
                                message = 'Medicine updated. Stock removed.';
                              } else {
                                message = 'Medicine updated.';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: cs.primary));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text(
                              isEditing ? 'Update Medicine' : 'Add Medicine',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
