import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/DailyAnalysisScreen.dart';
import 'widgets/training_item.dart';
import 'dialogs/dialog_training_input.dart';
import 'dialogs/dialog_delete.dart';
import 'dialogs/dialog_share.dart';
import 'dialogs/dialog_preschedule.dart';
import 'widgets/fab_menu.dart';
import 'widgets/monthly_analysis_screen.dart';
import 'widgets/swim_record.dart';
import 'package:swim/common/widgets/animated_loading.dart'; // 우리가 만든 위젯

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _fabExpanded = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<TrainingItem>> _events = {};
  List<SwimRecord> _swimRecords = []; // Firebase에서 가져올 데이터
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendarEvents();
  }

  // Firebase에서 캘린더 이벤트 로드
  Future<void> _loadCalendarEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('사용자가 로그인되어 있지 않음'); // 디버깅
      setState(() => _isLoading = false);
      return;
    }

    print('사용자 UID: ${user.uid}'); // 디버깅

    try {
      // calendar_events 컬렉션에서 사용자 데이터 가져오기 (인덱스 없이)
      final snapshot = await FirebaseFirestore.instance
          .collection('calendar_events')
          .where('userId', isEqualTo: user.uid)
          .get(); // orderBy 제거 (인덱스 문제 회피)

      print('가져온 문서 수: ${snapshot.docs.length}'); // 디버깅

      final Map<DateTime, List<TrainingItem>> events = {};
      final List<SwimRecord> records = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('문서 데이터: $data'); // 디버깅

        final date = (data['date'] as Timestamp).toDate();
        final dateKey = DateTime.utc(date.year, date.month, date.day);

        print('날짜 키: $dateKey'); // 디버깅

        // TrainingItem 생성
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
        print('추가된 이벤트: ${dayEvents.length}개'); // 디버깅

        // SwimRecord 생성 (분석용)
        records.add(SwimRecord(
          date: date,
          distance: (data['totalDistance'] ?? 0).toDouble(),
          duration: _parseDuration(data['totalTime'] ?? '00:00:00'),
        ));
      }

      print('총 이벤트 날짜 수: ${events.length}'); // 디버깅
      print('총 수영 기록 수: ${records.length}'); // 디버깅

      setState(() {
        _events.clear();
        _events.addAll(events);
        _swimRecords = records;
        _isLoading = false;
      });

      print('상태 업데이트 완료'); // 디버깅
    } catch (e) {
      print('캘린더 데이터 로드 오류: $e');
      setState(() => _isLoading = false);
    }
  }

  Duration _parseDuration(String timeString) {
    try {
      final parts = timeString.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = parts.length > 2 ? int.parse(parts[2].split('.')[0]) : 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } catch (e) {
      return const Duration(minutes: 30); // 기본값
    }
  }

  // 이번 달 기록 필터
  List<SwimRecord> get _thisMonthRecords => _swimRecords
      .where((r) => r.date.year == _focusedDay.year && r.date.month == _focusedDay.month)
      .toList();

  // 통계
  double get _totalDistanceKm {
    final meters = _thisMonthRecords.fold<double>(0, (sum, r) => sum + r.distance);
    return meters / 1000;
  }
  int get _totalSessions => _thisMonthRecords.length;
  Duration get _totalDuration => _thisMonthRecords.fold<Duration>(Duration.zero, (sum, r) => sum + r.duration);
  String get _totalDurationStr {
    final h = _totalDuration.inHours;
    final m = _totalDuration.inMinutes % 60;
    return '${h}h ${m}m';
  }

  // 다이얼로그에서 넘어온 훈련 기록 추가
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
    final monthLabel = DateFormat('yyyy년 M월').format(_focusedDay);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: AnimatedLoading(
            message: "수영 기록을 불러오는 중...",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.schedule),
          onPressed: () => showPreScheduleDialog(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCalendarEvents,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showShareDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 월 이동 + 오늘 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(monthLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _goToday,
                  child: const Text('오늘', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),

          // 월별 요약 카드
          if (_thisMonthRecords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthlyAnalysisScreen(
                          focusedMonth: _focusedDay,
                          allRecords: _swimRecords,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.bar_chart_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${DateFormat('M월').format(_focusedDay)} 수영 분석',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatColumn(label: '총 수영 거리', value: '${_totalDistanceKm.toStringAsFixed(1)}km'),
                            _StatColumn(label: '총 수영 횟수', value: '$_totalSessions회'),
                            _StatColumn(label: '총 수영 시간', value: _totalDurationStr),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 캘린더
          TableCalendar(
            headerVisible: false,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            calendarFormat: CalendarFormat.month,
            eventLoader: _getEvents,
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date),
              weekendStyle: const TextStyle(color: Colors.blue),
              weekdayStyle: const TextStyle(color: Colors.grey),
            ),
            calendarStyle: const CalendarStyle(outsideDaysVisible: false, markersMaxCount: 0),
            availableGestures: AvailableGestures.horizontalSwipe,
            onPageChanged: (focused) => setState(() { _focusedDay = focused; }),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, _) => _buildDayCell(day),
              todayBuilder: (ctx, day, _) => _buildDayCell(day, isToday: true),
              selectedBuilder: (ctx, day, _) => _buildDayCell(day, isSelected: true),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // 해당 날짜의 수영 기록이 있으면 상세 화면으로 이동
              final recordsOnDay = _swimRecords.where(
                      (r) => isSameDay(r.date, selectedDay));
              if (recordsOnDay.isNotEmpty) {
                final record = recordsOnDay.first;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DailyAnalysisScreen(record: record),
                  ),
                );
              }
            },
          ),

          // 선택일 이벤트 리스트
          Expanded(
            child: ListView.separated(
              itemCount: _getEvents(_selectedDay ?? _focusedDay).length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, idx) {
                final item = _getEvents(_selectedDay ?? _focusedDay)[idx];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.distance} • ${item.time}'),
                  onLongPress: () => _deleteItem(item),
                );
              },
            ),
          ),
        ],
      ),

      // FAB 메뉴
      floatingActionButton: FabMenu(
        isExpanded: _fabExpanded,
        toggle: () => setState(() => _fabExpanded = !_fabExpanded),
        onAction: _onFabAction,
      ),
    );
  }

  void _prevMonth() => setState(() {
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
  });

  void _nextMonth() => setState(() {
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
  });

  void _goToday() => setState(() {
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  });

  void _onFabAction(String label) {
    setState(() => _fabExpanded = false);
    final dateToAdd = _selectedDay ?? _focusedDay;
    switch (label) {
      case '훈련 추가':
        showTrainingInputDialog(context, dateToAdd, _addTraining);
        break;
      case '캘린더 공유':
        showShareDialog(context);
        break;
      case '리스트 삭제':
        final list = List<TrainingItem>.from(_getEvents(dateToAdd));
        showDeleteDialog(context, list, (toDelete) {
          setState(() {
            final key = DateTime.utc(dateToAdd.year, dateToAdd.month, dateToAdd.day);
            _events[key]?.removeWhere((e) => toDelete.contains(e));
            if (_events[key]?.isEmpty ?? false) _events.remove(key);
          });
        });
        break;
      case '미리 일정':
        showPreScheduleDialog(context);
        break;
    }
  }

  void _deleteItem(TrainingItem item) {
    final dayKey = _selectedDay ?? _focusedDay;
    final list = List<TrainingItem>.from(_getEvents(dayKey));
    showDeleteDialog(context, list, (toDelete) {
      setState(() {
        final key = DateTime.utc(dayKey.year, dayKey.month, dayKey.day);
        _events[key]?.removeWhere((e) => toDelete.contains(e));
        if (_events[key]?.isEmpty ?? false) _events.remove(key);
      });
    });
  }

  Widget _buildDayCell(DateTime day, {bool isToday = false, bool isSelected = false}) {
    final events = _getEvents(day);
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.shade100
            : isToday
            ? Colors.blue.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(child: Text('${day.day}', style: TextStyle(color: isSelected ? Colors.blue : Colors.black))),
          if (events.isNotEmpty)
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Row(
                children: events.map((_) => Expanded(child: Container(height: 4, color: Colors.green))).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}