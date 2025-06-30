// lib/features/home/widgets/swimming_pool_selector.dart
import 'package:flutter/material.dart';

class SwimmingPoolSelector extends StatelessWidget {
  final Map<String, dynamic>? selectedPool;
  final VoidCallback onTap;

  const SwimmingPoolSelector({
    Key? key,
    required this.selectedPool,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: selectedPool == null
            ? Column(
          children: [
            Icon(
              Icons.add_location_alt_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              '나의 수영장 고르기',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pool,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedPool!['name'] ?? '수영장',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
            if (selectedPool!['address'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      selectedPool!['address'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (selectedPool!['distance'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.directions_walk,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${selectedPool!['distance']}m',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}