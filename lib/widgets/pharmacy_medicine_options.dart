import 'package:flutter/material.dart';

class PharmacyMedicineOptions {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> medicine,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  medicine['name'],

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 18),

                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                  ),

                  title: const Text(
                    'Edit Medicine',
                  ),

                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                  ),

                  title: const Text(
                    'Remove Medicine',
                  ),

                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}