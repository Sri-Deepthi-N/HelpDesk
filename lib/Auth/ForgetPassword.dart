import 'package:college/Auth/AuthFunctions.dart';
import 'package:college/main.dart';
import 'package:flutter/material.dart';

class Forgotpassword extends StatefulWidget {
  const Forgotpassword({Key? key}) : super(key: key);

  @override
  State<Forgotpassword> createState() => _ForgotpasswordState();
}

class _ForgotpasswordState extends State<Forgotpassword> {
  final  _auth =AuthServices();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // Email validation function
  bool _validateEmail(String email) {
    // Regular expression for email validation
    String pattern = r'^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to the previous page
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => MyApp()));
          },
        ),
        title: const Text("Forgot Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Aligns content to the top
            children: [
              const SizedBox(height: 30), // You can add a small gap if needed
              const Text(
                "Enter your email address",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!_validateEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {

                       await _auth.sendPasswordReset(_emailController.text).then((value) =>
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(
                               content: Text('Reset password link has been sent to your email'),
                             )
                       )
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MyApp()),
                      );
                    }
                  },
                  child: const Text("Send Email"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}