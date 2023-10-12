import 'package:cloud_firestore/cloud_firestore.dart';

class ButtonRespon {
  sendRequest(int usernum, int friendnum) async {
    String requestId = '$usernum-$friendnum';

    await FirebaseFirestore.instance
        .collection('friendRequest')
        .doc(requestId)
        .set({
      'sendId': usernum,
      'recipientId': friendnum,
      'status': 'pending',
    });
    return requestId;
  }

  void acceptFriend(String requestId) async {
    DocumentSnapshot requestSnapshot = await FirebaseFirestore.instance
        .collection('friendRequest')
        .doc(requestId)
        .get();

    if (requestSnapshot.exists) {
      int usernum = requestSnapshot['sendId'];
      int friendnum = requestSnapshot['recipientId'];

      await addFriend(usernum, friendnum);
      await addFriend(friendnum, usernum);
      await deleteFriendRequest(requestId);
    } else {
      print('Document does not exist ');
    }
  }

  Future<void> addFriend(int userIds, int friendId) async {
    Future getsenddoc() async {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('Id', isEqualTo: userIds)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        String sendDoc = doc.id;
        return sendDoc;
      }
    }

    Future getRecipientdoc() async {
      QuerySnapshot querySnapshot2 = await FirebaseFirestore.instance
          .collection('users')
          .where('Id', isEqualTo: friendId)
          .get();
      if (querySnapshot2.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot2.docs.first;
        String recipientDoc = doc.id;
        return recipientDoc;
      }
    }

    String? sendDoc = await getsenddoc();
    String? recipientDoc = await getRecipientdoc();

    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(recipientDoc)
        .get();

    String friendName = userSnapshot['name'];
    String friendPro = userSnapshot['profile'];
    String friendBio = userSnapshot['bio'];
    String friendPhone = userSnapshot['phone'];
    double friendLong = userSnapshot['longtitude'];
    double friendLa = userSnapshot['latitude'];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(sendDoc)
        .collection('friends')
        .doc(recipientDoc)
        .set({
      'name': friendName,
      'profile': friendPro,
      'bio': friendBio,
      'phone': friendPhone,
      'longtitude': friendLong,
      'latitude': friendLa
    });
  }

  Future<void> deleteFriendRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('friendRequest')
        .doc(requestId)
        .delete();
  }
}
