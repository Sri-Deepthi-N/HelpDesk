import 'package:college/Auth/AuthFunctions.dart';
import 'package:college/Auth/ForgetPassword.dart';
import 'package:college/Database/Database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  String userName = '';
  String password = '';
  String email = '';
  final TextEditingController _usernameController = TextEditingController();
  final DatabaseMethods _userService = DatabaseMethods();
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      List<Map<String, dynamic>> users = await _userService.getUser();
      setState(() {
        _users = users;
      });
    } catch (e) {
      setState(() {});
      print('Error fetching users: $e');
    }
  }

  // Fetch email based on entered username
  String? _getEmailForUser(String enteredUserName) {
    for (var user in _users) {
      if (user['uid'] == enteredUserName) {
        return user['mailId'];

      }
    }
    return null;
  }


  void _handleCancel() {
    setState(() {
      userName = '';
      password = '';
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Image.asset(
                  'assets/college_logo.png',
                  height: 100.0,
                ),
              ),
              SizedBox(height: 20),
              Text('Username', style: TextStyle(fontSize: 18)),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter User Name',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please Enter User Name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text('Password', style: TextStyle(fontSize: 18)),
              TextFormField(
                key: ValueKey('password'),
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter Password',
                ),
                validator: (value) {
                  if (value!.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  password = value;
                },
              ),
              SizedBox(height: 30.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        String enteredUsername = _usernameController.text.trim();
                        String? fetchedEmail = _getEmailForUser(enteredUsername);
                        if (fetchedEmail != null) {
                          AuthServices.signinUser(fetchedEmail, password, context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid username or password')),
                          );
                        }
                      }
                    },
                    child: Text('Login'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _handleCancel,
                    child: Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (context) => Forgotpassword()));
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
