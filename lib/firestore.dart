import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getNickname(String userId) async {
    try {
      final snapshot = await _firestore.collection('users').doc(userId).get();
      if (snapshot.exists) {
        return snapshot.data()?['name'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving nickname: $e');
      return null;
    }
  }
}

class DataPerAccount {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> createUsersDocument(
      String userId, String nickname, int uniquenum, String profile) async {
    try {
      await usersCollection.doc(userId).set({
        'name': nickname,
        'Id': uniquenum,
        'profile': profile,
        'bio': '',
        'phoneNumber': '',
        'latitude': '',
        'longtitude': ''
      });
    } catch (error) {
      print('Error creating user document: $error');
    }
  }
}
