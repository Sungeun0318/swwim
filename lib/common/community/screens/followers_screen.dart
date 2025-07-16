import 'package:flutter/material.dart';

class FollowersScreen extends StatelessWidget {
  const FollowersScreen({Key? key}) : super(key: key);

  @override Widget build(BuildContext context) {
    final followers = ['user1','user2','user3'];
    return Scaffold(
      appBar: AppBar(title: const Text('팔로우/팔로잉')),
      body: ListView.builder(itemCount: followers.length, itemBuilder: (ctx,i)=>ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(followers[i]),
      )),
    );
  }
}
