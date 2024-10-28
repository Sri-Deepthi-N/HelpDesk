import 'package:college/Database/Database.dart';
import 'package:college/SuperAdmin/superadmin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DeleteUserScreen extends StatefulWidget {
  @override
  _DeleteUserScreenState createState() => _DeleteUserScreenState();
}

class _DeleteUserScreenState extends State<DeleteUserScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? errorMessage;
  String? userName = '';
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      List<Map<String, dynamic>> users = await DatabaseMethods().getUser();
      setState(() {
        _users = users;
      });
    } catch (e) {
      setState(() {});
      print('Error fetching users: $e');
    }
  }

  String? _getEmailForUser(String enteredUserName) {
    for (var user in _users) {
      if (user['mailId'] == enteredUserName) {
        return user['uid'];
      }
    }
    return null;
  }


  Future<void> deleteUser() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    print("dkjfbe $email");
    if(email !='' && password !='') {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await userCredential.user!.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User deleted successfully.')),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          errorMessage = e.message;
        });
      } catch (e) {
        setState(() {
          errorMessage = 'An unexpected error occurred: $e';
        });
      }
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please Enter emailId ans Password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SuperAdmin()),
            );
          },
        ),
        title: const Text("Delete User"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Enter the Username (Email)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Enter Your Password",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'Enter your old password',
                ),
                validator: (value) =>
                value!.isEmpty ? 'Please enter password' : null,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete your Account?'),
                          content: const Text(
                              '''If you select Delete we will delete your account on our server.\n\nYour app data will also be deleted and you won't be able to retrieve it.\n\nSince this is a security-sensitive operation, you are asked to log in before your account can be deleted.'''),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                userName = _getEmailForUser(emailController.text);
                                deleteUser();
                                await DatabaseMethods().deleteUser(userName!);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text("Delete"),
                ),
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
