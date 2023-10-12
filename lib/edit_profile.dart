import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  File? _profileImage;
  TextEditingController _nicknameController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _aboutMeController = TextEditingController();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    // Fetch user data from Firestore when the page is loaded
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final userData = await _firestore.collection('users').doc(userId).get();
        if (userData.exists) {
          setState(() {
            _nicknameController.text = userData['name'];
            _phoneNumberController.text = userData['phone'] ?? '';
            _aboutMeController.text = userData['bio'];
            _profileImageUrl = userData['profile'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_profileImage == null) return;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child(userId);
        await ref.putFile(_profileImage!);

        final downloadUrl = await ref.getDownloadURL();
        await _firestore.collection('users').doc(userId).update({
          'profile': downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });
      }
    } catch (e) {
      print('Error uploading profile image: $e');
    }
  }

  Future<void> _updateProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'name': _nicknameController.text,
          'phone': _phoneNumberController.text,
          'bio': _aboutMeController.text,
        });
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_profileImageUrl != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_profileImageUrl!),
              ),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Change Profile Picture'),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nicknameController,
              onChanged: (value) {},
              decoration: InputDecoration(
                labelText: 'Nickname',
                hintText: 'Enter your nickname',
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _phoneNumberController,
              onChanged: (value) {},
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: 'Enter your phone number',
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _aboutMeController,
              onChanged: (value) {},
              decoration: InputDecoration(
                labelText: 'Bio',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _uploadImageToFirebase();
                await _updateProfile();
                Navigator.pop(context);
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
