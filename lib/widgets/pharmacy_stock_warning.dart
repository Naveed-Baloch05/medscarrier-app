import 'package:flutter/material.dart';

class PharmacyStockWarning extends StatelessWidget {
  const PharmacyStockWarning({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius:
        BorderRadius.circular(10),
      ),

      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 17,
            color: Colors.red.shade600,
          ),

          const SizedBox(width: 7),

          Text(
            'Low stock — consider restocking',

            style: TextStyle(
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
              color:
              Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }
}