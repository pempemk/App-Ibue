import 'package:flutter/material.dart';
import 'package:ibue/friend.dart';
import 'package:ibue/map.dart';
import 'firestore.dart';
import 'main.dart';
import 'package:ibue/generatecode.dart';

class ProfilePage extends StatelessWidget {
  final DataPerAccount _dataPerAccount = DataPerAccount();
  final TextEditingController _nicknameController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(labelText: 'UserName'),
            ),
            ElevatedButton(
              onPressed: () async {
                int uniquenum = await uniqueAndCheck();
                String nickname = _nicknameController.text.trim();
                String userId = _authService.getCurrentUserId();
                await _dataPerAccount.createUsersDocument(
                    userId, nickname, uniquenum, profileuser);

                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(),
                    ));
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
