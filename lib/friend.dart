import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'qrcode.dart';
import 'button.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

String dog =
    'https://firebasestorage.googleapis.com/v0/b/ibue-183d9.appspot.com/o/profile_images%2Fdog.png?alt=media&token=9d8c0ea4-623a-4310-8ac1-1559e7ebe9cd';
String cat =
    'https://firebasestorage.googleapis.com/v0/b/ibue-183d9.appspot.com/o/profile_images%2Fcat.png?alt=media&token=8cc5db47-d5af-4fe0-98e5-b8a407a483a0';

int randomNumber = Random().nextInt(2) + 1;
String profileuser = (randomNumber == 1) ? cat : dog;

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<String> namereq = [];
  List<String> proreq = [];
  List<String> numreq = [];
  List<String> friend = [];
  List<String> friendPro = [];
  List<String> friendBio = [];
  List<String> friendPhone = [];
  List<int> reqId = [];
  String friendName = '';
  String friendProfile = '';
  bool showDialogs = false;
  bool showWrong = false;
  int searchunique = 0;
  int i = 0;
  int lenreq = 0;
  int iduser = 0;

  Future<int> getId(String userId) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (documentSnapshot.exists) {
        dynamic idFromFirestore = documentSnapshot.get('Id');
        if (idFromFirestore != null) {
          iduser = idFromFirestore as int;
        }
      }
    } catch (e) {
      print('Error Getting data From Firestore $e');
    }
    return iduser;
  }

  void _searchFriend(int? uniqueNumber) async {
    if (uniqueNumber == null) {
      setState(() {
        friendName = 'Invalid Id';
        friendProfile = '';
      });
      return;
    }
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('Id', isEqualTo: uniqueNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> userData =
            querySnapshot.docs[0].data() as Map<String, dynamic>;

        String name = userData['name'] ?? '';
        String profile = userData['profile'] ?? profileuser;

        setState(() {
          friendName = name;
          friendProfile = profile;
        });
      } else {
        setState(() {
          friendName = 'Not Found';
          friendProfile = '';
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<bool> checkIfUniqueNumberExists(int? uniqueNumber) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('Id', isEqualTo: uniqueNumber)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking unique number: $e");
      return false;
    }
  }

  Future<Map<String, List<String>>> getRequest(int iduser) async {
    int i = 0;
    List<int> reqfriend = [];
    List<String> namereq = [];
    List<String> proreq = [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('friendRequest')
        .where('recipientId', isEqualTo: iduser)
        .get();

    querySnapshot.docs.forEach((doc) {
      reqfriend.add(doc['sendId']);
    });
    lenreq = reqfriend.length;
    while (i < lenreq) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('Id', isEqualTo: reqfriend[i])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> userData =
            querySnapshot.docs[0].data() as Map<String, dynamic>;
        namereq.add(userData['name']);
        proreq.add(userData['profile'] ?? profileuser);
        i = i + 1;
      }
    }

    List<String> reqfriendStr = reqfriend.map((e) => e.toString()).toList();

    return {'name': namereq, 'profiles': proreq, 'reqfriend': reqfriendStr};
  }

  Future<Map<String, List<String>>> showFriend() async {
    List<String> friend = [];
    List<String> friendPro = [];
    List<String> friendBio = [];
    List<String> friendPhone = [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        friend.add(userData['name']);
        friendPro.add(userData['profile']);
        friendBio.add(userData['bio']);
        friendPhone.add(userData['phone']);
      }
    }
    return {
      'name': friend,
      'profile': friendPro,
      'bio': friendBio,
      'phone': friendPhone
    };
  }

  Future delFriend(friend, friendPro, friendPhone, friendBio) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .where('name', isEqualTo: friend)
        .where('profile', isEqualTo: friendPro)
        .where('phone', isEqualTo: friendPhone)
        .where('bio', isEqualTo: friendBio)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first;
      String deldoc = doc.id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(deldoc)
          .delete();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(deldoc)
          .collection('friends')
          .doc(userId)
          .delete();
    }
  }

  @override
  void initState() {
    super.initState();
    showFriend().then((value) {
      friend = value['name'] ?? [];
      friendPro = value['profile'] ?? [];
      friendBio = value['bio'] ?? [];
      friendPhone = value['phone'] ?? [];
    });
    getId(userId).then((value) {
      setState(() {
        iduser = value;
        getRequest(iduser).then((value) {
          setState(() {
            namereq = value['name'] ?? [];
            proreq = value['profiles'] ?? [];
            numreq = value['reqfriend'] ?? [];
            lenreq = namereq.length;
          });
        });
      });
    });
  }

  Future<void> refresh() async {}

  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: const Color.fromRGBO(22, 22, 22, 1),
        ),
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: AppBar(
                  backgroundColor: Colors.black,
                  bottom: TabBar(
                      labelColor: Color.fromARGB(255, 100, 255, 242),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      tabs: [
                        Tab(
                            child: Text('Friends',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))),
                        Tab(
                            child: Text('Search',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))),
                        Tab(
                            child: Text('Requests',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)))
                      ])),
            ),
            body: Stack(
              children: [
                TabBarView(children: [
                  Center(
                      child: GridView.count(
                    scrollDirection: Axis.vertical,
                    crossAxisCount: 2,
                    children: List.generate(friend.length, (index) {
                      return Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30)),
                                              backgroundColor:
                                                  Color.fromRGBO(22, 22, 22, 1),
                                              content: Container(
                                                width: 350,
                                                height: 400,
                                                child: Stack(
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          Alignment(-1, -1),
                                                      child: ClipOval(
                                                          child: Image.network(
                                                        friendPro[index],
                                                        fit: BoxFit.cover,
                                                        height: 100,
                                                        width: 100,
                                                      )),
                                                    ),
                                                    Stack(
                                                      children: [
                                                        Align(
                                                          alignment: Alignment(
                                                              -1, -0.4),
                                                          child: Text(
                                                            friend[index],
                                                            style: TextStyle(
                                                              fontSize: 26,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Align(
                                                          alignment: Alignment(
                                                              -1, 0.1),
                                                          child: Text(
                                                            friendBio[index],
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            softWrap: true,
                                                            maxLines: 3,
                                                          ),
                                                        ),
                                                        Align(
                                                          alignment: Alignment(
                                                              -1, -0.2),
                                                          child: Text(
                                                            'Phone: ' +
                                                                friendPhone[
                                                                    index],
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Align(
                                                        alignment:
                                                            Alignment(0.7, 0.7),
                                                        child: SizedBox(
                                                          width: 100,
                                                          height: 45,
                                                          child: ElevatedButton(
                                                              onPressed: () {},
                                                              style: ElevatedButton.styleFrom(
                                                                  splashFactory:
                                                                      NoSplash
                                                                          .splashFactory,
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              15)),
                                                                  backgroundColor:
                                                                      Color.fromRGBO(
                                                                          0,
                                                                          0,
                                                                          0,
                                                                          1)),
                                                              child: Text(
                                                                  'Message',
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight.bold))),
                                                        )),
                                                    Align(
                                                        alignment: Alignment(
                                                            -0.7, 0.7),
                                                        child: Container(
                                                            decoration: BoxDecoration(
                                                                border: Border.all(
                                                                    color: Colors
                                                                        .red),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            15)),
                                                            child: SizedBox(
                                                              width: 100,
                                                              height: 45,
                                                              child:
                                                                  ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        showDialog(
                                                                            context:
                                                                                context,
                                                                            builder: (context) =>
                                                                                AlertDialog(
                                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                                                                  backgroundColor: Color.fromRGBO(112, 128, 144, 1),
                                                                                  content: Container(
                                                                                    width: 250,
                                                                                    height: 120,
                                                                                    child: Stack(children: [
                                                                                      Align(
                                                                                        alignment: Alignment(0, -1),
                                                                                        child: Text('Are you sure you want to unfriend ' + friend[index] + ' ?', style: TextStyle(color: Colors.white)),
                                                                                      ),
                                                                                      Align(
                                                                                          alignment: Alignment(1, 1),
                                                                                          child: SizedBox(
                                                                                            width: 80,
                                                                                            height: 40,
                                                                                            child: ElevatedButton(
                                                                                              onPressed: () {
                                                                                                delFriend(friend[index], friendPro[index], friendPhone[index], friendBio[index]);
                                                                                                Navigator.pop(context);
                                                                                                Navigator.pop(context);
                                                                                                setState(() {});
                                                                                              },
                                                                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                                                                                              child: Text('Yes'),
                                                                                            ),
                                                                                          )),
                                                                                      Align(
                                                                                          alignment: Alignment(0, 1),
                                                                                          child: SizedBox(
                                                                                            width: 80,
                                                                                            height: 40,
                                                                                            child: ElevatedButton(
                                                                                              onPressed: () {
                                                                                                Navigator.pop(context);
                                                                                              },
                                                                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                                                                                              child: Text('No'),
                                                                                            ),
                                                                                          ))
                                                                                    ]),
                                                                                  ),
                                                                                ));
                                                                      },
                                                                      style: ElevatedButton.styleFrom(
                                                                          splashFactory: NoSplash
                                                                              .splashFactory,
                                                                          shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(
                                                                                  15)),
                                                                          backgroundColor: Colors
                                                                              .transparent),
                                                                      child:
                                                                          Text(
                                                                        'Unfriend',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.red,
                                                                            fontWeight: FontWeight.bold),
                                                                      )),
                                                            )))
                                                  ],
                                                ),
                                              ),
                                            ));
                                  },
                                  style: ElevatedButton.styleFrom(
                                      primary: Color.fromRGBO(0, 0, 0, 1),
                                      splashFactory: NoSplash.splashFactory,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30))),
                                  child: Stack(children: [
                                    Align(
                                      alignment: Alignment(0, 0.5),
                                      child: Text(
                                        friend[index],
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment(0, -0.6),
                                      child: ClipOval(
                                        child: Image.network(
                                          friendPro[index],
                                          fit: BoxFit.cover,
                                          height: 70,
                                          width: 70,
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  )),
                  Center(
                    child: Stack(
                      children: [
                        Align(
                            alignment: Alignment(0, 0.9),
                            child: SizedBox(
                                width: 400,
                                height: 700,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(22, 22, 22, 1),
                                    borderRadius: BorderRadius.circular(0),
                                  ),
                                ))),
                        Scaffold(
                          resizeToAvoidBottomInset: false,
                          body: SingleChildScrollView(
                            padding: EdgeInsets.only(top: 120),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment(-0.8, -0.58),
                                  child: SizedBox(
                                      width: 280,
                                      height: 40,
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                                color: Color.fromRGBO(
                                                    255, 255, 255, 1),
                                                borderRadius:
                                                    BorderRadius.circular(60)),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 11, vertical: 8),
                                              child: TextField(
                                                onChanged: (text) {
                                                  setState(() {});
                                                },
                                                controller: _searchController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_searchController.text.isEmpty)
                                            Positioned(
                                                top: 10,
                                                left: 10,
                                                child: Text('Search Id',
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16))),
                                        ],
                                      )),
                                ),
                                Align(
                                    alignment: Alignment(0.89, -0.58),
                                    child: SizedBox(
                                      width: 80,
                                      height: 41,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          String uniqueNumberStr =
                                              _searchController.text.trim();
                                          if (uniqueNumberStr.isNotEmpty) {
                                            int? uniqueNumber =
                                                int.tryParse(uniqueNumberStr);

                                            bool isValiduniqueNumber =
                                                await checkIfUniqueNumberExists(
                                                    uniqueNumber);

                                            if (isValiduniqueNumber) {
                                              _searchFriend(uniqueNumber);

                                              setState(() {
                                                searchunique = int.tryParse(
                                                        uniqueNumberStr) ??
                                                    0;
                                                showDialogs = true;
                                                showWrong = false;
                                              });
                                            } else {
                                              showDialogs = false;
                                              showWrong = true;
                                            }
                                          } else {
                                            setState(() {
                                              showDialogs = false;
                                              showWrong = true;
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(60)),
                                          backgroundColor:
                                              Color.fromRGBO(0, 0, 0, 1),
                                        ),
                                        child: const Image(
                                            image: AssetImage('search.png')),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                        if (showDialogs)
                          Padding(
                              padding: EdgeInsets.only(top: 200, left: 20),
                              child: SizedBox(
                                  width: 350,
                                  height: 100,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color:
                                                Color.fromRGBO(44, 44, 44, 1),
                                            borderRadius:
                                                BorderRadius.circular(15)),
                                      ),
                                      Align(
                                        alignment: Alignment(-0.9, 0),
                                        child: SizedBox(
                                            width: 90,
                                            height: 90,
                                            child: Stack(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              60),
                                                      color: Color.fromRGBO(
                                                          0, 0, 0, 1)),
                                                ),
                                                if (friendProfile.isNotEmpty)
                                                  Positioned(
                                                      child: ClipOval(
                                                    child: Image.network(
                                                      friendProfile,
                                                      height: 90,
                                                      width: 90,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )),
                                              ],
                                            )),
                                      ),
                                      Align(
                                          alignment: Alignment(0, -0.7),
                                          child: Text('$friendName',
                                              style: TextStyle(
                                                  color: const Color.fromARGB(
                                                      255, 255, 255, 255),
                                                  fontSize: 20,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Align(
                                        alignment: Alignment(0.8, -0.19),
                                        child: SizedBox(
                                            height: 60,
                                            width: 60,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                int iduser =
                                                    await getId(userId);
                                                ButtonRespon().sendRequest(
                                                    iduser, searchunique);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15)),
                                                  backgroundColor:
                                                      Color.fromRGBO(
                                                          0, 0, 0, 1)),
                                              child: const Image(
                                                  image: AssetImage(
                                                      'addfriend.png')),
                                            )),
                                      ),
                                    ],
                                  ))),
                        if (showWrong)
                          Padding(
                            padding: EdgeInsets.only(top: 300),
                            child: SingleChildScrollView(
                                child: Align(
                              alignment: Alignment(0, 0),
                              child: Text(
                                'Invalid Id',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold),
                              ),
                            )),
                          ),
                        SingleChildScrollView(
                          padding: EdgeInsets.only(top: 35),
                          child: Stack(
                            children: [
                              Align(
                                  alignment: Alignment(0.45, -0.88),
                                  child: SizedBox(
                                      width: 65,
                                      height: 65,
                                      child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CallQRScreen(),
                                                ));
                                          },
                                          style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                              backgroundColor:
                                                  Color.fromRGBO(0, 0, 0, 1)),
                                          child: const Image(
                                              image:
                                                  AssetImage('qrcode.png'))))),
                              Align(
                                alignment: Alignment(-0.8, -0.85),
                                child: SizedBox(
                                  child: Text(
                                    'ID: $iduser',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Align(
                                  alignment: Alignment(0.9, -0.88),
                                  child: SizedBox(
                                      width: 65,
                                      height: 65,
                                      child: ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                              backgroundColor:
                                                  Color.fromRGBO(0, 0, 0, 1)),
                                          child: const Image(
                                              image: AssetImage(
                                                  'qrcodescan.png'))))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: ListView.builder(
                      itemCount: lenreq,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 380,
                              height: 120,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                    ),
                                  ),
                                  Align(
                                      alignment: Alignment(-0.9, 0),
                                      child: ClipOval(
                                        child: Image.network(
                                          proreq[index],
                                          fit: BoxFit.cover,
                                          height: 90,
                                          width: 90,
                                        ),
                                      )),
                                  Align(
                                    alignment: Alignment(-0.1, -0.6),
                                    child: Text(
                                      namereq[index],
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment(0.8, -0.6),
                                    child: ElevatedButton(
                                      child: Text(
                                        'Accept',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(45)),
                                          backgroundColor: Colors.green[300]),
                                      onPressed: () async {
                                        List<int> reqId = numreq
                                            .map((e) => int.parse(e))
                                            .toList();
                                        String requestId = await ButtonRespon()
                                            .sendRequest(reqId[index], iduser);
                                        ButtonRespon().acceptFriend(requestId);
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment(0.8, 0.7),
                                    child: ElevatedButton(
                                      child: Text('Ignore',
                                          style: TextStyle(fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Color.fromRGBO(0, 0, 0, 0),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(60))),
                                      onPressed: () async {
                                        List<int> reqId = numreq
                                            .map((e) => int.parse(e))
                                            .toList();
                                        String requestId = await ButtonRespon()
                                            .sendRequest(reqId[index], iduser);
                                        ButtonRespon()
                                            .deleteFriendRequest(requestId);
                                        setState(() {});
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ));
  }
}
