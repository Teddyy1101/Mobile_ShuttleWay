import 'package:flutter/material.dart';

class BusMarkerWidget extends StatelessWidget {
  final String? licensePlate; // giữ lại API cũ nhưng không hiển thị

  const BusMarkerWidget({
    super.key,
    this.licensePlate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4285F4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4285F4).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_bus_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
