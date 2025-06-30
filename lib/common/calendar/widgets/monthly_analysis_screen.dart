import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'swim_record.dart';

import 'distance_tab.dart';
import 'count_analysis_tab.dart';
import 'time_analysis_tab.dart';
import 'day_of_week_analysis_tab.dart';
import 'time_of_day_analysis_tab.dart';

class MonthlyAnalysisScreen extends StatefulWidget {
  final DateTime focusedMonth;
  final List<SwimRecord> allRecords;

  const MonthlyAnalysisScreen({
    Key? key,
    required this.focusedMonth,
    required this.allRecords,
  }) : super(key: key);

  @override
  State<MonthlyAnalysisScreen> createState() => _MonthlyAnalysisScreenState();
}

class _MonthlyAnalysisScreenState extends State<MonthlyAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<SwimRecord> get _monthRecords => widget.allRecords
      .where((r) =>
  r.date.year == widget.focusedMonth.year &&
      r.date.month == widget.focusedMonth.month)
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('yyyy년 M월 분석').format(widget.focusedMonth);
    final monthRecords = _monthRecords;
    final totalDistance = monthRecords.fold<double>(0, (sum, r) => sum + r.distance) / 1000;
    final totalSessions = monthRecords.length;
    final totalDuration = monthRecords.fold<Duration>(Duration.zero, (sum, r) => sum + r.duration);
    final totalMinutes = totalDuration.inMinutes;
    // 칼로리 예시(실제 데이터 있으면 교체)
    final totalCalories = monthRecords.fold<double>(0, (sum, r) => sum + (r.calories ?? 0));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '거리'),
            Tab(text: '횟수'),
            Tab(text: '시간'),
            Tab(text: '요일'),
            Tab(text: '시간대'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── 상단 요약 카드 ──
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('총 거리', '${totalDistance.toStringAsFixed(1)}km', Icons.straighten, Colors.blue),
                  _buildStatCard('총 칼로리', '${totalCalories.toInt()}kcal', Icons.local_fire_department, Colors.redAccent),
                  _buildStatCard('총 횟수', '$totalSessions회', Icons.pool, Colors.green),
                  _buildStatCard('총 시간', '${totalMinutes ~/ 60}h ${totalMinutes % 60}m', Icons.access_time, Colors.deepPurple),
                ],
              ),
            ),
          ),
          // ── 탭별 분석 ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                DistanceTab(
                  records: monthRecords,
                  month: widget.focusedMonth,
                  allRecords: widget.allRecords,
                ),
                CountAnalysisTab(
                  allRecords: widget.allRecords,
                  focusedMonth: widget.focusedMonth,
                ),
                TimeAnalysisTab(
                  allRecords: widget.allRecords,
                  focusedMonth: widget.focusedMonth,
                ),
                // 요일별 통계 탭(추가 구현 필요)
                DayOfWeekAnalysisTab(
                  allRecords: widget.allRecords,
                  focusedMonth: widget.focusedMonth,
                ),
                // 시간대별 통계 탭(추가 구현 필요)
                TimeOfDayAnalysisTab(
                  allRecords: widget.allRecords,
                  focusedMonth: widget.focusedMonth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
