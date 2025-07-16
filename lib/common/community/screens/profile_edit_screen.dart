import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
      String nickname = data['nickname'] ?? '';
      if (nickname.isEmpty && user.email != null) {
        nickname = user.email!.split('@')[0];
      }
      _nicknameController.text = nickname;
      _bioController.text = data['bio'] ?? '';
      _interests = List<String>.from(data['interests'] ?? []);
      _avatarUrl = data['avatarUrl'] ?? _avatarUrl;
    } else if (user.email != null) {
      // Firestore에 문서가 없고, 이메일이 있으면 이메일 앞부분을 닉네임으로
      _nicknameController.text = user.email!.split('@')[0];
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

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final ref = FirebaseStorage.instance.ref().child('avatars/${FirebaseAuth.instance.currentUser!.uid}');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      setState(() {
        _avatarUrl = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = 120;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // 커스텀 AppBar
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('취소', style: TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black)),
                        ),
                        const Text('프로필 편집', style: TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.w900, fontSize: 32, color: Colors.black, letterSpacing: 1.5, shadows: [Shadow(color: Colors.white, offset: Offset(2,2), blurRadius: 0)])),
                        GestureDetector(
                          onTap: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              await _saveProfile();
                            }
                          },
                          child: const Text('완료', style: TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.w900, fontSize: 22, color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 프로필 이미지 + 오버레이
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B94A3),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: _avatarUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.network(_avatarUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.person, size: avatarSize * 0.6, color: Colors.white)),
                                  )
                                : Icon(Icons.person, size: avatarSize * 0.6, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 10, right: 10,
                          child: GestureDetector(
                            onTap: _pickAndUploadImage,
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                              ),
                              child: const Icon(Icons.add, size: 32, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                        children: [
                          // 아이디
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('아이디', style: TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black)),
                              const SizedBox(width: 32),
                              Expanded(
                                child: TextFormField(
                                  controller: _nicknameController,
                                  style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 28, fontWeight: FontWeight.w400, color: Colors.black, letterSpacing: 2),
                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                  validator: (v) => v!.isEmpty ? '아이디를 입력하세요' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // 소개
                          const Text('소개', style: TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E5E5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _bioController,
                              style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 20, color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: '자기소개를 입력하세요',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(18),
                              ),
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // 카테고리
                          const Text('카테고리', style: TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E5E5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: _interests.map((interest) => Chip(
                                    label: Text(interest, style: const TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.w700, fontSize: 16)),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    onDeleted: () => setState(() => _interests.remove(interest)),
                                  )).toList(),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _interestController,
                                        style: const TextStyle(fontFamily: 'MyCustomFont', fontSize: 18, color: Colors.black),
                                        decoration: const InputDecoration(
                                          hintText: '카테고리 추가',
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        onSubmitted: (_) => _addInterest(),
                                      ),
                                    ),
                                    IconButton(icon: const Icon(Icons.add, size: 28), onPressed: _addInterest),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 