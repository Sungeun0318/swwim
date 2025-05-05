import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'training_item.dart';
import 'exercise_graph_widget.dart';
import 'dialog_training_input.dart';
import 'dialog_delete.dart';
import 'dialog_share.dart';
import 'dialog_preschedule.dart';
import 'fab_menu.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isFabExpanded = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<TrainingItem>> _events = {};

  void _handleFabAction(String action) {
    switch (action) {
      case "훈련 추가":
        showTrainingInputDialog(context, _addTraining);
        break;
      case "리스트 삭제":
        final day = _selectedDay ?? _focusedDay;
        final key = DateTime.utc(day.year, day.month, day.day);
        final events = List<TrainingItem>.from(_events[key] ?? []);
        showDeleteDialog(context, events, (selectedItems) {
          setState(() {
            _events[key]?.removeWhere((item) => selectedItems.contains(item));
            if (_events[key]?.isEmpty ?? false) _events.remove(key);
          });
        });
        break;
      case "캘린더 공유":
        showShareDialog(context);
        break;
    }
    setState(() => _isFabExpanded = false);
  }

  Future<void> _showExerciseGraphDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("운동량 그래프"),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: ExerciseGraphWidget(dateRange: picked, events: _events),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("닫기"),
            ),
          ],
        ),
      );
    }
  }

  List<TrainingItem> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _addTraining(TrainingItem training) {
    final dateKey = DateTime.utc(
      _selectedDay?.year ?? _focusedDay.year,
      _selectedDay?.month ?? _focusedDay.month,
      _selectedDay?.day ?? _focusedDay.day,
    );

    setState(() {
      _events[dateKey] ??= [];
      _events[dateKey]!.add(training);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.arrow_back, color: Colors.white),
                  Spacer(),
                  Text("Z:TOP",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent)),
                  Spacer(),
                  Icon(Icons.settings, color: Colors.white),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.bar_chart),
                    tooltip: "운동량 그래프",
                    onPressed: _showExerciseGraphDialog,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                          });
                        },
                      ),
                      Text(
                        DateFormat('yyyy.MM').format(_focusedDay),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                          });
                        },
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.menu),
                    tooltip: '스케줄 미리 작성',
                    onPressed: () => showPreScheduleDialog(context),
                  ),
                ],
              ),
            ),
            TableCalendar(
              headerVisible: false,
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _selectedDay != null
                    ? DateFormat('yyyy.MM.dd.E', 'ko').format(_selectedDay!)
                    : "날짜를 선택해주세요",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: _getEventsForDay(_selectedDay ?? _focusedDay).length,
                    itemBuilder: (context, index) {
                      final item = _getEventsForDay(_selectedDay ?? _focusedDay)[index];
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(item.distance, style: TextStyle(fontSize: 14)),
                                Text(item.time, style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          Divider(height: 1, thickness: 2, color: Colors.black),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FabMenu(
        isExpanded: _isFabExpanded,
        toggle: () => setState(() => _isFabExpanded = !_isFabExpanded),
        onAction: _handleFabAction,
      ),
    );
  }
}
