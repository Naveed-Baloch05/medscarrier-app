import 'package:flutter/material.dart';

import '../widgets/pharmacy_medicine_card.dart';
import '../widgets/pharmacy_medicine_options.dart';

class PharmacyMedicinesScreen extends StatefulWidget {
  const PharmacyMedicinesScreen({
    super.key,
  });

  @override
  State<PharmacyMedicinesScreen> createState() =>
      _PharmacyMedicinesScreenState();
}

class _PharmacyMedicinesScreenState
    extends State<PharmacyMedicinesScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'All';

  // ============================================================
  // TEMPORARY UI DATA
  // Backend will be connected later.
  // ============================================================

  final List<Map<String, dynamic>> _medicines = [
    {
      'name': 'Paracetamol 500mg',
      'genericName': 'Paracetamol',
      'category': 'OTC',
      'stock': 120,
      'price': 5.50,
      'prescription': false,
      'lowStockThreshold': 10,
    },
    {
      'name': 'Amoxicillin 500mg',
      'genericName': 'Amoxicillin',
      'category': 'Prescription',
      'stock': 45,
      'price': 12.00,
      'prescription': true,
      'lowStockThreshold': 15,
    },
    {
      'name': 'Ibuprofen 400mg',
      'genericName': 'Ibuprofen',
      'category': 'OTC',
      'stock': 75,
      'price': 7.25,
      'prescription': false,
      'lowStockThreshold': 10,
    },
    {
      'name': 'Cetirizine 10mg',
      'genericName': 'Cetirizine',
      'category': 'OTC',
      'stock': 8,
      'price': 4.50,
      'prescription': false,
      'lowStockThreshold': 12,
    },
    {
      'name': 'Metformin 500mg',
      'genericName': 'Metformin',
      'category': 'Prescription',
      'stock': 32,
      'price': 9.75,
      'prescription': true,
      'lowStockThreshold': 10,
    },
    {
      'name': 'Azithromycin 250mg',
      'genericName': 'Azithromycin',
      'category': 'Prescription',
      'stock': 5,
      'price': 15.50,
      'prescription': true,
      'lowStockThreshold': 8,
    },
  ];

  // ============================================================
  // FILTERED MEDICINES
  // ============================================================

  List<Map<String, dynamic>> get _filteredMedicines {
    final search = _searchController.text.toLowerCase().trim();

    return _medicines.where((medicine) {
      final medicineName =
      medicine['name'].toString().toLowerCase();

      final genericName =
      medicine['genericName'].toString().toLowerCase();

      final matchesSearch =
          medicineName.contains(search) ||
              genericName.contains(search);

      final stock = medicine['stock'] as int;

      final threshold =
          medicine['lowStockThreshold'] as int? ?? 10;

      final isLowStock = stock <= threshold;

      final matchesCategory =
          _selectedCategory == 'All' ||
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final medicines = _filteredMedicines;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Medicines',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              _showMedicineForm(context);
            },
            icon: const Icon(
              Icons.add_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ==================================================
              // SEARCH
              // ==================================================

              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: TextField(
                  controller: _searchController,

                  onChanged: (_) {
                    setState(() {});
                  },

                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),

                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade600,
                    ),

                    suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();

                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                      ),
                    )
                        : null,

                    border: InputBorder.none,

                    contentPadding:
                    const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // FILTER
              // ==================================================

              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _categoryButton('All'),
                    _categoryButton('OTC'),
                    _categoryButton('Prescription'),
                    _categoryButton('Low Stock'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // INVENTORY SUMMARY
              // ==================================================

              Row(
                children: [
                  const Text(
                    'Medicine Inventory',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${medicines.length} items',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // MEDICINE LIST
              // ==================================================

              Expanded(
                child: medicines.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                  physics:
                  const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.only(
                    bottom: 20,
                  ),

                  itemCount: medicines.length,

                  separatorBuilder: (_, __) {
                    return const SizedBox(
                      height: 12,
                    );
                  },

                  itemBuilder: (context, index) {
                    final medicine = medicines[index];

                    return PharmacyMedicineCard(
                      medicine: medicine,

                      onOptionsTap: () {
                        PharmacyMedicineOptions.show(
                          context: context,
                          medicine: medicine,

                          onEdit: () {
                            _showMedicineForm(
                              context,
                              existing: medicine,
                            );
                          },

                          onDelete: () {
                            _deleteMedicine(
                              medicine,
                            );
                          },
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

  // ============================================================
  // CATEGORY FILTER BUTTON
  // ============================================================

  Widget _categoryButton(String category) {
    final isSelected =
        _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },

        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),

          decoration: BoxDecoration(
            color: isSelected
                ? Colors.black
                : Colors.white,

            borderRadius:
            BorderRadius.circular(20),

            border: Border.all(
              color: isSelected
                  ? Colors.black
                  : Colors.grey.shade200,
            ),
          ),

          child: Center(
            child: Text(
              category,

              style: TextStyle(
                fontSize: 13,

                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w500,

                color: isSelected
                    ? Colors.white
                    : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [
          Container(
            width: 80,
            height: 80,

            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),

            child: Icon(
              Icons.medication_outlined,
              size: 38,
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No medicines found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Try changing your search or category.',
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE MEDICINE
  // ============================================================

  void _deleteMedicine(
      Map<String, dynamic> medicine) {
    setState(() {
      _medicines.remove(medicine);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Medicine removed.',
        ),
      ),
    );
  }

  // ============================================================
  // ADD / EDIT MEDICINE FORM
  // ============================================================

  void _showMedicineForm(
      BuildContext context, {
        Map<String, dynamic>? existing,
      }) {
    final bool isEditing = existing != null;

    final nameCtrl = TextEditingController(
      text: isEditing
          ? existing['name']
          : '',
    );

    final genericCtrl = TextEditingController(
      text: isEditing
          ? existing['genericName']
          : '',
    );

    final stockCtrl = TextEditingController(
      text: isEditing
          ? '${existing['stock']}'
          : '',
    );

    final priceCtrl = TextEditingController(
      text: isEditing
          ? (existing['price'] as num)
          .toStringAsFixed(2)
          : '',
    );

    final lowStockCtrl = TextEditingController(
      text: isEditing
          ? '${existing['lowStockThreshold'] ?? 10}'
          : '10',
    );

    // ------------------------------------------------------------
    // STOCK ADJUSTMENT
    // ------------------------------------------------------------

    final stockAdjustmentCtrl =
    TextEditingController();

    String stockAction = 'Add Stock';

    String category =
    isEditing
        ? existing['category']
        : 'OTC';

    bool prescription =
    isEditing
        ? existing['prescription']
        : false;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      isScrollControlled: true,

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(25),
        ),
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
                  MediaQuery.of(ctx)
                      .viewInsets
                      .bottom +
                      24,
                ),

                child: Form(
                  key: formKey,

                  child:
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        // ==================================================
                        // DRAG HANDLE
                        // ==================================================

                        Center(
                          child: Container(
                            width: 40,
                            height: 4,

                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .grey
                                  .shade300,

                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // ==================================================
                        // TITLE
                        // ==================================================

                        Text(
                          isEditing
                              ? 'Edit Medicine'
                              : 'Add Medicine',

                          style:
                          const TextStyle(
                            fontSize: 20,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // ==================================================
                        // MEDICINE NAME
                        // ==================================================

                        _formField(
                          controller: nameCtrl,
                          hint: 'Medicine name',
                          icon:
                          Icons.medication_outlined,
                          validator: (v) {
                            if (v == null ||
                                v.trim().isEmpty) {
                              return 'Please enter medicine name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // GENERIC NAME
                        // ==================================================

                        _formField(
                          controller: genericCtrl,
                          hint: 'Generic name',
                          icon:
                          Icons.science_outlined,
                          validator: (v) {
                            if (v == null ||
                                v.trim().isEmpty) {
                              return 'Please enter generic name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // STOCK + PRICE
                        // ==================================================

                        Row(
                          children: [
                            Expanded(
                              child: _formField(
                                controller:
                                stockCtrl,
                                hint: isEditing
                                    ? 'Current Stock'
                                    : 'Initial Stock',
                                icon: Icons
                                    .inventory_2_outlined,
                                keyboardType:
                                TextInputType
                                    .number,
                                validator: (v) {
                                  if (v == null ||
                                      v.trim()
                                          .isEmpty) {
                                    return 'Required';
                                  }

                                  final value =
                                  int.tryParse(
                                    v.trim(),
                                  );

                                  if (value ==
                                      null) {
                                    return 'Invalid';
                                  }

                                  if (value < 0) {
                                    return 'Invalid';
                                  }

                                  return null;
                                },
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: _formField(
                                controller:
                                priceCtrl,
                                hint: 'Price (£)',
                                icon: Icons
                                    .payments_outlined,
                                keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (v) {
                                  if (v == null ||
                                      v.trim()
                                          .isEmpty) {
                                    return 'Required';
                                  }

                                  if (double.tryParse(
                                    v.trim(),
                                  ) ==
                                      null) {
                                    return 'Invalid';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        // ==================================================
                        // STOCK ADJUSTMENT
                        // ONLY SHOWN WHILE EDITING
                        // ==================================================

                        if (isEditing) ...[
                          const SizedBox(
                            height: 18,
                          ),

                          Container(
                            width:
                            double.infinity,

                            padding:
                            const EdgeInsets
                                .all(15),

                            decoration:
                            BoxDecoration(
                              color: Colors
                                  .grey
                                  .shade50,

                              borderRadius:
                              BorderRadius
                                  .circular(
                                15,
                              ),

                              border:
                              Border.all(
                                color: Colors
                                    .grey
                                    .shade200,
                              ),
                            ),

                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                              children: [
                                const Text(
                                  'Stock Adjustment',
                                  style:
                                  TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  'Current stock: ${existing['stock']}',
                                  style:
                                  TextStyle(
                                    fontSize: 12,
                                    color: Colors
                                        .grey
                                        .shade600,
                                  ),
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                // ------------------------------------------
                                // ADD / REMOVE DROPDOWN
                                // ------------------------------------------

                                DropdownButtonFormField<
                                    String>(
                                  initialValue:
                                  stockAction,

                                  decoration:
                                  InputDecoration(
                                    prefixIcon:
                                    Icon(
                                      stockAction ==
                                          'Add Stock'
                                          ? Icons
                                          .add_circle_outline
                                          : Icons
                                          .remove_circle_outline,
                                      color: stockAction ==
                                          'Add Stock'
                                          ? Colors
                                          .green
                                          : Colors
                                          .red,
                                    ),

                                    labelText:
                                    'Stock Action',

                                    border:
                                    OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        14,
                                      ),
                                    ),

                                    contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal:
                                      16,
                                      vertical:
                                      14,
                                    ),
                                  ),

                                  items: const [
                                    DropdownMenuItem(
                                      value:
                                      'Add Stock',
                                      child: Text(
                                          'Add Stock'),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                      'Remove Stock',
                                      child: Text(
                                          'Remove Stock'),
                                    ),
                                  ],

                                  onChanged:
                                      (value) {
                                    if (value ==
                                        null) {
                                      return;
                                    }

                                    setSheetState(
                                          () {
                                        stockAction =
                                            value;
                                      },
                                    );
                                  },
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                _formField(
                                  controller:
                                  stockAdjustmentCtrl,
                                  hint:
                                  stockAction ==
                                      'Add Stock'
                                      ? 'Quantity to add'
                                      : 'Quantity to remove',
                                  icon: stockAction ==
                                      'Add Stock'
                                      ? Icons
                                      .add_rounded
                                      : Icons
                                      .remove_rounded,
                                  keyboardType:
                                  TextInputType
                                      .number,
                                  validator: (v) {
                                    if (v == null ||
                                        v.trim()
                                            .isEmpty) {
                                      return 'Enter quantity';
                                    }

                                    final quantity =
                                    int.tryParse(
                                      v.trim(),
                                    );

                                    if (quantity ==
                                        null ||
                                        quantity <=
                                            0) {
                                      return 'Enter a valid quantity';
                                    }

                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // LOW STOCK THRESHOLD
                        // ==================================================

                        _formField(
                          controller:
                          lowStockCtrl,
                          hint:
                          'Low stock threshold',
                          icon: Icons
                              .warning_amber_outlined,
                          keyboardType:
                          TextInputType
                              .number,
                          validator: (v) {
                            if (v == null ||
                                v.trim().isEmpty) {
                              return 'Required';
                            }

                            final value =
                            int.tryParse(
                              v.trim(),
                            );

                            if (value == null) {
                              return 'Invalid';
                            }

                            if (value < 1) {
                              return 'Must be greater than 0';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // CATEGORY
                        // ==================================================

                        DropdownButtonFormField<
                            String>(
                          initialValue:
                          category,

                          decoration:
                          InputDecoration(
                            labelText:
                            'Medicine Category',

                            prefixIcon:
                            const Icon(
                              Icons
                                  .category_outlined,
                            ),

                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                14,
                              ),
                            ),

                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                14,
                              ),

                              borderSide:
                              BorderSide(
                                color: Colors
                                    .grey
                                    .shade300,
                              ),
                            ),

                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                14,
                              ),

                              borderSide:
                              const BorderSide(
                                color:
                                Colors.black,
                              ),
                            ),

                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),

                          items: const [
                            DropdownMenuItem(
                              value: 'OTC',
                              child:
                              Text('OTC'),
                            ),

                            DropdownMenuItem(
                              value:
                              'Prescription',
                              child: Text(
                                'Prescription',
                              ),
                            ),
                          ],

                          onChanged:
                              (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setSheetState(() {
                              category =
                                  value;

                              if (category ==
                                  'Prescription') {
                                prescription =
                                true;
                              } else {
                                prescription =
                                false;
                              }
                            });
                          },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ==================================================
                        // PRESCRIPTION SWITCH
                        // ==================================================

                        SwitchListTile(
                          title:
                          const Text(
                            'Prescription only',
                            style:
                            TextStyle(
                              fontSize: 14,
                            ),
                          ),

                          subtitle: Text(
                            'Requires a prescription',
                            style:
                            TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey
                                  .shade500,
                            ),
                          ),

                          value:
                          prescription,

                          onChanged:
                              (value) {
                            setSheetState(
                                  () {
                                prescription =
                                    value;

                                category =
                                value
                                    ? 'Prescription'
                                    : 'OTC';
                              },
                            );
                          },

                          contentPadding:
                          EdgeInsets.zero,

                          activeThumbColor:
                          Colors.black,
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        // ==================================================
                        // SAVE / UPDATE BUTTON
                        // ==================================================

                        SizedBox(
                          width:
                          double.infinity,

                          height: 50,

                          child:
                          ElevatedButton(
                            onPressed: () {
                              if (!formKey
                                  .currentState!
                                  .validate()) {
                                return;
                              }

                              // --------------------------------------------
                              // CURRENT STOCK
                              // --------------------------------------------

                              int stock =
                              int.parse(
                                stockCtrl.text
                                    .trim(),
                              );

                              // --------------------------------------------
                              // STOCK ADJUSTMENT
                              // --------------------------------------------

                              if (isEditing &&
                                  stockAdjustmentCtrl
                                      .text
                                      .trim()
                                      .isNotEmpty) {
                                final quantity =
                                int.parse(
                                  stockAdjustmentCtrl
                                      .text
                                      .trim(),
                                );

                                if (stockAction ==
                                    'Add Stock') {
                                  stock += quantity;
                                } else {
                                  stock -= quantity;

                                  // Stock can never go below zero.
                                  if (stock < 0) {
                                    stock = 0;
                                  }
                                }
                              }

                              // --------------------------------------------
                              // LOW STOCK THRESHOLD
                              // --------------------------------------------

                              final threshold =
                              int.parse(
                                lowStockCtrl
                                    .text
                                    .trim(),
                              );

                              // --------------------------------------------
                              // CREATE UPDATED MEDICINE
                              // --------------------------------------------

                              final newMedicine =
                              <String, dynamic>{
                                'name':
                                nameCtrl
                                    .text
                                    .trim(),

                                'genericName':
                                genericCtrl
                                    .text
                                    .trim(),

                                'category':
                                category,

                                'stock':
                                stock,

                                'price':
                                double.parse(
                                  priceCtrl
                                      .text
                                      .trim(),
                                ),

                                'prescription':
                                prescription,

                                'lowStockThreshold':
                                threshold,
                              };

                              // --------------------------------------------
                              // UPDATE LIST
                              // --------------------------------------------

                              setState(() {
                                if (isEditing) {
                                  final index =
                                  _medicines
                                      .indexOf(
                                    existing,
                                  );

                                  if (index !=
                                      -1) {
                                    _medicines[
                                    index] =
                                        newMedicine;
                                  }
                                } else {
                                  _medicines.insert(
                                    0,
                                    newMedicine,
                                  );
                                }
                              });

                              Navigator.pop(
                                ctx,
                              );

                              // --------------------------------------------
                              // SUCCESS MESSAGE
                              // --------------------------------------------

                              String message;

                              if (!isEditing) {
                                message =
                                'Medicine added.';
                              } else if (
                              stockAction ==
                                  'Add Stock' &&
                                  stockAdjustmentCtrl
                                      .text
                                      .trim()
                                      .isNotEmpty) {
                                message =
                                'Medicine updated. Stock added.';
                              } else if (
                              stockAction ==
                                  'Remove Stock' &&
                                  stockAdjustmentCtrl
                                      .text
                                      .trim()
                                      .isNotEmpty) {
                                message =
                                'Medicine updated. Stock removed.';
                              } else {
                                message =
                                'Medicine updated.';
                              }

                              ScaffoldMessenger
                                  .of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content:
                                  Text(message),
                                ),
                              );
                            },

                            style:
                            ElevatedButton
                                .styleFrom(
                              backgroundColor:
                              Colors.black,

                              foregroundColor:
                              Colors.white,

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  15,
                                ),
                              ),
                            ),

                            child: Text(
                              isEditing
                                  ? 'Update Medicine'
                                  : 'Add Medicine',

                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 8,
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

  // ============================================================
  // FORM FIELD
  // ============================================================

  Widget _formField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType:
      keyboardType,

      validator:
      validator,

      decoration:
      InputDecoration(
        hintText: hint,

        hintStyle:
        TextStyle(
          color:
          Colors.grey.shade400,
          fontSize: 14,
        ),

        prefixIcon:
        Icon(
          icon,
          color:
          Colors.grey.shade500,
          size: 20,
        ),

        errorStyle:
        const TextStyle(
          fontSize: 12,
        ),

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),

          borderSide:
          BorderSide(
            color:
            Colors.grey.shade300,
          ),
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),

          borderSide:
          BorderSide(
            color:
            Colors.grey.shade300,
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),

          borderSide:
          const BorderSide(
            color:
            Colors.black,
          ),
        ),

        contentPadding:
        const EdgeInsets
            .symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}