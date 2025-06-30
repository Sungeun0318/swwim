import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kDebugMode 사용을 위해 추가
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/user_service.dart';
import 'widgets/DailyAnalysisScreen.dart';
import 'widgets/training_item.dart';
import 'dialogs/dialog_training_input.dart';
import 'dialogs/dialog_share.dart';
import 'widgets/swim_record.dart';
import 'widgets/monthly_analysis_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 기존 이벤트 맵
  final Map<DateTime, List<TrainingItem>> _events = {};
  // ▶ 변경: 클릭된 날짜의 훈련 리스트를 저장할 상태 추가
  List<TrainingItem> _selectedEvents = [];

  List<SwimRecord> _swimRecords = [];
  bool _isLoading = true;
  final UserService _userService = UserService();
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadCalendarEvents();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _userService.getUserStats();
    setState(() => _stats = stats);
  }

  Future<void> _loadCalendarEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) print('사용자가 로그인되어 있지 않음');
      setState(() => _isLoading = false);
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('calendar_events')
          .where('userId', isEqualTo: user.uid)
          .get();

      final Map<DateTime, List<TrainingItem>> events = {};
      final List<SwimRecord> records = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final dateKey = DateTime.utc(date.year, date.month, date.day);
        final trainings = data['trainings'] as List? ?? [];
        final List<TrainingItem> dayEvents = [];

        for (var training in trainings) {
          dayEvents.add(TrainingItem(
            id: doc.id,
            date: date,
            name: training['title'] ?? '훈련',
            distance: '${training['distance'] ?? 0}m',
            time: '${training['cycle'] ?? 0}초 x ${training['count'] ?? 1}',
          ));
        }

        events[dateKey] = dayEvents;
        records.add(SwimRecord(
          date: date,
          distance: (data['totalDistance'] ?? 0).toDouble(),
          duration: _parseDuration(data['totalTime'] ?? '00:00:00'),
        ));
      }

      setState(() {
        _events
          ..clear()
          ..addAll(events);
        _swimRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) print('캘린더 데이터 로드 오류: $e');
      setState(() => _isLoading = false);
    }
  }

  Duration _parseDuration(String timeString) {
    try {
      final parts = timeString.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final s = parts.length > 2 ? int.parse(parts[2].split('.')[0]) : 0;
      return Duration(hours: h, minutes: m, seconds: s);
    } catch (_) {
      return const Duration(minutes: 30);
    }
  }

  List<SwimRecord> get _thisMonthRecords => _swimRecords
      .where((r) => r.date.year == _focusedDay.year && r.date.month == _focusedDay.month)
      .toList();

  double get _totalDistanceKm {
    final meters = _thisMonthRecords.fold<double>(0, (sum, r) => sum + r.distance);
    return meters / 1000;
  }

  int get _totalSessions => _thisMonthRecords.length;

  Duration get _totalDuration => _thisMonthRecords
      .fold<Duration>(Duration.zero, (sum, r) => sum + r.duration);

  void _addTraining(TrainingItem item) {
    final key = DateTime.utc(item.date.year, item.date.month, item.date.day);
    setState(() {
      _events[key] ??= [];
      _events[key]!.add(item);
    });
  }

  List<TrainingItem> _getEvents(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('yyyy년 M월 d일').format(_focusedDay);
    final weekDays = ['일', '월', '화', '수', '목', '금', '토'];
    final today = DateTime.now();
    final isThisMonth = _focusedDay.year == today.year && _focusedDay.month == today.month;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(monthLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── 상단 요일/날짜 네비게이션 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final date = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1 - i));
                final isSelected = _selectedDay != null && date.year == _selectedDay!.year && date.month == _selectedDay!.month && date.day == _selectedDay!.day;
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                return GestureDetector(
                  onTap: () async {
                    // 파이어베이스에서 해당 날짜의 기록 불러오기
                    final user = FirebaseAuth.instance.currentUser;
                    SwimRecord? record;
                    if (user != null) {
                      final snapshot = await FirebaseFirestore.instance
                          .collection('calendar_events')
                          .where('userId', isEqualTo: user.uid)
                          .where('date', isGreaterThanOrEqualTo: DateTime(date.year, date.month, date.day, 0, 0, 0))
                          .where('date', isLessThan: DateTime(date.year, date.month, date.day, 23, 59, 59))
                          .get();
                      if (snapshot.docs.isNotEmpty) {
                        final data = snapshot.docs.first.data();
                        record = SwimRecord(
                          date: (data['date'] as Timestamp).toDate(),
                          distance: (data['totalDistance'] ?? 0).toDouble(),
                          duration: _parseDuration(data['totalTime'] ?? '00:00:00'),
                          calories: (data['totalCalories'] ?? 0).toDouble(),
                          avgHeartRate: data['avgHeartRate'],
                          avgPace: data['avgPace'],
                        );
                      }
                    }
                    // 월간 분석 스타일 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MonthlyAnalysisScreen(
                          focusedMonth: date,
                          allRecords: _swimRecords,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(weekDays[i], style: TextStyle(color: i == 0 ? Colors.red : (i == 6 ? Colors.blue : Colors.black), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : (isToday ? Colors.lightBlue.shade100 : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text('${date.day}', style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      // 미니 마커(수영 기록 있으면 표시)
                      if (_getEvents(date).isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // ── 상단 통계 카드 ──
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.blue, size: 18),
                      const SizedBox(width: 6),
                      const Text('이번 달 수영 분석', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _loadStats,
                        child: const Icon(Icons.refresh, color: Colors.grey, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('총 거리', '${((_stats['totalDistance'] ?? (_totalDistanceKm * 1000)) / 1000).toStringAsFixed(1)}km', Icons.straighten, Colors.blue),
                      _buildStatItem('총 칼로리', '${_stats['totalCalories'] ?? 0}kcal', Icons.local_fire_department, Colors.redAccent),
                      _buildStatItem('총 횟수', '${_stats['totalSessions'] ?? _totalSessions}회', Icons.pool, Colors.green),
                      _buildStatItem('총 시간', '${(_stats['totalMinutes'] ?? _totalDuration.inMinutes) ~/ 60}h ${(_stats['totalMinutes'] ?? _totalDuration.inMinutes) % 60}m', Icons.access_time, Colors.deepPurple),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── 캘린더 ──
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                headerVisible: false,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                calendarFormat: CalendarFormat.month,
                eventLoader: _getEvents,
                daysOfWeekStyle: DaysOfWeekStyle(
                  dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date),
                  weekendStyle: const TextStyle(color: Colors.red),
                  weekdayStyle: const TextStyle(color: Colors.black),
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  markersMaxCount: 0,
                  todayDecoration: BoxDecoration(
                    color: Colors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                availableGestures: AvailableGestures.horizontalSwipe,
                onPageChanged: (focused) => setState(() => _focusedDay = focused),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedEvents = _getEvents(selectedDay);
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, _) => _buildDayCell(day),
                  todayBuilder: (ctx, day, _) => _buildDayCell(day, isToday: true),
                  selectedBuilder: (ctx, day, _) => _buildDayCell(day, isSelected: true),
                ),
              ),
            ),
          ),

          // ── 일별 기록 리스트 ──
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: _selectedDay == null
                  ? const Center(child: Text('날짜를 선택해 주세요'))
                  : _selectedEvents.isEmpty
                  ? Center(
                child: Text(
                  '${DateFormat('yyyy.MM.dd').format(_selectedDay!)}\n운동 기록이 없습니다',
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                itemCount: _selectedEvents.length,
                itemBuilder: (_, idx) {
                  final item = _selectedEvents[idx];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.distance}, ${item.time}'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: Colors.lightBlue,
          onPressed: () {
            final dateToAdd = _selectedDay ?? _focusedDay;
            showTrainingInputDialog(context, dateToAdd, _addTraining);
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day,
      {bool isToday = false, bool isSelected = false}) {
    final events = _getEvents(day);
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue
            : isToday
            ? Colors.lightBlue.shade100
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (events.isNotEmpty)
            const Positioned(
              bottom: 2,
              left: 2,
              right: 2,
              child: SizedBox(
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
