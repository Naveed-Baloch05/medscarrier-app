import 'package:flutter/material.dart';

class PharmacyMedicineOptions {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> medicine,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
                  title: Text(
                    'Edit Medicine',
                    style: TextStyle(color: cs.onSurface),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600),
                  title: Text(
                    'Remove Medicine',
                    style: TextStyle(color: Colors.red.shade600),
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
