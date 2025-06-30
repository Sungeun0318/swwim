import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);
  @override _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestController = TextEditingController();
  List<String> _interests = [];
  bool _isLoading = true;
  String _avatarUrl = 'https://i.pravatar.cc/150?img=50';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nicknameController.text = data['nickname'] ?? '';
      _bioController.text = data['bio'] ?? '';
      _interests = List<String>.from(data['interests'] ?? []);
      _avatarUrl = data['avatarUrl'] ?? _avatarUrl;
    }
    setState(() => _isLoading = false);
  }

  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
        _interestController.clear();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'nickname': _nicknameController.text,
        'bio': _bioController.text,
        'interests': _interests,
        'avatarUrl': _avatarUrl,
        'uid': user.uid,
      }, SetOptions(merge: true));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('프로필 저장 실패: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 편집')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(radius: 50, backgroundImage: NetworkImage(_avatarUrl)),
                        Positioned(bottom: 0, right: 0, child: IconButton(icon: const Icon(Icons.camera_alt), onPressed: () {/* TODO: 이미지 변경 로직 */})),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(labelText: '닉네임'),
                    validator: (v) => v!.isEmpty ? '닉네임을 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: '자기소개'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text('관심사', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8.0,
                    children: _interests.map((interest) => Chip(
                      label: Text(interest),
                      onDeleted: () => setState(() => _interests.remove(interest)),
                    )).toList(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _interestController,
                          decoration: const InputDecoration(hintText: '관심사 추가'),
                          onSubmitted: (_) => _addInterest(),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.add), onPressed: _addInterest),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
    );
  }
} 