import 'package:college/Auth/AuthFunctions.dart';
import 'package:college/Database/Database.dart';
import 'package:college/SuperAdmin/CreateUserPage.dart';
import 'package:college/SuperAdmin/DeleteUserPage.dart';
import 'package:college/SuperAdmin/Department.dart';
import 'package:college/SuperAdmin/ReportPage.dart';
import 'package:college/SuperAdmin/UpdateRolePage.dart';
import 'package:college/SuperAdmin/changepasswordapp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() => runApp(SuperAdmin());

class SuperAdmin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Super Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SuperAdminHomePage(),
    );
  }
}

class SuperAdminHomePage extends StatefulWidget {
  @override
  _SuperAdminHomePageState createState() => _SuperAdminHomePageState();
}

class _SuperAdminHomePageState extends State<SuperAdminHomePage> {
  String? currentUsername;

  @override
  void initState() {
    _fetchCurrentUser();
    super.initState();
  }

  Future<String?> _getUserName(String? email) async {
    try {
      if (email == null) return null;

      List<Map<String, dynamic>> users = await DatabaseMethods().getUser();
      for (var user in users) {
        if (user['mailId'] == email) {
          return user['name'];
        }
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
    return null;
  }

  Future<void> _fetchCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? username = await _getUserName(user.email);
        if (mounted) {
          setState(() {
            currentUsername = username;
          });
        }
      }
    } catch (e) {
      print('Error fetching current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${currentUsername ?? 'User'}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildGridButton(
                    icon: Icons.home,
                    label: 'Department',
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DepartmentPage()));
                    },
                  ),
                  _buildGridButton(
                    icon: Icons.person_add,
                    label: 'Create Users',
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Createuser()));
                    },
                  ),
                  _buildGridButton(
                    icon: Icons.person_remove,
                    label: 'Delete Users',
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>DeleteUserScreen()));
                    },
                  ),
                  _buildGridButton(
                    icon: Icons.report,
                    label: 'Report',
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Superadminreport()));
                    },
                  ),
                  _buildGridButton(
                    icon: Icons.lock,
                    label: 'Change Password',
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChangePasswordApp()));
                    },
                  ),
                  _buildGridButton(
                    icon: Icons.update,
                    label: 'Update Role',
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UpdateRoleApp()));
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  AuthServices.logout(context);
                },
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridButton({
    required IconData icon,
    required String label,
    required Function onTap,
  }) {
    return ElevatedButton(
      onPressed: () => onTap(),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Colors.grey, width: 1),
        ),
        elevation: 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50),
          SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: MediaQuery.of(context).textScaleFactor * 16),
          ),
        ],
      ),
    );
  }
}
