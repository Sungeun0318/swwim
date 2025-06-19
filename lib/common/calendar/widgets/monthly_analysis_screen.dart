import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'swim_record.dart';

import 'distance_tab.dart';
import 'count_analysis_tab.dart';
import 'time_analysis_tab.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat('yyyy년 M월 분석').format(widget.focusedMonth);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DistanceTab(
            records: _monthRecords,
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
        ],
      ),
    );
  }
}
