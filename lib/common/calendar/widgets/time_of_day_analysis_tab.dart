import 'package:flutter/material.dart';
import 'swim_record.dart';

class TimeOfDayAnalysisTab extends StatelessWidget {
  final List<SwimRecord> allRecords;
  final DateTime focusedMonth;
  const TimeOfDayAnalysisTab({required this.allRecords, required this.focusedMonth});

  @override
  Widget build(BuildContext context) {
    final labels = ['아침', '점심', '저녁'];
    final counts = [0, 0, 0];
    final monthRecords = allRecords.where((r) => r.date.year == focusedMonth.year && r.date.month == focusedMonth.month).toList();
    for (var r in monthRecords) {
      final hour = r.date.hour;
      if (hour < 12) counts[0] += 1;
      else if (hour < 18) counts[1] += 1;
      else counts[2] += 1;
    }
    final total = counts.fold(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              const Text('주로 수영한 시간대', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) {
                  final percent = total > 0 ? (counts[i] * 100 ~/ total) : 0;
                  return Column(
                    children: [
                      Text('${counts[i]}회', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      Container(
                        width: 32,
                        height: 60 * (total > 0 ? counts[i] / (counts.reduce((a, b) => a > b ? a : b) == 0 ? 1 : counts.reduce((a, b) => a > b ? a : b)) : 0.1),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Text(labels[i], style: const TextStyle(fontSize: 12)),
                      Text('$percent%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 