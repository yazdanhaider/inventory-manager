import 'package:flutter/material.dart';

class StockStatusBadge extends StatelessWidget {
  final bool isLowStock;

  const StockStatusBadge({super.key, required this.isLowStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLowStock ? Colors.red : Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isLowStock ? 'Low Stock' : 'Normal',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
