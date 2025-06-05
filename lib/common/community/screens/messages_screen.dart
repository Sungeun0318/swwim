import 'package:flutter/material.dart';

/// 메시지(DM) 화면
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('메시지')), body: const Center(child: Text('DM 기능 구현 예정')));
  }
}