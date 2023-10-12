import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:ibue/friend.dart';
import 'edit_profile.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<num> locationFriendslong = [];
  Set<Marker> markers = {};
  List<num> locationFriendslat = [];
  List<double> locationlong = [];
  List<double> locationlat = [];
  late GoogleMapController mapController;
  Position? currentPosition;
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  Timer? _timer;
  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;

  Future<Map<String, List<num>>> getLocationFriend() async {
    List<num> locationFriendslong = [];
    List<num> locationFriendslat = [];

    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .get();
    if (userSnapshot.docs.isNotEmpty) {
      for (var doc in userSnapshot.docs) {
        Map<String, dynamic> usersData = doc.data() as Map<String, dynamic>;
        locationFriendslong.add(usersData['longtitude']);
        locationFriendslat.add(usersData['latitude']);
      }
    }
    return {'long': locationFriendslong, 'la': locationFriendslat};
  }

  Future updata() async {
    List<String> docAll = [];
    Future getAllDoc() async {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (QueryDocumentSnapshot<Map<String, dynamic>> docSnapshot
          in querySnapshot.docs) {
        docAll.add(docSnapshot.id);
        await docAll.remove(userId);
      }
      return docAll;
    }

    docAll = await getAllDoc();

    DocumentSnapshot<Map<String, dynamic>> doc1Snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (doc1Snapshot.exists) {
      int i = 0;
      Map<String, dynamic> data = doc1Snapshot.data()!;
      while (i < docAll.length) {
        DocumentReference<Map<String, dynamic>> doc3Ref = FirebaseFirestore
            .instance
            .collection('users')
            .doc(docAll[i])
            .collection('friends')
            .doc(userId);

        await doc3Ref.set(data);
        i = i + 1;
      }
    } else {
      print('doc1 does not exist');
    }
  }

  //GPS-------------------------------------------------------------------------

  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(
              devicePixelRatio: 1.0,
            ),
            'mylocation.png')
        .then((icon) {
      sourceIcon = icon;
    });
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.0, size: Size(16, 16)),
            'cat.png')
        .then((icon) {
      destinationIcon = icon;
    });
  }

  void setMarker(List<double> locationlat, List<double> locationlong) {
    for (int index = 0; index < locationlat.length; index++) {
      Marker marker = Marker(
          markerId: MarkerId('mark1'),
          icon: BitmapDescriptor.defaultMarker,
          position: LatLng(locationlat[index], locationlong[index]));
      Marker mymarker = Marker(
          markerId: MarkerId('mark2'),
          icon: destinationIcon,
          position:
              LatLng(currentPosition!.latitude, currentPosition!.longitude));
      markers.add(marker);
      markers.add(mymarker);
      print('Add marker $index');
    }
  }

  @override
  void initState() {
    super.initState();
    setCustomMarkerIcon();
    getLocation();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'latitude': currentPosition!.latitude,
        'longtitude': currentPosition!.longitude
      });
      updata();
      getLocationFriend().then(
        (value) {
          List<double> locationlong = (value['long'] as List?)
                  ?.map((e) => (e as double).toDouble())
                  .toList() ??
              [];
          List<double> locationlat = (value['la'] as List?)
                  ?.map((e) => (e as double).toDouble())
                  .toList() ??
              [];

          setMarker(locationlat, locationlong);
          setState(() {});
        },
      );
      mylocation();
    });
  }

  void getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      // Handle permission denied
      return;
    } else if (permission == LocationPermission.deniedForever) {
      // Handle permission permanently denied
      return;
    } else {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = position;
      });
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 18)));
    }
  }

  void mylocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentPosition = position;
    });
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 18)));
  }

  //GPS-------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: currentPosition != null
                  ? CameraPosition(
                      target: LatLng(currentPosition!.latitude,
                          currentPosition!.longitude),
                      zoom: 12.0,
                    )
                  : CameraPosition(
                      target: LatLng(13.736717, 100.523186),
                    ),
              gestureRecognizers: Set()
                ..add(Factory<OneSequenceGestureRecognizer>(
                    () => ScaleGestureRecognizer())),
              zoomControlsEnabled: false,
              markers: markers,
            ),
          ),
          Align(
            alignment: Alignment(0, 0.9),
            child: SizedBox(
              width: 75,
              height: 75,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    backgroundColor: Colors.black),
                child: const Image(image: AssetImage('message.png')),
              ),
            ),
          ),
          Align(
              alignment: Alignment(0.55, 0.9),
              child: SizedBox(
                  width: 65,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchScreen(),
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        backgroundColor: Colors.black87),
                    child: const Image(image: AssetImage('friend.png')),
                  ))),
          Align(
              alignment: Alignment(-0.55, 0.9),
              child: SizedBox(
                  width: 65,
                  height: 65,
                  child: ElevatedButton(
                      onPressed: () {
                        mylocation();
                      },
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          backgroundColor: Colors.black),
                      child:
                          const Image(image: AssetImage('mylocation.png'))))),
          Align(
              alignment: Alignment(0.9, -0.9),
              child: SizedBox(
                  width: 50,
                  height: 40,
                  child: ElevatedButton(
                      onPressed: () {
                        // action
                      },
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.black),
                      child: const Image(image: AssetImage('settings.png'))))),
          Align(
              alignment: Alignment(0.9, -0.76),
              child: SizedBox(
                  width: 50,
                  height: 40,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(),
                            ));
                      },
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.black),
                      child: const Image(image: AssetImage('profile.png')))))
        ],
      ),
    );
  }
}
