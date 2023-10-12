import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ibue/firestore.dart';
import 'package:ibue/friend.dart';
import 'package:ibue/generatecode.dart';
import 'package:ibue/map.dart';
import 'package:ibue/profile.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(LoginApp());
}

//หน้าLogin =====================================================================

class LoginApp extends StatelessWidget {
  // This widget is the root of your application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: AuthService().handleAuthState(),
    );
  }
}

class AuthService {
  String getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      throw Exception('User is not authenticated');
    }
  }

  //Deteermine if the user is authenticated
  StreamBuilder<User?> handleAuthState() {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<String?>(
              future: FirestoreService().getNickname(snapshot.data!.uid),
              builder: (context, AsyncSnapshot<String?> nicknamesnapshot) {
                if (nicknamesnapshot.hasData && nicknamesnapshot.data != null) {
                  return MapScreen();
                } else {
                  return ProfilePage();
                }
              },
            );
          } else {
            return LoginPage();
          }
        });
  }

  signInWithGoogle(BuildContext context) async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser =
        await GoogleSignIn(scopes: <String>["email"]).signIn(); //GoogleSignIn

    // Obtain The auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential authResult =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final String userId = authResult.user!.uid;

    if (authResult.additionalUserInfo?.isNewUser == true) {
      final User user = authResult.user!;
      int uniquenum = await uniqueAndCheck();
      await DataPerAccount().createUsersDocument(
          userId, user.displayName ?? 'No name', uniquenum, profileuser);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(),
          ));
    }

    // Once signed in return the UserCredential
    return authResult;
  }

  // Sign out
  signOut() {
    FirebaseAuth.instance.signOut();
  }
}

// Login =======================================================================

