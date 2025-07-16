import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String mateUid;
  final String mateNickname;
  const ChatScreen({Key? key, required this.mateUid, required this.mateNickname}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late final String _chatId;
  late final String _myUid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _myUid = user?.uid ?? '';
    // chatId: 두 uid를 정렬해서 합침 (중복방지)
    final uids = [_myUid, widget.mateUid]..sort();
    _chatId = uids.join('_');
    _createChatIfNotExists();
  }

  Future<void> _createChatIfNotExists() async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    final doc = await chatRef.get();
    if (!doc.exists) {
      await chatRef.set({
        'participants': [_myUid, widget.mateUid],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final msgRef = FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('messages').doc();
    await msgRef.set({
      'sender': _myUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0061A8),
        title: Text(widget.mateNickname, style: const TextStyle(fontFamily: 'MyCustomFont', fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('에러 발생: \n${snapshot.error.toString()}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final msg = docs[i].data() as Map<String, dynamic>;
                    final isMe = msg['sender'] == _myUid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF3A8DFF) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                            fontFamily: 'MyCustomFont',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '메시지 입력',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF0061A8)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F9FB),
    );
  }
} 