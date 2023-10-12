import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CallQRScreen extends StatefulWidget {
  @override
  _CallQRScreenState createState() => _CallQRScreenState();
}

class _CallQRScreenState extends State<CallQRScreen> {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int uniqueQR = 0;
  String uniqueQRStr = '';

  Future<void> uniqueuser(String userId) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (documentSnapshot.exists) {
        dynamic idFromFirestore = documentSnapshot.get('Id');
        if (idFromFirestore != null) {
          setState(() {
            uniqueQR = idFromFirestore as int;
            uniqueQRStr = uniqueQR.toString();
          });
        }
      }
    } catch (e) {
      print('Error getting data from FireStore $e');
    }
  }

  @override
  void initState() {
    super.initState();
    uniqueuser(userId);
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('QR Code'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
            ),
            QrImageView(
              data: uniqueQRStr,
              version: QrVersions.auto,
              size: 200,
            ),
          ],
        )));
  }
}
