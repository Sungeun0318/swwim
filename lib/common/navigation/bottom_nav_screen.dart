import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart'; // 새로운 홈 화면
import '../calendar/calendar_screen.dart';
import '../notifications/notification_screen.dart';
import '../community/screens/community_screen.dart';
import '../more/more_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({Key? key}) : super(key: key);

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 2; // 기본적으로 홈 화면(가운데)이 선택되도록 설정

  final List<Widget> _screens = [
    const CalendarScreen(),    // 기록
    const CommunityScreen(),   // 커뮤니티
    const HomeScreen(),        // 홈 (새로운 Swimming Starter 디자인)
    const NotificationScreen(), // 알림
    const MoreScreen(),        // 설정
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.blue.shade600,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            items: [
              // 기록 (캘린더)
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 0
                      ? BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  )
                      : null,
                  child: Icon(
                    _selectedIndex == 0 ? Icons.calendar_today : Icons.calendar_today_outlined,
                    size: 24,
                  ),
                ),
                label: "기록",
              ),
              // 커뮤니티
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 1
                      ? BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  )
                      : null,
                  child: Icon(
                    _selectedIndex == 1 ? Icons.people : Icons.people_outline,
                    size: 24,
                  ),
                ),
                label: "커뮤니티",
              ),
              // 홈
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 2
                      ? BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  )
                      : null,
                  child: Icon(
                    _selectedIndex == 2 ? Icons.home : Icons.home_outlined,
                    size: 28, // 홈 아이콘을 조금 더 크게
                  ),
                ),
                label: "홈",
              ),
              // 알림
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 3
                      ? BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  )
                      : null,
                  child: Icon(
                    _selectedIndex == 3 ? Icons.notifications : Icons.notifications_outlined,
                    size: 24,
                  ),
                ),
                label: "알림",
              ),
              // 설정
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 4
                      ? BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  )
                      : null,
                  child: Icon(
                    _selectedIndex == 4 ? Icons.settings : Icons.settings_outlined,
                    size: 24,
                  ),
                ),
                label: "설정",
              ),
            ],
          ),
        ),
      ),
    );
  }
}