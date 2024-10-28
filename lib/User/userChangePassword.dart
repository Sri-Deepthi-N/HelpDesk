import 'package:college/Database/Database.dart';
import 'package:college/User/userpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() => runApp(Userchangepassword());

class Userchangepassword extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Change Password',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChangePasswordPage(),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _retypeNewPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  User? currentUser;
  bool isLoading = false;
  List<Map<String, dynamic>> _users = [];
  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    setState(() {
      currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  Future<void> _fetchUsers() async {
    try {
      List<Map<String, dynamic>> users = await DatabaseMethods().getUser();
      setState(() {
        _users = users;
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> _changePasswordindb() async {
    if (_newPasswordController.text != null) {
      setState(() {
        isLoading = true;
      });
      Map<String, dynamic> updatedPassword = {
        'password': _newPasswordController.text,
      };
      await _fetchUsers();

      try {
        var user = _users.firstWhere((user) => user['mailId'] == currentUser!.email);
        await DatabaseMethods().updateUser(user['uid'], updatedPassword);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password.')),
      );
    }
  }



  String? _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (password.length < 8 || password.length > 15) {
      return 'Password must be between 8 and 15 characters';
    }
    if (!RegExp(r'^(?=.*[A-Z])').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password)) {
      return 'Password must contain both letters and numbers';
    }
    if (!RegExp(r'^(?=.*[!@#\$&*~])').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text == _retypeNewPasswordController.text) {
        if (_newPasswordController.text == _oldPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                'New password cannot be the same as old password.')),
          );
          return;
        }
        await _checkOldPassword();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New passwords do not match')),
        );
      }
    }
  }

  Future<void> _checkOldPassword() async {
    try {
      if (currentUser != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: _oldPasswordController.text,
        );
        await currentUser!.reauthenticateWithCredential(credential);
        await currentUser!.updatePassword(_newPasswordController.text);
        await _changePasswordindb();
        _handleClear();
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => Userpage()));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password changed successfully!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'wrong-password':
          message = 'The old password is incorrect.';
          break;
        case 'weak-password':
          message = 'The new password is too weak.';
          break;
        case 'requires-recent-login':
          message = 'Please reauthenticate to change your password.';
          break;
        default:
          message = e.message ?? message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleClear() {
    _newPasswordController.clear();
    _oldPasswordController.clear();
    _retypeNewPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    print(currentUser!.email);
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => Userpage()));
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Old Password', style: TextStyle(fontSize: 18)),
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your old password',
                ),
                validator: (value) =>
                value!.isEmpty
                    ? 'Please enter old password'
                    : null,
              ),
              SizedBox(height: 20),
              Text('New Password', style: TextStyle(fontSize: 18)),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter new password',
                ),
                validator: _validatePassword,
              ),
              SizedBox(height: 20),
              Text('Retype New Password', style: TextStyle(fontSize: 18)),
              TextFormField(
                controller: _retypeNewPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Retype new password',
                ),
                validator: (value) =>
                value!.isEmpty
                    ? 'Please retype the new password'
                    : null,
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _changePassword,
                    child: Text('Change Password'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}