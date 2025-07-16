import 'package:flutter/material.dart';
import 'swim_record.dart';

class DayOfWeekAnalysisTab extends StatelessWidget {
  final List<SwimRecord> allRecords;
  final DateTime focusedMonth;
  const DayOfWeekAnalysisTab({required this.allRecords, required this.focusedMonth});

  @override
  Widget build(BuildContext context) {
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    final counts = List.generate(7, (i) => 0);
    final monthRecords = allRecords.where((r) => r.date.year == focusedMonth.year && r.date.month == focusedMonth.month).toList();
    for (var r in monthRecords) {
      counts[(r.date.weekday % 7)] += 1; // 월~일(0~6)
    }
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              const Text('가장 많이 수영한 요일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${counts[i]}회', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        Container(
                          width: 18,
                          height: maxCount > 0 ? 80 * counts[i] / maxCount : 8,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Text(weekDays[i], style: const TextStyle(fontSize: 12)),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 