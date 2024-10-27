import 'package:college/Admin/adminPage.dart';
import 'package:college/Incharge/incharge.dart';
import 'package:college/SuperAdmin/superadmin.dart';
import 'package:college/User/userpage.dart';
import 'package:college/Auth/LoginPage.dart';
import 'package:college/Database/Database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'College Management Login',
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // If the user is authenticated, fetch the user role
            return FutureBuilder<String?>(
              future: _getUserRole(FirebaseAuth.instance.currentUser!.email),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  String? role = snapshot.data;
                  // Navigate based on the role
                  switch (role) {
                    case 'A':
                      return Adminpage();
                    case 'SA':
                      return SuperAdmin();
                    case 'I':
                      return Incharge();
                    case 'U':
                      return Userpage();
                    default:
                      return LoginPage();
                  }
                } else {
                  return LoginPage();
                }
              },
            );
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }

  //Getting user Role
  Future<String?> _getUserRole(String? email) async {
    try {
      if (email == null) return null;
      List<Map<String, dynamic>> users = await DatabaseMethods().getUser();
      for (var user in users) {
        if (user['mailId'] == email) {
          return user['role'];
        }
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
    return null;
  }
}
