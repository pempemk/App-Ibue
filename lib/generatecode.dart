import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

int uniqueNumber() {
  final Random random = Random();
  const int codeLength = 8;

  //Generate number
  int randomNumber = 0;
  for (int i = 0; i < codeLength; i++) {
    randomNumber = randomNumber * 10 + random.nextInt(10);
  }

  return randomNumber;
}

Future<int> uniqueAndCheck() async {
  int number = 0;
  bool isUnique = false;

  while (!isUnique) {
    number = uniqueNumber();

    //Check if the generate number already in the database
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('Id', isEqualTo: number)
        .get();

    if (querySnapshot.size == 0) {
      isUnique = true;
    }
  }

  return number;
}
