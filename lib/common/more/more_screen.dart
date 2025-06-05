import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swim/features/login/screens/login_sc.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoLogin', false); // 자동 로그인 해제
    await FirebaseAuth.instance.signOut(); // Firebase 로그아웃

    // 로그인 화면으로 이동 (뒤로가기 방지)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: ListView(
        children: [
          // 정보 수정 제안하기
          ListTile(
            title: const Text('정보 수정 제안하기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 원하는 기능 연결
            },
          ),

          // 앱 설정
          _buildSectionTitle('앱 설정'),
          ListTile(
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 알림 설정 화면 이동
            },
          ),

          // 약관 및 정책
          _buildSectionTitle('약관 및 정책'),
          ListTile(
            title: const Text('이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 이용약관 화면 이동
            },
          ),
          ListTile(
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 개인정보 처리방침 화면 이동
            },
          ),

          // 계정 관리
          _buildSectionTitle('계정 관리'),
          ListTile(
            title: const Text('로그아웃'),
            onTap: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );
              if (result == true) {
                await _logout(context);
              }
            },
          ),
          ListTile(
            title: const Text('비밀번호 변경하기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 비밀번호 변경 화면 이동
            },
          ),
          ListTile(
            title: const Text('계정 탈퇴하기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 계정 탈퇴 화면 이동
            },
          ),

          const SizedBox(height: 20),
          const Center(
            child: Text(
              '버전정보 1.1.1',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
